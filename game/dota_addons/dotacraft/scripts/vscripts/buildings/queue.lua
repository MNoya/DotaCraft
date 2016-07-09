if not Queue then
    Queue = class({})
end

function Queue:Init(building)
    if not building.IsUnderConstruction then return end --Dummy building

    building.QueueTimer = Timers:CreateTimer(function()
        if IsValidEntity(building) and building:IsAlive() then
            self:Think(building)
            return 0.03
        end
    end)

    -- Creates a rally point flag for this unit, removing the old one if there was one
    if HasTrainAbility(building) then
        Timers:CreateTimer(2/30, function()
            local origin = building:GetAbsOrigin()
            
            -- Find vector towards 0,0,0 for the initial rally point
            local forwardVec = Vector(0,0,0) - origin
            forwardVec = forwardVec:Normalized()

            -- For the initial rally point, get point away from the building looking towards (0,0,0)
            local position = origin + forwardVec * 250
            position = GetGroundPosition(position, building)

            -- Keep track of this position so that every unit is autospawned there
            building.initial_spawn_position = position
            building.flag_type = "position"
            building.flag = position
        end)
    end
end

function Queue:Remove(building)
    if building.QueueTimer then Timers:RemoveTimer(building.QueueTimer) end
end

function Queue:Think(building)
    local playerID = building:GetPlayerOwnerID()
    local bChanneling = IsChanneling(building)
    if not bChanneling then
        building:SetMana(0)
        building:SetBaseManaRegen(0)
    end

    if building:HasModifier("modifier_frozen") then
        if bChanneling then bChanneling:EndChannel(true) end
        return
    end

    if not bChanneling and not building:IsUnderConstruction() then  
        -- Remake queue
        building.queue = {}

        -- Autocast, only if the queue is empty and there's enough food and resources for any of the training
        local nQueued = GetNumItemsInInventory(building)
        if nQueued == 0 then
            for i=0,15 do
                local ability = building:GetAbilityByIndex(i)
                if ability and ability:GetAutoCastState() and Players:EnoughForDoMyPower(playerID, ability) then
                    building:CastAbilityNoTarget(ability, playerID)
                end
            end
        end

        -- Check the first item that contains "train" on the queue
        for itemSlot=0,5 do
            local item = building:GetItemInSlot(itemSlot)
            if item and IsValidEntity(item) then
                table.insert(building.queue, item:GetEntityIndex())
                local item_name = item:GetAbilityName()

                -- Items that contain "train" "revive" or "research" will start a channel of an ability with the same name without the item_ affix
                if item_name:match("train_") or item_name:match("_revive") or item_name:match("research_") then
                    local train_ability_name = item_name:gsub("item_", "") --tied ability-item
                    local ability_to_channel = building:FindAbilityByName(train_ability_name) 
                    if ability_to_channel then
                        local food_cost = ability_to_channel:GetLevelSpecialValueFor("food_cost", ability_to_channel:GetLevel() - 1) or 0

                        if Players:HasEnoughFood(playerID, food_cost) then

                            -- Add to the value of food used as soon as the unit training starts
                            Players:ModifyFoodUsed(playerID, food_cost)

                            -- Fake mana channel bar
                            ability_to_channel:SetChanneling(true)
                            building:SetMana(0)
                            building:SetBaseManaRegen(building:GetMaxMana()/ability_to_channel:GetChannelTime())

                            -- Cheats
                            if GameRules.WarpTen then
                                ability_to_channel:EndChannel(false)
                                ReorderItems(building)
                                return
                            end

                            -- After the channeling time, check if it was cancelled or spawn it
                            -- EndChannel(false) runs whatever is in the OnChannelSucceded of the function
                            local time = ability_to_channel:GetChannelTime()
                            Timers:CreateTimer(time, function()
                                if IsValidEntity(item) then
                                    ability_to_channel:EndChannel(false)
                                    ReorderItems(building)
                                end
                            end)
                        end
                    end
                    return -- Don't continue, queue should strictly only take the first in line
                end
            end
        end

        -- Night Elf buildings disable attack
        if IsNightElf(building) and building.original_attack then
            building:SetAttackCapability(building.original_attack)
        end
    end
end

-- Creates an item on the buildings inventory to consume the queue.
function EnqueueUnit( event )
    local caster = event.caster
    local ability = event.ability
    local playerID = caster:GetPlayerOwnerID()
    local gold_cost = ability:GetGoldCost( ability:GetLevel() - 1 )
    local lumber_cost = ability:GetLevelSpecialValueFor("lumber_cost", ability:GetLevel() - 1) or 0

    -- Initialize queue
    if not caster.queue then
        caster.queue = {}
    end

    -- Check food
    local food_cost = ability:GetLevelSpecialValueFor("food_cost", ability:GetLevel() - 1)
    if not food_cost then
        food_cost = 0
    end

    -- Send 'need more farms' warning
    if not Players:HasEnoughFood(playerID, food_cost) then
        local race = Players:GetRace(playerID)
        SendErrorMessage(playerID, "#error_not_enough_food_"..race)
    end

    -- Check lumber
    if not Players:HasEnoughLumber( playerID, lumber_cost ) then
        -- Refund gold, show message
        Players:ModifyGold(playerID, gold_cost)
        SendErrorMessage(playerID, "#error_not_enough_lumber")
        return
    else
        -- Use lumber
        Players:ModifyLumber(playerID, -lumber_cost)
    end

    -- Queue up to 6 units max
    if #caster.queue < 6 then
        local ability_name = ability:GetAbilityName()
        local item_name = "item_"..ability_name
        local item = CreateItem(item_name, caster, caster)
        caster:AddItem(item)

        -- RemakeQueue
        caster.queue = {}
        for itemSlot = 0, 5, 1 do
            local item = caster:GetItemInSlot( itemSlot )
            if item ~= nil then
                table.insert(caster.queue, item:GetEntityIndex())
            end
        end

        -- Disable research
        if string.match(ability_name, "research_") then
            DisableResearch(event) -- buildings/research.lua
        end

        -- Night Elf buildings disable attack
        if IsNightElf(caster) then
            caster.original_attack = caster:GetAttackCapability()
            caster:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
        end

        -- Start building upgrade actions
        if event.Action == "StartUpgrade" then
            StartUpgrade(event)
        end
    else
        -- Refund with message
        Players:ModifyLumber(playerID, lumber_cost)
        Players:ModifyGold(playerID, gold_cost)
        SendErrorMessage(playerID, "#error_queue_full")
    end
end


-- Destroys an item on the buildings inventory, refunding full cost of purchasing and reordering the queue
-- If its the first slot, the channeling ability is also set to not channel, refunding the full price.
function DequeueUnit( event )
    local caster = event.caster
    local item_ability = event.ability
    local playerID = caster:GetPlayerOwnerID()
    local item_ability_name = item_ability:GetAbilityName()

    -- Get tied ability
    local train_ability_name = item_ability_name:gsub("item_", "")
    local train_ability = caster:FindAbilityByName(train_ability_name)
    local gold_cost = train_ability:GetGoldCost( train_ability:GetLevel() )
    local lumber_cost = train_ability:GetLevelSpecialValueFor("lumber_cost", train_ability:GetLevel() - 1) or 0

    for itemSlot = 0, 5 do
        local item = caster:GetItemInSlot( itemSlot )
        if item and item == item_ability then
            local queue_element = getIndex(caster.queue, item:GetEntityIndex())
            table.remove(caster.queue, queue_element)

            -- Refund ability cost
            Players:ModifyGold(playerID, gold_cost)
            Players:ModifyLumber(playerID, lumber_cost)

            -- Set not channeling if the cancelled item was the first slot
            if itemSlot == 0 or IsInFirstSlot(caster, item) then
                -- Refund food used
                local ability = caster:FindAbilityByName(train_ability_name)
                local food_cost = ability:GetLevelSpecialValueFor("food_cost", ability:GetLevel())
                if food_cost and not caster:IsUnderConstruction() and ability:IsChanneling() then
                    Players:ModifyFoodUsed(playerID, -food_cost)
                end

                train_ability:SetChanneling(false)
                train_ability:EndChannel(true)

                -- Fake mana channel bar
                caster:SetMana(0)
                caster:SetBaseManaRegen(0)
            end
            item:RemoveSelf()
            ReorderItems(caster)
            break
        end
    end
end

-- Moves on to the next element of the queue
function NextQueue( event )
    local caster = event.caster
    local ability = event.ability
    ability:SetChanneling(false)

    local hAbility = EntIndexToHScript(ability:GetEntityIndex())
    for itemSlot = 0, 5, 1 do
        local item = caster:GetItemInSlot( itemSlot )
        if item ~= nil then
            local item_name = tostring(item:GetAbilityName())

            -- Remove the "item_" to compare
            local train_ability_name = item_name:gsub("item_", "")
            if train_ability_name == hAbility:GetAbilityName() then

                local train_ability = caster:FindAbilityByName(train_ability_name)
                local queue_element = getIndex(caster.queue, item:GetEntityIndex())
                if IsValidEntity(item) then
                    table.remove(caster.queue, queue_element)
                    caster:RemoveItem(item)
                end

                break
            end
        end
    end
end