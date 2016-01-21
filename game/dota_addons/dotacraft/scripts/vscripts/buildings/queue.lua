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
    local train_ability_name = string.gsub(item_ability_name, "item_", "")
    local train_ability = caster:FindAbilityByName(train_ability_name)
    local gold_cost = train_ability:GetGoldCost( train_ability:GetLevel() )
    local lumber_cost = train_ability:GetLevelSpecialValueFor("lumber_cost", train_ability:GetLevel() - 1) or 0

    print("DequeueUnit")

    for itemSlot = 0, 5, 1 do
        local item = caster:GetItemInSlot( itemSlot )
        if item and item == item_ability then
            local queue_element = getIndex(caster.queue, item:GetEntityIndex())
            table.remove(caster.queue, queue_element)

            item:RemoveSelf()
            
            -- Refund ability cost
            Players:ModifyGold(playerID, gold_cost)
            Players:ModifyLumber(playerID, lumber_cost)

            -- Set not channeling if the cancelled item was the first slot
            if itemSlot == 0 then
                -- Refund food used
                local ability = caster:FindAbilityByName(train_ability_name)
                local food_cost = ability:GetLevelSpecialValueFor("food_cost", ability:GetLevel())
                if food_cost and not caster:HasModifier("modifier_construction") and ability:IsChanneling() then
                    Players:ModifyFoodUsed(playerID, -food_cost)
                end

                train_ability:SetChanneling(false)
                train_ability:EndChannel(true)

                -- Fake mana channel bar
                caster:SetMana(0)
                caster:SetBaseManaRegen(0)            
            end
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
            local train_ability_name = string.gsub(item_name, "item_", "")

            if train_ability_name == hAbility:GetAbilityName() then

                local train_ability = caster:FindAbilityByName(train_ability_name)
                local queue_element = getIndex(caster.queue, item:GetEntityIndex())
                if IsValidEntity(item) then
                    table.remove(caster.queue, queue_element)
                    caster:RemoveItem(item)
                end

                break
            elseif item then
                --print(item_name,hAbility:GetAbilityName())
            end
        end
    end
end

function AdvanceQueue( event )
    local caster = event.caster
    local ability = event.ability
    local playerID = caster:GetPlayerOwnerID()

    if not IsChanneling( caster ) then
        caster:SetMana(0)
        caster:SetBaseManaRegen(0)
    end

    if caster and IsValidEntity(caster) and not IsChanneling( caster ) and not caster:HasModifier("modifier_construction") then
        
        -- RemakeQueue
        caster.queue = {}

        -- Autocast, only if the queue is empty and there's enough food and resources for any of the training
        local nQueued = GetNumItemsInInventory(caster)
        if nQueued == 0 then
            for i=0,15 do
                local thisAbility = caster:GetAbilityByIndex(i)
                if thisAbility and thisAbility:GetAutoCastState() and Players:EnoughForDoMyPower(playerID, thisAbility) then
                    caster:CastAbilityNoTarget(thisAbility, playerID)
                end
            end
        end

        -- Check the first item that contains "train" on the queue
        for itemSlot=0,5 do
            local item = caster:GetItemInSlot(itemSlot)
            if item and IsValidEntity(item) then
                table.insert(caster.queue, item:GetEntityIndex())

                local item_name = tostring(item:GetAbilityName())
                -- Items that contain "train" "revive" or "research" will start a channel of an ability with the same name without the item_ affix
                if string.find(item_name, "train_") or string.find(item_name, "_revive") or string.find(item_name, "research_") then
                    -- Find the name of the tied ability-item
                    local train_ability_name = string.gsub(item_name, "item_", "")

                    local ability_to_channel = caster:FindAbilityByName(train_ability_name)
                    if ability_to_channel then

                        local food_cost = ability_to_channel:GetLevelSpecialValueFor("food_cost", ability_to_channel:GetLevel() - 1)
                        if not food_cost then
                            food_cost = 0
                        end

                        if Players:HasEnoughFood(playerID, food_cost) then

                            -- Add to the value of food used as soon as the unit training starts
                            Players:ModifyFoodUsed(playerID, food_cost)

                            ability_to_channel:SetChanneling(true)

                            -- Fake mana channel bar
                            local channel_time = ability_to_channel:GetChannelTime()
                            caster:SetMana(0)
                            caster:SetBaseManaRegen(caster:GetMaxMana()/channel_time)

                            -- Cheats
                            if GameRules.WarpTen then
                                ability_to_channel:EndChannel(false)
                                ReorderItems(caster)
                                return
                            end

                            -- After the channeling time, check if it was cancelled or spawn it
                            -- EndChannel(false) runs whatever is in the OnChannelSucceded of the function
                            local time = ability_to_channel:GetChannelTime()
                            Timers:CreateTimer(time, function()
                                if IsValidEntity(item) then
                                    ability_to_channel:EndChannel(false)
                                    ReorderItems(caster)
                                end
                            end)
                        end
                    end
                    return -- Don't continue, queue should strictly only take the first in line
                end
            end
        end

        -- Empty queue

        -- Night Elf buildings disable attack
        if IsNightElf(caster) and caster.original_attack then
            caster:SetAttackCapability(caster.original_attack)
        end
    end
end