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

    local bValidRepair = BuildingHelper:OnPreRepair(caster, target)
    if not bValidRepair then
        Gatherer:CastGatherAbility(event)
    else return end -- Exit out of repair ability usage

    event:OnTreeReached(function(tree)
        Gatherer:print("Tree reached")

        if race == "nightelf" then
            caster:AddNewModifier(nil, nil, "modifier_stunned", {})
            local tree_pos = tree:GetAbsOrigin()
            local caster_location = caster:GetAbsOrigin()
            local speed = caster:GetBaseMoveSpeed() * 0.03
            local distance = (tree_pos - caster_location):Length()
            local direction = (tree_pos - caster_location):Normalized()

            -- Move the wisp on top of the tree
            Timers:CreateTimer(function()
                if not caster:IsAlive() then return end

                local new_location = caster:GetAbsOrigin() + direction * speed
                caster:SetAbsOrigin(new_location)

                local distance = (tree_pos - caster:GetAbsOrigin()):Length()
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
        Gatherer:print("Gained "..value.." lumber")
        Players:ModifyLumber(playerID, value)
        PopupLumber(caster, value)
        Scores:IncrementLumberHarvested(playerID, value)
    end)

    event:OnTreeDamaged(function(tree)
        Gatherer:print("OnTreeDamaged: "..tree.health)

        caster:StartGesture(ACT_DOTA_ATTACK)

        -- Hit particle
        local particleName = "particles/custom/tree_pine_01_destruction.vpcf"
        local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(particle, 0, tree:GetAbsOrigin())

        -- Peasant backpack create
    end)

    event:OnTreeCutDown(function(tree)
        Gatherer:print("OnTreeCutDown")
    end)

    event:OnMaxResourceGathered(function(node_type)
        Gatherer:print("Max "..node_type.." gathered")
    end)

    event:OnGoldMineReached(function(mine)
        Gatherer:print("Gold Mine reached")
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
                return self.ThinkInterval
            end

            if not mine.builders then
                mine.builders = {}
            end

            local counter = TableCount(mine.builders)
            print(counter, "Builders inside")
            if counter >= 5 then
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
            
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_gold", {})

            -- Find first empty position
            local free_pos
            for i=1,5 do
                if not mine.builders[i] then
                    mine.builders[i] = caster
                    free_pos = i
                    break
                end
            end        

            -- 5 positions = 72 degrees
            local mine_origin = mine:GetAbsOrigin()
            local fv = mine:GetForwardVector()
            local front_position = mine_origin + fv * distance
            local pos = RotatePosition(mine_origin, QAngle(0, 72*free_pos, 0), front_position)
            caster:Stop()
            caster:SetAbsOrigin(Vector(pos.x, pos.y, pos.z+height))
            caster:SetForwardVector( (mine_origin - caster:GetAbsOrigin()):Normalized() )
            Timers:CreateTimer(0.06, function() 
                caster:Stop() 
                caster:SetForwardVector( (mine_origin - caster:GetAbsOrigin()):Normalized() )
                PlayerResource:RemoveFromSelection(caster:GetPlayerOwnerID(), caster)
            end)

            -- Particle Counter on overhead
            counter = #mine.builders
            SetGoldMineCounter(mine, counter)
        end
    end)

    -- For gathering without return
    event:OnGoldGained(function(value)
        Gatherer:print("Gained "..value.." gold")
        local upkeep = Players:GetUpkeep(playerID)
        local gold_gain = value * upkeep

        Scores:IncrementGoldMined(playerID, gold_gain)
        Scores:AddGoldLostToUpkeep(playerID, value - gold_gain)

        Players:ModifyGold(playerID, gold_gain)
        PopupGoldGain(caster, gold_gain)
    end)

    event:OnGoldMineCollapsed(function(mine)
        Gatherer:print("OnGoldMineCollapsed")
    end)

    event:OnCancelGather(function()
        Gatherer:print("OnCancelGather")
        local tree = caster.target_tree
        if tree then
            caster.target_tree = nil
            caster.target_tree = nil
            tree.builder = nil
        end

        if caster.tree_fx then
            ParticleManager:DestroyParticle(caster.tree_fx, true)
        end

        local mine = caster.target_mine
        if mine and mine.builders then
            if race == "nightelf" or race == "undead" then
                local caster_key = TableFindKey(mine.builders, caster)
                if caster_key then
                    mine.builders[caster_key] = nil

                    local count = 0
                    for k,v in pairs(mine.builders) do
                        count=count+1
                    end
                    print("Count is ", count, "key removed was ",caster_key)
                    SetGoldMineCounter(mine, count)
                end
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

        caster:RemoveModifierByName("modifier_carrying_lumber")
        PopupLumber(caster, caster.lumber_gathered)
        
        Players:ModifyLumber(playerID, caster.lumber_gathered)
        Scores:IncrementLumberHarvested( playerID, caster.lumber_gathered)

        caster.lumber_gathered = 0
    end)

    event:OnGoldDepositReached(function(building)
        Gatherer:print("Gold deposit reached: ".. building:GetUnitName())
        
        local upkeep = Players:GetUpkeep( playerID )
        local gold_gain = caster.gold_gathered * upkeep

        caster:RemoveModifierByName("modifier_carrying_gold")
        Scores:IncrementGoldMined(playerID, caster.gold_gathered)
        Scores:AddGoldLostToUpkeep(playerID, caster.gold_gathered - gold_gain)

        Players:ModifyGold(playerID, gold_gain)
        PopupGoldGain(caster, gold_gain)

        caster.gold_gathered = 0
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
-- Code to refactor below
--[[
    GatherLumber - Should be a timer iniside Gatherer, with a callback per tick
    GatherGold - Should be a timer iniside Gatherer, with a callback per tick
    LumberGain (Static)
    GoldGain (Static)
    SetGoldMineCounter (cosmetic)
    SendBackToGather should be a gather unit method
]]

-- Used in Nigh Elf and Undead Gather Gold
function GoldGain( event )
    local ability = event.ability
    local caster = event.caster
    local playerID = caster:GetPlayerOwnerID()
    local race = GetUnitRace(caster)
    local upkeep = Players:GetUpkeep(playerID)
    local gold_base = ability:GetSpecialValueFor("gold_per_interval")
    local gold_gain = gold_base * upkeep

    Scores:IncrementGoldMined( playerID, gold_gain )
    Scores:AddGoldLostToUpkeep( playerID, gold_base - gold_gain )

    Players:ModifyGold(playerID, gold_gain)
    PopupGoldGain( caster, gold_gain)

    -- Reduce the health of the main and mana on the entangled/haunted mine to show the remaining gold
    local mine = caster.target_mine
    mine:SetHealth( mine:GetHealth() - gold_gain )
    mine.building_on_top:SetMana( mine:GetHealth() - gold_gain )

    -- If the gold mine has no health left for another harvest
    if mine:GetHealth() < gold_gain then

        -- Destroy the nav blockers associated with it
        for k, v in pairs(mine.blockers) do
          DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
          DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
        end
        print("Gold Mine Collapsed at ", mine:GetHealth())

        -- Stop all builders
        local builders = mine.builders
        for k,builder in pairs(builders) do

            -- Cancel gather effects
            builder:RemoveModifierByName("modifier_gathering_gold")
            builder.state = "idle"
            builder.GatherAbility:ToggleOff()

            if race == "nightelf" then
                FindClearSpaceForUnit(builder, mine.entrance, true)
            end
        end

        ParticleManager:DestroyParticle(mine.building_on_top.counter_particle, true)
        mine.building_on_top:RemoveSelf()

        mine:RemoveModifierByName("modifier_invulnerable")
        mine:Kill(nil, nil)
        mine:AddNoDraw()

        caster.target_mine = nil
    end
end

function SetGoldMineCounter(mine, count)
    local building_on_top = mine.building_on_top
    print("SetGoldMineCounter ",count)

    for i=1,count do
        --print("Set ",i," turned on")
        ParticleManager:SetParticleControl(building_on_top.counter_particle, i, Vector(1,0,0))
    end
    for i=count+1,5 do
        --print("Set ",i," turned off")
        ParticleManager:SetParticleControl(building_on_top.counter_particle, i, Vector(0,0,0))
    end
end