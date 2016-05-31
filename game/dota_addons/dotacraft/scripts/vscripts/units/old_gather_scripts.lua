------------------------------------------
--     (Deprecated) Gather Scripts      --
------------------------------------------

MIN_DISTANCE_TO_TREE = 200
MIN_DISTANCE_TO_MINE = 300
TREE_FIND_RADIUS_FROM_TREE = 200
TREE_FIND_RADIUS_FROM_TOWN = 2000
DURATION_INSIDE_MINE = 0.5
DAMAGE_TO_MINE = 10
THINK_INTERVAL = 0.5
DEBUG_TREES = false
VALID_DEPOSITS = LoadKeyValues("scripts/kv/buildings.kv")

-- Gather Start - Decides what behavior to use
function Gather( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local target_class = target:GetClassname()

    caster:Interrupt() -- Stops any instance of Hold/Stop the builder might have

    -- Builder race
    local race = GetUnitRace(caster)

    -- Initialize variables to keep track of how much resource is the unit carrying
    if not caster.lumber_gathered then
        caster.lumber_gathered = 0
    end

    -- Possible states
        -- moving_to_tree
        -- moving_to_mine
        -- moving_to_repair
        -- moving_to_build (set on Building Helper when a build queue advances)
        -- returning_lumber
        -- returning_gold
        -- gathering_lumber
        -- gathering_gold
        -- repairing
        -- idle

    -- Gather Lumber
    if target_class == "ent_dota_tree" then
        
        local tree = target

        caster.last_resource_gathered = "lumber"

        -- Disable this for Acolytes
        if caster:GetUnitName() == "undead_acolyte" then
            print("Interrupt")
            caster:Interrupt()
            return
        end

        -- Check for empty tree for Wisps
        if IsNightElf(caster) and (tree.builder ~= nil and tree.builder ~= caster) then
            local tree = FindEmptyNavigableTreeNearby(caster, tree:GetAbsOrigin(), 150)
            if tree then
                caster:Interrupt()
                ExecuteOrderFromTable({UnitIndex = caster:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree:GetTreeID(), AbilityIndex = ability:GetEntityIndex(), Queue = false})
                return
            end
        end

        local tree_pos = tree:GetAbsOrigin()
        --[[local particleName = "particles/ui_mouseactions/ping_circle_static.vpcf"
        local particle = ParticleManager:CreateParticleForPlayer(particleName, PATTACH_CUSTOMORIGIN, caster, caster:GetPlayerOwner())
        ParticleManager:SetParticleControl(particle, 0, Vector(tree_pos.x, tree_pos.y, tree_pos.z+20))
        ParticleManager:SetParticleControl(particle, 1, Vector(0,255,0))
        Timers:CreateTimer(3, function() 
            ParticleManager:DestroyParticle(particle, true)
        end)]]

        -- If the caster already had a tree targeted but changed with a right click to another tree, destroy the old move timer
        if caster.moving_timer then
            Timers:RemoveTimer(caster.moving_timer)
        end
        caster.state = "moving_to_tree"
        caster.target_tree = tree
        ability.cancelled = false
        if not tree.health then
            tree.health = TREE_HEALTH
        end

        tree.builder = caster
        local tree_pos = tree:GetAbsOrigin()

        -- Fake toggle the ability, cancel if any other order is given
        ToggleOn(ability)

        -- Recieving another order will cancel this
        ability:ApplyDataDrivenModifier(caster, caster, "modifier_on_order_cancel_lumber", {})

        caster.moving_timer = Timers:CreateTimer(function() 

            -- End if killed
            if not (caster and IsValidEntity(caster) and caster:IsAlive()) then
                return
            end

            -- Move towards the tree until close range
            if not ability.cancelled and caster:HasModifier("modifier_on_order_cancel_lumber") and caster.state == "moving_to_tree" then
                local distance = (tree_pos - caster:GetAbsOrigin()):Length()
                
                if distance > MIN_DISTANCE_TO_TREE then
                    caster:MoveToPosition(tree_pos)
                    return THINK_INTERVAL
                else
                    --print("Tree Reached")

                    if IsNightElf(caster) then
                        tree_pos.z = tree_pos.z - 28
                        caster:SetAbsOrigin(tree_pos)

                        tree.wisp_gathering = true
                    end

                    ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_lumber", {})
                    return
                end
            else
                return
            end
        end)

        -- Hide Return
        if IsHuman(caster) or IsOrc(caster) then
            local return_ability = FindReturnAbility(caster)
            return_ability:SetHidden(true)
            ability:SetHidden(false)
            --print("Gathering Lumber ON, Return OFF")
        end

    -- Gather Gold
    elseif string.match(target:GetUnitName(),"gold_mine") then

        caster.last_resource_gathered = "gold"

        -- Disable this for Ghouls
        if not caster:CanGatherGold() then
            caster:Interrupt()
            return
        end

        local mine
        if IsHuman(caster) or IsOrc(caster) then
            if target:GetUnitName() ~= "gold_mine" then
                print("Must target a gold mine, not a "..target:GetUnitName())
                return
            else
                mine = target
            end
        elseif IsNightElf(caster) then
            if target:GetUnitName() ~= "nightelf_entangled_gold_mine" then
                print("Must target a entangled gold mine, not a "..target:GetUnitName())
                return
            else
                mine = target.mine
            end
        elseif IsUndead(caster) then
            if target:GetUnitName() ~= "undead_haunted_gold_mine" then
                print("Must target a haunted gold mine, not a "..target:GetUnitName())
                return
            else
                mine = target.mine
            end
        end        

        local mine_pos = mine:GetAbsOrigin()
        caster.gold_gathered = 0
        caster.target_mine = mine
        caster.target_tree = nil -- Forget the tree
        ability.cancelled = false
        caster.state = "moving_to_mine"

        -- Destroy any old move timer
        if caster.moving_timer then
            Timers:RemoveTimer(caster.moving_timer)
        end

        -- Fake toggle the ability, cancel if any other order is given
        if ability:GetToggleState() == false then
            ability:ToggleAbility()
        end

        -- Recieving another order will cancel this
        ability:ApplyDataDrivenModifier(caster, caster, "modifier_on_order_cancel_gold", {})

        local mine_entrance_pos = mine.entrance+RandomVector(50)
        caster.moving_timer = Timers:CreateTimer(function() 

            -- End if killed
            if not (caster and IsValidEntity(caster) and caster:IsAlive()) then
                return
            end

            -- Move towards the mine until close range
            if not ability.cancelled and caster:HasModifier("modifier_on_order_cancel_gold") and caster.state == "moving_to_mine" then
                local distance = (mine_pos - caster:GetAbsOrigin()):Length()
                
                if distance > MIN_DISTANCE_TO_MINE then
                    caster:MoveToPosition(mine_entrance_pos)
                    --print("Moving to Mine, distance ", distance)
                    return THINK_INTERVAL
                else
                    --print("Mine Reached")

                    -- 2 Possible behaviours: Human/Orc vs NE/UD
                    -- NE/UD requires another building on top (Missing at the moment)

                    if race == "human" or race == "orc" then
                        if mine.builder then
                            --print("Waiting for the builder inside to leave")
                            return THINK_INTERVAL
                        elseif mine and IsValidEntity(mine) then
                            mine.builder = caster
                            caster:AddNoDraw()
                            ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_gold", {duration = DURATION_INSIDE_MINE})
                            caster:SetAbsOrigin(mine:GetAbsOrigin()) -- Send builder inside
                            return
                        else
                            caster:RemoveModifierByName("modifier_on_order_cancel_gold")
                            CancelGather(event)
                        end

                    elseif race == "undead" or race == "nightelf" then
                        if not IsMineOccupiedByTeam(mine, caster:GetTeamNumber()) then
                            print("Mine must be occupied by your team, fool")
                            return
                        end

                        if target.state == "building" then
                            --print("Extraction Building is still in construction, wait...")
                            return THINK_INTERVAL
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
                end
            else
                return
            end
        end)
            
        -- Hide Return
        local return_ability = FindReturnAbility(caster)
        if return_ability then
            return_ability:SetHidden(true)
        end
    else
        print("Not a valid target for this ability")
        caster:Stop()
    end
end

-- Toggles Off Gather
function CancelGather( event )
    local caster = event.caster
    local ability = event.ability
    local casterKV = GameRules.UnitKV[caster:GetUnitName()]

    local ability_order = event.event_ability
    if ability_order then
        local order_name = ability_order:GetAbilityName()
        --print("CancelGather Order: "..order_name)
        if string.match(order_name,"build_") then
            --print(" return")
            return
        end
    end

    caster:RemoveModifierByName("modifier_on_order_cancel_lumber")
    caster:RemoveModifierByName("modifier_gathering_lumber")
    caster:RemoveModifierByName("modifier_on_order_cancel_gold")
    caster:RemoveModifierByName("modifier_gathering_gold")

    ability.cancelled = true
    caster.state = "idle"

    -- Builder race
    local race = GetUnitRace(caster)

    -- If it's carrying resources, leave the return resources ability enabled
    if caster:HasModifier("modifier_carrying_lumber") or caster:HasModifier("modifier_carrying_gold") then
        caster:SwapAbilities(casterKV.GatherAbility, casterKV.ReturnAbility, false, true)
    end

    local tree = caster.target_tree
    if tree then
        caster.target_tree = nil
        tree.builder = nil
    end

    if race == "nightelf" then
        -- Give 1 extra second of fly movement
        caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
        Timers:CreateTimer(2,function() 
            caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
            caster:AddNewModifier(caster, nil, "modifier_phased", {duration=0.03})
        end)
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
    
    ToggleOff(ability)
    if gather_ability then
        ToggleOff(gather_ability)
    end
end

-- Toggles Off Return because of an order (e.g. Stop)
function CancelReturn( event )
    local caster = event.caster
    local ability = event.ability

    local ability_order = event.event_ability
    if ability_order then
        local order_name = ability_order:GetAbilityName()
        if string.match(order_name,"build_") then
            return
        end
    end

    -- Builder race
    local race = GetUnitRace(caster)

    local gather_ability = FindGatherAbility(caster)
    gather_ability.cancelled = true
    caster.state = "idle"

    local tree = caster.target_tree
    if tree then
        tree.builder = nil
    end
    
    ToggleOff(ability)
    if gather_ability then
        ToggleOff(gather_ability)
    end
end

-- Used in Human and Orc Gather Lumber
-- Gets called every second, increases the carried lumber of the builder by 1 until it can't carry more
-- Also does tree cutting and reacquiring of new trees when necessary.
function GatherLumber( event )
    local caster = event.caster
    local ability = event.ability
    local abilityLevel = ability:GetLevel() - 1
    local max_lumber_carried = ability:GetLevelSpecialValueFor("lumber_capacity", abilityLevel)
    local tree = caster.target_tree
    local casterKV = GameRules.UnitKV[caster:GetUnitName()]
    local lumber_per_hit = ability:GetLevelSpecialValueFor("lumber_per_hit", abilityLevel)
    local damage_to_tree = ability:GetLevelSpecialValueFor("damage_to_tree", abilityLevel)
    local playerID = caster:GetPlayerOwnerID()

    caster.state = "gathering_lumber"

    local return_ability = FindReturnAbility(caster)

    caster.lumber_gathered = caster.lumber_gathered + lumber_per_hit
    if tree and tree.health then

        -- Hit particle
        local particleName = "particles/custom/tree_pine_01_destruction.vpcf"
        local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(particle, 0, tree:GetAbsOrigin())

        tree.health = tree.health - damage_to_tree
        if tree.health <= 0 then
            tree:CutDown(caster:GetTeamNumber())

            -- Move to a new tree nearby
            local a_tree = FindEmptyNavigableTreeNearby(caster, tree:GetAbsOrigin(), TREE_FIND_RADIUS_FROM_TREE)
            if a_tree then
                caster.target_tree = a_tree
                caster:MoveToTargetToAttack(a_tree)
                if DEBUG_TREES then DebugDrawCircle(a_tree:GetAbsOrigin(), Vector(0,255,0), 255, 64, true, 10) end
            else
                -- Go to return resources (where it will find a tree nearby the town instead)
                return_ability:SetHidden(false)
                ability:SetHidden(true)
                
                caster:CastAbilityNoTarget(return_ability, playerID)
            end
        end
    end
        
    -- Show the stack of resources that the unit is carrying
    if not caster:HasModifier("modifier_carrying_lumber") then
        return_ability:ApplyDataDrivenModifier( caster, caster, "modifier_carrying_lumber", nil)
    end
    caster:SetModifierStackCount("modifier_carrying_lumber", caster, caster.lumber_gathered)
 
    -- Increase up to the max, or cancel
    if caster.lumber_gathered < max_lumber_carried and tree:IsStanding() then
        caster:StartGesture(ACT_DOTA_ATTACK)

        -- Show the return ability
        if return_ability:IsHidden() then
            caster:SwapAbilities(casterKV.GatherAbility, casterKV.ReturnAbility, false, true)
        end
    else
        -- RETURN     
        caster:RemoveModifierByName("modifier_gathering_lumber")

        -- Cast Return Resources    
        caster:CastAbilityNoTarget(return_ability, playerID)
    end
end

-- Used in Human and Orc Gather Gold
-- Gets called after the builder goes outside the mine
-- Takes DAMAGE_TO_MINE hit points away from the gold mine and starts the return
function GatherGold( event )
    local caster = event.caster
    local ability = event.ability
    local mine = caster.target_mine
    local playerID = caster:GetPlayerOwnerID()

    -- Builder race
    local race = GetUnitRace(caster)

    mine:SetHealth( mine:GetHealth() - DAMAGE_TO_MINE )
    caster.gold_gathered = DAMAGE_TO_MINE
    mine.builder = nil --Set the mine free for other builders to enter
    caster:RemoveNoDraw()
    caster.state = "gathering_gold"

    -- If the gold mine has no health left for another harvest
    if mine:GetHealth() < DAMAGE_TO_MINE then

        -- Destroy the nav blockers associated with it
        for k, v in pairs(mine.blockers) do
          DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
          DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
        end
        print("Gold Mine Collapsed at ", mine:GetHealth())
        mine:RemoveSelf()

        caster.target_mine = nil
    end

    local return_ability = FindReturnAbility(caster)
    return_ability:SetHidden(false)
    return_ability:ApplyDataDrivenModifier( caster, caster, "modifier_carrying_gold", nil)
    
    ability:SetHidden(true)

    caster:SetModifierStackCount("modifier_carrying_gold", caster, DAMAGE_TO_MINE)
                    
    -- Find where to put the builder outside the mine
    local position = mine.entrance
    FindClearSpaceForUnit(caster, position, true)

    -- Cast ReturnResources
    caster:CastAbilityNoTarget(return_ability, playerID)
end

-- Used in Night Elf Gather Lumber
function LumberGain( event )
    local ability = event.ability
    local caster = event.caster
    local lumber_gain = ability:GetSpecialValueFor("lumber_per_interval")
    local playerID = caster:GetPlayerOwnerID()
    Players:ModifyLumber( playerID, lumber_gain )
    PopupLumber( caster, lumber_gain)

    Scores:IncrementLumberHarvested( playerID, lumber_gain )
end

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
            builder:RemoveModifierByName("modifier_on_order_cancel_gold")
            builder:RemoveModifierByName("modifier_gathering_gold")
            builder.state = "idle"

            local ability = FindGatherAbility(builder)
            ability.cancelled = true
            ToggleOff(ability)

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

function SetGoldMineCounter( mine, count )
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

-- Called when the race_return_resources ability is cast
function ReturnResources( event )
    local caster = event.caster
    local ability = event.ability
    local playerID = caster:GetPlayerOwnerID()
    local casterKV = GameRules.UnitKV[caster:GetUnitName()]
    
    caster:Interrupt() -- Stops any instance of Hold/Stop the builder might have
    
    -- Return Ability On
    ability.cancelled = false
    if ability:GetToggleState() == false then
        ability:ToggleAbility()
    end

    local gather_ability = FindGatherAbility(caster)

    -- Destroy any old move timer
    if caster.moving_timer then
        Timers:RemoveTimer(caster.moving_timer)
    end

    -- Send back to the last resource gathered
    local coming_from = caster.last_resource_gathered

    -- LUMBER
    if caster:HasModifier("modifier_carrying_lumber") then
        -- Find where to return the resources
        local building = FindClosestResourceDeposit( caster, "lumber" )
        caster.target_building = building
        caster.state = "returning_lumber"


        -- Move towards it
        caster.moving_timer = Timers:CreateTimer(function() 

            -- End if killed
            if not (caster and IsValidEntity(caster) and caster:IsAlive()) then
                return
            end

            if not ability.cancelled then
                if caster.target_building and IsValidEntity(caster.target_building) and caster.state == "returning_lumber" then
                    local building_pos = caster.target_building:GetAbsOrigin()
                    local collision_size = GetCollisionSize(building)*2
                    local distance = (building_pos - caster:GetAbsOrigin()):Length()
                
                    if distance > collision_size then
                        caster:MoveToPosition(GetReturnPosition( caster, building ))        
                        return THINK_INTERVAL
                    elseif caster.lumber_gathered and caster.lumber_gathered > 0 then
                        --print("Building Reached at ",distance)
                        caster:RemoveModifierByName("modifier_carrying_lumber")
                        PopupLumber(caster, caster.lumber_gathered)
                        Players:ModifyLumber(playerID, caster.lumber_gathered)
                        Scores:IncrementLumberHarvested( playerID, caster.lumber_gathered )

                        -- Also handle possible gold leftovers if its being deposited in a city center
                        if caster:HasModifier("modifier_carrying_gold") then
                            caster:RemoveModifierByName("modifier_carrying_gold")
                            local gold_building = FindClosestResourceDeposit( caster, "gold" )
                            if gold_building == caster.target_building then 
                                local upkeep = Players:GetUpkeep( playerID )
                                local gold_gain = caster.gold_gathered * upkeep

                                Scores:IncrementGoldMined( playerID, caster.gold_gathered )
                                Scores:AddGoldLostToUpkeep( playerID, caster.gold_gathered - gold_gain )

                                Players:ModifyGold(playerID, gold_gain)
                                PopupGoldGain(caster, gold_gain)
                            end
                            caster.gold_gathered = 0
                        end

                        caster.lumber_gathered = 0

                        SendBackToGather(caster, gather_ability, caster.last_resource_gathered)
                    
                        return
                    end
                else
                    -- Find a new building deposit
                    building = FindClosestResourceDeposit( caster, "lumber" )
                    caster.target_building = building
                    return THINK_INTERVAL
                end
            else
                return
            end
        end)

    -- GOLD
    elseif caster:HasModifier("modifier_carrying_gold") then
        -- Find where to return the resources
        local building = FindClosestResourceDeposit( caster, "gold" )
        caster.target_building = building
        caster.state = "returning_gold"
        local collision_size = GetCollisionSize(building)*2

        -- Move towards it
        caster.moving_timer = Timers:CreateTimer(function() 

            -- End if killed
            if not (caster and IsValidEntity(caster) and caster:IsAlive()) then
                return
            end

            if not ability.cancelled then
                if caster.target_building and IsValidEntity(caster.target_building) and caster.state == "returning_gold" then
                    local building_pos = building:GetAbsOrigin()
                    local distance = (building_pos - caster:GetAbsOrigin()):Length()
                
                    if distance > collision_size then
                        caster:MoveToPosition(GetReturnPosition( caster, building ))
                        return THINK_INTERVAL
                    elseif caster.gold_gathered and caster.gold_gathered > 0 then
                        --print("Building Reached at ",distance)
                        local upkeep = Players:GetUpkeep( playerID )
                        local gold_gain = caster.gold_gathered * upkeep

                        Scores:IncrementGoldMined( playerID, caster.gold_gathered )
                        Scores:AddGoldLostToUpkeep( playerID, caster.gold_gathered - gold_gain )

                        Players:ModifyGold(playerID, gold_gain)
                        PopupGoldGain(caster, gold_gain)

                        caster:RemoveModifierByName("modifier_carrying_gold")

                        -- Also handle possible lumber leftovers
                        if caster:HasModifier("modifier_carrying_lumber") then
                            caster:RemoveModifierByName("modifier_carrying_lumber")
                            PopupLumber(caster, caster.lumber_gathered)
                            Players:ModifyLumber(playerID, caster.lumber_gathered)
                            Scores:IncrementLumberHarvested( playerID, caster.lumber_gathered )
                            caster.lumber_gathered = 0
                        end

                        caster.gold_gathered = 0

                        SendBackToGather(caster, gather_ability, caster.last_resource_gathered)
                    end
                else
                    -- Find a new building deposit
                    building = FindClosestResourceDeposit( caster, "gold" )
                    caster.target_building = building
                    return THINK_INTERVAL
                end
            else
                return
            end
        end)
    
    -- No resources to return, give the gather ability back
    else
        --print("TRIED TO RETURN NO RESOURCES")
        ToggleOff(gather_ability)
        caster:SwapAbilities(casterKV.GatherAbility,casterKV.ReturnAbility, true, false)
        caster:RemoveModifierByName("modifier_on_order_cancel_gold")
    end
end

function SendBackToGather( unit, ability, resource_type )
    local playerID = unit:GetPlayerOwnerID()
    local casterKV = GameRules.UnitKV[unit:GetUnitName()]

    if resource_type == "lumber" then
        --print("Back to the trees")
        if unit.target_tree and unit.target_tree:IsStanding() then
            unit:CastAbilityOnTarget(unit.target_tree, ability, playerID)
        else
            -- Find closest near the city center in a huge radius
            if unit.target_building then
                unit.target_tree = FindEmptyNavigableTreeNearby(unit, unit.target_building:GetAbsOrigin(), TREE_FIND_RADIUS_FROM_TOWN)
                if unit.target_tree and DEBUG_TREES then
                    DebugDrawCircle(unit.target_building:GetAbsOrigin(), Vector(255,0,0), 5, TREE_FIND_RADIUS_FROM_TOWN, true, 60)
                    DebugDrawCircle(unit.target_tree:GetAbsOrigin(), Vector(0,255,0), 255, 64, true, 10)
                end
            end
                                        
            if unit.target_tree then
                if DEBUG_TREES then DebugDrawCircle(unit.target_tree:GetAbsOrigin(), Vector(0,255,0), 255, 64, true, 10) end
                if unit.target_tree then
                    unit:CastAbilityOnTarget(unit.target_tree, ability, playerID)
                end
            else
                -- Cancel ability, couldn't find moar trees...
                ToggleOff(ability)

                unit:SwapAbilities(casterKV.GatherAbility, casterKV.ReturnAbility, true, false)
            end
        end

    elseif resource_type == "gold" then

        if unit.target_mine and IsValidEntity(unit.target_mine) then

            unit:SwapAbilities(casterKV.GatherAbility,casterKV.ReturnAbility, true, false)

            unit:CastAbilityOnTarget(unit.target_mine, ability, playerID)
        else
            print("Mine Collapsed")
            ToggleOff(ability)
            unit:SwapAbilities(casterKV.GatherAbility,casterKV.ReturnAbility, true, false)
            unit:RemoveModifierByName("modifier_on_order_cancel_gold")
        end
    end
end

function GetReturnPosition( unit, target )
    local origin = unit:GetAbsOrigin()
    local building_pos = target:GetAbsOrigin()
    local distance = target:GetHullRadius()
    return building_pos + (origin - building_pos):Normalized() * distance
end