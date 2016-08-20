--[[=============================================================
                         Gather Scripts    
 Unit KeyValues
"GatherAbility"     "undead_gather"
"ReturnAbility"     "undead_return_resources" //only for "Return" behaviour
"GatherResources"   "lumber" or "gold" or "lumber,gold"

 Lumber Ability KeyValues
"LumberGainInterval" "1"
"LumberPerInterval"  "1"
"DamageTree"         "1"
"RequiresEmptyTree"  "1" //0 by default
 
 Gold Ability KeyValues
"GoldGainInterval"   "0.5"
"GoldPerInterval"    "10"
"GoldMineInside"     "1"
"DamageMine"         "10"
"GoldMineBuilding"  "nightelf_entangled_gold_mine" //"gold_mine" by default
"GoldMineCapacity"  "5" //1 by default, 5 with building_on_top

===============================================================]]

-- Gather Start - Decides what behavior to use
function Gather( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local race = GetUnitRace(caster)
    local playerID = caster:GetPlayerOwnerID()

    if caster.target_tree then caster:CancelGather() end

    local bValidRepair = BuildingHelper:OnPreRepair(caster, target)
    if not bValidRepair then
        Gatherer:CastGatherAbility(event)
    else return end -- Exit out of repair ability usage

    event:OnTreeReached(function(tree)
        Gatherer:print("Tree reached")
        caster.state = "gathering_lumber"
        if race == "nightelf" then
            caster:AddNewModifier(nil, nil, "modifier_stunned", {})
            tree.wisp = caster
            local tree_pos = tree:GetAbsOrigin()
            local speed = caster:GetBaseMoveSpeed() * 0.03

            if caster.tree_fx then
                ParticleManager:DestroyParticle(caster.tree_fx, true)
            end

            Timers:CreateTimer(0.03, function()
                caster.wisp_unstuck_position = caster:GetAbsOrigin()
            end)

            -- Move the wisp on top of the tree
            Timers:CreateTimer(function()
                if not caster:IsAlive() then return end
                local origin = caster:GetAbsOrigin()
                local direction = (tree_pos - origin):Normalized()
                local new_location = origin + direction * speed
                caster:SetAbsOrigin(new_location)

                local distance = (tree_pos - origin):Length()
                if distance > 10 then
                    return 0.03
                else
                    caster:RemoveModifierByName("modifier_stunned")
                    caster.tree_fx = ParticleManager:CreateParticle("particles/custom/nightelf/gather.vpcf", PATTACH_CUSTOMORIGIN, caster)
                    tree_pos.z = tree_pos.z + 100
                    ParticleManager:SetParticleControl(caster.tree_fx, 0, tree_pos)
                end
            end)
        else
            caster:StartGesture(ACT_DOTA_ATTACK)
        end
    end)

    -- For gathering without a return ability
    event:OnLumberGained(function(value)
        --Gatherer:print("Gained "..value.." lumber")
        Players:ModifyLumber(playerID, value)
        PopupLumber(caster, value)
        Scores:IncrementLumberHarvested(playerID, value)
    end)

    event:OnTreeDamaged(function(tree)
        --Gatherer:print("OnTreeDamaged: "..tree.health)
        caster:StartGesture(ACT_DOTA_ATTACK)

        -- Hit particle
        local particleName = "particles/custom/tree_pine_01_destruction.vpcf"
        local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(particle, 0, tree:GetAbsOrigin())

        -- Peasant backpack create
    end)

    event:OnTreeCutDown(function(tree)
        Gatherer:print("OnTreeCutDown")

        if IsValidEntity(tree.wisp) then
            tree.wisp:CancelGather()
            tree.wisp = nil
        end
    end)

    event:OnMaxResourceGathered(function(node_type)
        Gatherer:print("Max "..node_type.." gathered")
    end)

    event:OnGoldMineReached(function(mine)
        Gatherer:print("Gold Mine reached")
        if IsValidEntity(mine.building_on_top) and not mine:HasRoomForGatherer() then
            caster:CancelGather()
        end
    end)

    event:OnGoldMineFree(function(mine)
        Gatherer:print("On Gold Mine Free")      

        -- 2 Possible behaviours: Human/Orc vs NE/UD
        -- NE/UD requires another building on top

        if race == "undead" or race == "nightelf" then
            if not IsMineOccupiedByTeam(mine, caster:GetTeamNumber()) then
                print("Mine must be occupied by your team, fool")
                return
            end

            if mine.building_on_top and mine.building_on_top:IsUnderConstruction() then
                --print("Extraction Building is still in construction, wait...")
                return
            end
            
            -- 5 positions = 72 degrees
            local free_pos = mine:AddGatherer(caster)
            if not free_pos then
                print(" Mine full")
                return
            end

            local distance = 0
            local height = 0
            if race == "undead" then
                distance = 250
            elseif race == "nightelf" then
                distance = 100
                height = 25
            end

            local mine_origin = mine:GetAbsOrigin()
            local fv = mine:GetForwardVector()
            local front_position = mine_origin + fv * distance
            local pos = RotatePosition(mine_origin, QAngle(0, 72*free_pos, 0), front_position)
            caster:Stop()
            caster:SetAbsOrigin(Vector(pos.x, pos.y, pos.z+height))
            
            caster.state = "gathering_gold"
            if race == "undead" then
                caster:SetForwardVector( (mine_origin - caster:GetAbsOrigin()):Normalized() )
                Timers:CreateTimer(0.06, function() 
                    caster:Stop() 
                    caster:SetForwardVector( (mine_origin - caster:GetAbsOrigin()):Normalized() )
                end)
            elseif race == "nightelf" then
                -- If its the last selected unit, select the mine
                local playerID = caster:GetPlayerOwnerID()
                local selectedEntities = PlayerResource:GetSelectedEntities(playerID)
                if TableCount(selectedEntities) == 1 and PlayerResource:IsUnitSelected(playerID, caster) then
                    local building = mine.building_on_top or mine
                    PlayerResource:NewSelection(playerID, building)
                else
                    PlayerResource:RemoveFromSelection(playerID, caster)
                end
            end
        end
    end)

    -- For gathering without return
    event:OnGoldGained(function(value, mine)
        --Gatherer:print("Gained "..value.." gold from "..mine:GetUnitName().." "..mine:GetEntityIndex())
        if IsValidEntity(mine.building_on_top) then
            mine.building_on_top:SetMana(mine:GetHealth())
        end
        local upkeep = Players:GetUpkeep(playerID)
        local gold_gain = value * upkeep

        Scores:IncrementGoldMined(playerID, gold_gain)
        Scores:AddGoldLostToUpkeep(playerID, value - gold_gain)

        Players:ModifyGold(playerID, gold_gain)
        PopupGoldGain(caster, gold_gain)
    end)

    event:OnGoldMineDepleted(function(mine)
        Gatherer:print("OnGoldMineDepleted")

        -- Stop builders
        for _,gatherer in pairs(mine.gatherers) do
            gatherer:CancelGather()
            ExecuteOrderFromTable({UnitIndex = gatherer:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_STOP, Queue = false}) 
        end

        local building_on_top = mine.building_on_top
        if IsValidEntity(building_on_top) then
            building_on_top:SetMana(0)
            if building_on_top:GetUnitName() == "undead_haunted_gold_mine" then
                -- Unsummon, then destroy the gold mine with it
                Unsummon(building_on_top, function()
                    mine:ForceKill(true)
                    mine:AddNoDraw()
                end)
            else
                building_on_top:ForceKill(true)
                building_on_top:AddNoDraw()
                mine:ForceKill(true)
                mine:AddNoDraw()
            end
        else
            mine:AddNoDraw()
            mine:ForceKill(true)
        end
    end)

    event:OnCancelGather(function()
        Gatherer:print("OnCancelGather")
        local tree = caster.target_tree
        if tree then
            caster.target_tree = nil
            caster.target_tree = nil
            tree.builder = nil
        end

        if caster.wisp_unstuck_position then
            FindClearSpaceForUnit(caster, caster.wisp_unstuck_position, true)
            caster.wisp_unstuck_position = nil
        end

        if caster.tree_fx then
            ParticleManager:DestroyParticle(caster.tree_fx, true)
        end

        local mine = caster.target_mine
        if mine then
            if race == "nightelf" or race == "undead" then
                mine:RemoveGatherer(caster)
            end
        end
    end)
end

-- Called when the race_return_resources ability is cast
function ReturnResources( event )
    local caster = event.caster
    local playerID = caster:GetPlayerOwnerID()

    Gatherer:CastReturnAbility(event)

    event:OnLumberDepositReached(function(building)
        Gatherer:print("Lumber deposit reached: ".. building:GetUnitName())
        local lumber_gathered = caster:GetModifierStackCount("modifier_carrying_lumber",caster)
        caster:RemoveCarriedResource("lumber")
        if lumber_gathered > 0 then
            PopupLumber(caster, lumber_gathered)
            Players:ModifyLumber(playerID, lumber_gathered)
            Scores:IncrementLumberHarvested( playerID, lumber_gathered)
        end
    end)

    event:OnGoldDepositReached(function(building)
        Gatherer:print("Gold deposit reached: ".. building:GetUnitName())
        
        local upkeep = Players:GetUpkeep( playerID )
        local gold_gain = caster.gold_gathered * upkeep

        caster:RemoveCarriedResource("gold")
        Scores:IncrementGoldMined(playerID, caster.gold_gathered)
        Scores:AddGoldLostToUpkeep(playerID, caster.gold_gathered - gold_gain)

        Players:ModifyGold(playerID, gold_gain)
        PopupGoldGain(caster, gold_gain)
    end)
end

-- Toggles Off Gather
function CancelGather( event )
    print("CancelGather Datadriven Event is Deprecated, using :CancelGather() lua")
    event.caster:CancelGather()
end

-- Toggles Off Return because of an order (e.g. Stop)
function CancelReturn( event )
    print("CancelReturn Datadriven Event is Deprecated, using :CancelGather() lua")
    event.caster:CancelGather()
end

----------------------------------------------------------------------------------