------------------------------------------
--             Build Scripts
------------------------------------------

-- A build ability is used (not yet confirmed)
function Build( event )
    local caster = event.caster
    local ability = event.ability
    local ability_name = ability:GetAbilityName()
    local AbilityKV = GameRules.AbilityKV
    local UnitKV = GameRules.UnitKV
    local casterKV = GameRules.UnitKV[caster:GetUnitName()]

    if caster:IsIdle() then
        caster:Interrupt()
    end

    -- Handle the name for item-ability build
    local building_name
    if event.ItemUnitName then
        building_name = event.ItemUnitName --Directly passed through the runscript
    else
        building_name = AbilityKV[ability_name].UnitName --Building Helper value
    end

    local construction_size = BuildingHelper:GetConstructionSize(building_name)
    local construction_radius = construction_size * 64 - 32

    -- Checks if there is enough custom resources to start the building, else stop.
    local unit_table = UnitKV[building_name]
    local gold_cost = ability:GetSpecialValueFor("gold_cost")
    local lumber_cost = ability:GetSpecialValueFor("lumber_cost")

    local hero = caster:GetOwner()
    local playerID = hero:GetPlayerID()
    local player = PlayerResource:GetPlayer(playerID)    
    local teamNumber = hero:GetTeamNumber()

    -- If the ability has an AbilityGoldCost, it's impossible to not have enough gold the first time it's cast
    -- Always refund the gold here, as the building hasn't been placed yet
    Players:ModifyGold(playerID, gold_cost)

    if not Players:HasEnoughLumber( playerID, lumber_cost ) then
        return
    end

    -- Makes a building dummy and starts panorama ghosting
    BuildingHelper:AddBuilding(event)

    -- Additional checks to confirm a valid building position can be performed here
    event:OnPreConstruction(function(vPos)

        -- Enemy unit check
        local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
        local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
        local enemies = FindUnitsInRadius(teamNumber, vPos, nil, construction_size, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_ANY_ORDER, false)

        if #enemies > 0 then
            SendErrorMessage(caster:GetPlayerOwnerID(), "#error_invalid_build_position")
            return false
        end

           -- Blight check
           if string.match(building_name, "undead") and building_name ~= "undead_necropolis" then
               local bHasBlight = HasBlight(vPos)
               BuildingHelper:print("Blight check for "..building_name..":", bHasBlight)
               if not bHasBlight then
                   SendErrorMessage(caster:GetPlayerOwnerID(), "#error_must_build_on_blight")
                   return false
               end
           end

            -- Proximity to gold mine check for Human/Orc: Main Buildings can be as close as 768.015 towards the center of the Gold Mine.
            if HasGoldMineDistanceRestriction(building_name) then
                local nearby_mine = Entities:FindAllByNameWithin("*gold_mine", vPos, 768)
                if #nearby_mine > 0 then
                    SendErrorMessage(caster:GetPlayerOwnerID(), "#error_too_close_to_goldmine")
                    return false
                end
           end

            -- If not enough resources to queue, stop
            if not Players:HasEnoughGold( playerID, gold_cost ) then
                return false
            end

            if not Players:HasEnoughLumber( playerID, lumber_cost ) then
                return false
            end

        return true
    end)

    -- Position for a building was confirmed and valid
    event:OnBuildingPosChosen(function(vPos)
        
        -- Spend resources
        Players:ModifyGold(playerID, -gold_cost)
        Players:ModifyLumber(playerID, -lumber_cost)

        -- Play a sound
        Sounds:EmitSoundOnClient(playerID, "Building.Placement")
        EmitGlobalSound("Building.Placement")

        -- Cancel gather
        local gather_ability = FindGatherAbility(caster)
        if gather_ability then
            CancelGather({caster = caster, ability = gather_ability})
        end

        -- Move allied units away from the building place
        local units = FindUnitsInRadius(teamNumber, vPos, nil, construction_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
        
        for _,unit in pairs(units) do
            if unit ~= caster and unit:GetTeamNumber() == teamNumber and not IsCustomBuilding(unit) then
                -- This is still sketchy but works.
                if (unit:IsIdle() and unit.state ~= "repairing") then
                    BuildingHelper:print("Moving unit "..unit:GetUnitName().." outside of the building area")
                    local origin = unit:GetAbsOrigin()
                    local front_position = origin + (origin - vPos):Normalized() * (construction_radius - (vPos-origin):Length2D())
                    ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = front_position, Queue = false})
                    unit:AddNewModifier(caster, nil, "modifier_phased", {duration=1})
                end
            end
        end
    end)

    -- The construction failed and was never confirmed due to the gridnav being blocked in the attempted area
    event:OnConstructionFailed(function()
        local playerTable = BuildingHelper:GetPlayerTable(playerID)
        local name = playerTable.activeBuilding

        BuildingHelper:print("Failed placement of " .. name)
        SendErrorMessage(caster:GetPlayerOwnerID(), "#error_invalid_build_position")
    end)

    -- Cancelled due to ClearQueue
    event:OnConstructionCancelled(function(work)
        local name = work.name
        BuildingHelper:print("Cancelled construction of " .. name)

        -- Refund resources for this cancelled work
        if work.refund then
            Players:ModifyGold(playerID, gold_cost)
            Players:ModifyLumber(playerID, lumber_cost)
        end
    end)

    -- A building unit was created
    event:OnConstructionStarted(function(unit)
        BuildingHelper:print("Started construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
        -- Play construction sound

        -- If it's an item-ability and has charges, remove a charge or remove the item if no charges left
        if ability.GetCurrentCharges and not ability:IsPermanent() then
            local charges = ability:GetCurrentCharges()
            charges = charges-1
            if charges == 0 then
                ability:RemoveSelf()
            else
                ability:SetCurrentCharges(charges)
            end
        end

        -- Units can't attack while building
        unit.original_attack = unit:GetAttackCapability()
        unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)

        -- Give item to cancel
        local item = CreateItem("item_building_cancel", playersHero, playersHero)
        unit:AddItem(item)

        -- FindClearSpace for the builder
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
        caster:AddNewModifier(caster, nil, "modifier_phased", {duration=0.03})

        -- Remove invulnerability on npc_dota_building baseclass
        unit:RemoveModifierByName("modifier_invulnerable")

        -- Particle effect
        ApplyModifier(unit, "modifier_construction")

        -- Check the abilities of this building, disabling those that don't meet the requirements
        CheckAbilityRequirements( unit, playerID )

        -- Add roots to ancient
        local ancient_roots = unit:FindAbilityByName("nightelf_uproot")
        if ancient_roots then
            ancient_roots:ApplyDataDrivenModifier(unit, unit, "modifier_rooted_ancient", {})
        end

        -- Apply the current level of Masonry to the newly upgraded building
        local masonry_rank = Players:GetCurrentResearchRank(playerID, "human_research_masonry1")
        if masonry_rank and masonry_rank > 0 then
            BuildingHelper:print("Applying masonry rank "..masonry_rank.." to this building construction")
            UpdateUnitUpgrades( unit, playerID, "human_research_masonry"..masonry_rank )
        end

        -- Apply altar linking
        if string.find( unit:GetUnitName(), "altar") then
            unit:AddAbility("ability_altar")
            local ability = unit:FindAbilityByName("ability_altar")
            ability:SetLevel(1)
        end

        -- Add the building handle to the list of structures
        Players:AddStructure(playerID, unit)
    end)

    -- A building finished construction
    event:OnConstructionCompleted(function(unit)
        BuildingHelper:print("Completed construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
        
        -- Play construction complete sound

        -- Give the unit their original attack capability
        unit:SetAttackCapability(unit.original_attack)

        -- Let the building cast abilities
        unit:RemoveModifierByName("modifier_construction")

        -- Remove item_building_cancel and reorder
        RemoveItemByName(unit, "item_building_cancel")
        ReorderItems(unit)

        local building_name = unit:GetUnitName()
        --[[local builders = {}
        if unit.builder then
            table.insert(builders, unit.builder)
        elseif unit.units_repairing then
            builders = unit.units_repairing
        end

        -- When building one of the lumber-only buildings, send the builder(s) to auto-gather lumber after the building is done
        Timers:CreateTimer(0.5, function() 
        if builders and building_name == "human_lumber_mill" or building_name == "orc_war_mill" then
            BuildingHelper:print("Sending "..#builders.." builders to gather lumber after finishing "..building_name)
            
            for k,builder in pairs(builders) do
                local race = GetUnitRace(builder)
                local gather_ability = builder:FindAbilityByName(race.."_gather")
                if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                    local empty_tree = FindEmptyNavigableTreeNearby(builder, unit:GetAbsOrigin(), 2000)
                    if empty_tree then
                        local tree_index = GetTreeIdForEntityIndex( empty_tree:GetEntityIndex() )
                        ExecuteOrderFromTable({ UnitIndex = builder:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
                    end
                elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
                    -- Can the unit still gather more resources?
                    if (builder.lumber_gathered and builder.lumber_gathered < 10) and not builder:HasModifier("modifier_returning_gold") then
                        local empty_tree = FindEmptyNavigableTreeNearby(builder, unit:GetAbsOrigin(), 2000)
                        if empty_tree then
                            local tree_index = GetTreeIdForEntityIndex( empty_tree:GetEntityIndex() )
                            builder:SwapAbilities(race.."_gather", race.."_return_resources", true, false)
                            ExecuteOrderFromTable({ UnitIndex = builder:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
                        end
                    else
                        -- Return
                        local return_ability = builder:FindAbilityByName(race.."_return_resources")
                        local empty_tree = FindEmptyNavigableTreeNearby(builder, point, TREE_RADIUS)
                        builder.target_tree = empty_tree --The new selected tree
                        ExecuteOrderFromTable({ UnitIndex = builder:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = false})
                    end
                end
            end
            return false
        end
        end)]]

        -- Add 1 to the player building tracking table for that name
        local buildingTable = Players:GetBuildingTable(playerID)
        if not buildingTable[building_name] then
            buildingTable[building_name] = 1
        else
            buildingTable[building_name] = buildingTable[building_name] + 1
        end

        -- Add blight if its an undead building
        if IsUndead(unit) then
            local size = "small"
            if unit:GetUnitName() == "undead_necropolis" then
                radius = "large"
            end
            CreateBlight(unit:GetAbsOrigin(), radius)
        end

        -- Add ability_shop on buildings labeled with _shop
        if string.match( unit:GetUnitLabel(), "_shop") then
            TeachAbility(unit, "ability_shop")
        end

        -- If it's a city center, check for city_center_level updates
        if IsCityCenter(unit) then
            Players:CheckCurrentCityCenters(playerID)
        end

        -- Add to the Food Limit if possible
        local food_produced = GetFoodProduced(unit)
        if food_produced ~= 0 then
            Players:ModifyFoodLimit(playerID, food_produced)
        end

        -- Update the abilities of the builders and buildings
        local playerUnits = Players:GetUnits(playerID)
        for k,units in pairs(playerUnits) do
            CheckAbilityRequirements( units, playerID )
        end

        local playerStructures = Players:GetStructures(playerID)
        for k,structure in pairs(playerStructures) do
            CheckAbilityRequirements( structure, playerID )
        end

    end)

    -- These callbacks will only fire when the state between below half health/above half health changes.
    -- i.e. it won't fire multiple times unnecessarily.
    event:OnBelowHalfHealth(function(unit)
        BuildingHelper:print("" .. unit:GetUnitName() .. " is below half health.")
                
        local item = CreateItem("item_apply_modifiers", nil, nil)
        item:ApplyDataDrivenModifier(unit, unit, "modifier_onfire", {})
        item = nil

    end)

    event:OnAboveHalfHealth(function(unit)
        BuildingHelper:print("" ..unit:GetUnitName().. " is above half health.")

        unit:RemoveModifierByName("modifier_onfire")
        
    end)
end

-- Called when the Cancel ability-item is used
function CancelBuilding( keys )
    BuildingHelper:CancelBuilding(keys)
end

------------------------------------------
--               Gather Scripts     
-- human_gather orc_gather share the same tree and behavior
-- undead_gather (ghoul) has the same tree behavior
-- undead_gather (acolyte) and nightelf_gather share the same mine behavior
-- All builders share the same building repair behavior except for humans who can also construct with multiple builders
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
    local casterKV = GameRules.UnitKV[caster:GetUnitName()]

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
        
        -- Gather cancels queue
        BuildingHelper:ClearQueue(caster)

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
            print(" The Tree already has a wisp in it, find another one!")
            caster:Interrupt()
            return
        end

        local tree_pos = tree:GetAbsOrigin()
        local particleName = "particles/ui_mouseactions/ping_circle_static.vpcf"
        local particle = ParticleManager:CreateParticleForPlayer(particleName, PATTACH_CUSTOMORIGIN, caster, caster:GetPlayerOwner())
        ParticleManager:SetParticleControl(particle, 0, Vector(tree_pos.x, tree_pos.y, tree_pos.z+20))
        ParticleManager:SetParticleControl(particle, 1, Vector(0,255,0))
        Timers:CreateTimer(3, function() 
            ParticleManager:DestroyParticle(particle, true)
        end)

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

        -- Gather cancels queue
        BuildingHelper:ClearQueue(caster)

        -- Disable this for Ghouls
        if caster:GetUnitName() == "undead_ghoul" then
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

                        local counter = #mine.builders
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
                            RemoveUnitFromSelection(caster)
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

    -- Repair Building / Siege
    elseif target_class == "npc_dota_creature" then
        if (IsCustomBuilding(target) or IsMechanical(target)) and target:GetHealthDeficit() > 0 and not target.unsummoning and not target.frozen then

            -- Only Humans can assist building construction
            if race ~= "human" and target.state == "building" then
                caster:Interrupt()
                return
            end

            -- Ghouls don't repair
            if caster:GetUnitName() == "undead_ghoul" then
                caster:Interrupt()
                return
            end

            caster.repair_target = target
            
            ability.cancelled = false
            caster.state = "moving_to_repair"

            -- Destroy any old move timer
            if caster.moving_timer then
                Timers:RemoveTimer(caster.moving_timer)
            end

            -- Fake toggle the ability, cancel if any other order is given
            if ability:GetToggleState() == false then
                ability:ToggleAbility()
            end

            -- Recieving another order will cancel this
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_on_order_cancel_repair", {})

            local collision_size = GetCollisionSize(target)*2 + 64

            caster.moving_timer = Timers:CreateTimer(function()

                -- End if killed
                if not (caster and IsValidEntity(caster) and caster:IsAlive()) then
                    return
                end

                -- Move towards the target until close range
                if not ability.cancelled and caster.state == "moving_to_repair" then
                    if caster.repair_target and IsValidEntity(caster.repair_target) then
                        local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length()
                        
                        if distance > collision_size then
                            caster:MoveToPosition(target:GetAbsOrigin())
                            return THINK_INTERVAL
                        else
                            --print("Reached target, starting the Repair process")
                            -- Must refresh the modifier to make sure the OnCreated is executed
                            if caster:HasModifier("modifier_builder_repairing") then
                                caster:RemoveModifierByName("modifier_builder_repairing")
                            end
                            Timers:CreateTimer(function()
                                ability:ApplyDataDrivenModifier(caster, caster, "modifier_builder_repairing", {})
                            end)
                            return
                        end
                    else
                        print("Building was killed in the way of a builder to repair it")
                        caster:RemoveModifierByName("modifier_on_order_cancel_repair")
                        CancelGather(event)
                    end
                else
                    return
                end
            end)
        else
            print("Not a valid repairable unit or already on full health")
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
    local casterKV = GameRules.UnitKV[caster:GetUnitName()]

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
    local casterKV = GameRules.UnitKV[caster:GetUnitName()] --
    local UnitKV = GameRules.UnitKV
    local lumber_per_hit = ability:GetLevelSpecialValueFor("lumber_per_hit", abilityLevel)
    local damage_to_tree = ability:GetLevelSpecialValueFor("damage_to_tree", abilityLevel)

    -- Builder race
    local race = GetUnitRace(caster)

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
                local player = caster:GetPlayerOwnerID()
                return_ability:SetHidden(false)
                ability:SetHidden(true)
                
                caster:CastAbilityNoTarget(return_ability, player)
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
        local player = caster:GetOwner():GetPlayerID()
        caster:RemoveModifierByName("modifier_gathering_lumber")

        -- Cast Return Resources    
        caster:CastAbilityNoTarget(return_ability, player)
    end
end

-- Used in Human and Orc Gather Gold
-- Gets called after the builder goes outside the mine
-- Takes DAMAGE_TO_MINE hit points away from the gold mine and starts the return
function GatherGold( event )
    local caster = event.caster
    local ability = event.ability
    local mine = caster.target_mine
    local casterKV = GameRules.UnitKV[caster:GetUnitName()]

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

    local player = caster:GetOwner():GetPlayerID()
                    
    -- Find where to put the builder outside the mine
    local position = mine.entrance
    FindClearSpaceForUnit(caster, position, true)

    -- Cast ReturnResources
    caster:CastAbilityNoTarget(return_ability, player)
end

-- Used in Night Elf Gather Lumber
function LumberGain( event )
    local ability = event.ability
    local caster = event.caster
    local lumber_gain = ability:GetSpecialValueFor("lumber_per_interval")
    local playerID = caster:GetPlayerOwnerID()
    Players:ModifyLumber( playerID, lumber_gain )
    PopupLumber( caster, lumber_gain)
end

-- Used in Nigh Elf and Undead Gather Gold
function GoldGain( event )
    local ability = event.ability
    local caster = event.caster
    local playerID = caster:GetPlayerOwnerID()
    local hero = caster:GetOwner()
    local race = GetUnitRace(caster)
    local gold_gain = ability:GetSpecialValueFor("gold_per_interval")
    local casterKV = GameRules.UnitKV[caster:GetUnitName()]
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

        mine:RemoveSelf()

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
    local hero = caster:GetOwner()
    local player = caster:GetPlayerOwner()
    local playerID = hero:GetPlayerID()
    local casterKV = GameRules.UnitKV[caster:GetUnitName()]
    
    caster:Interrupt() -- Stops any instance of Hold/Stop the builder might have
    
    -- Builder race
    local race = GetUnitRace(caster)

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

                        -- Also handle possible gold leftovers if its being deposited in a city center
                        if caster:HasModifier("modifier_carrying_gold") then
                            caster:RemoveModifierByName("modifier_carrying_gold")
                            local gold_building = FindClosestResourceDeposit( caster, "gold" )
                            if gold_building == caster.target_building then 
                                local upkeep = Players:GetUpkeep( playerID )
                                local gold_gain = caster.gold_gathered * upkeep
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

                        Players:ModifyGold(playerID, gold_gain)
                        PopupGoldGain(caster, gold_gain)

                        caster:RemoveModifierByName("modifier_carrying_gold")

                        -- Also handle possible lumber leftovers
                        if caster:HasModifier("modifier_carrying_lumber") then
                            caster:RemoveModifierByName("modifier_carrying_lumber")
                            PopupLumber(caster, caster.lumber_gathered)
                            Players:ModifyLumber(playerID, caster.lumber_gathered)
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
    local race = GetUnitRace(unit)
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

--------------------------------
--       Repair Scripts       --
--------------------------------

-- These are the Repair ratios for any race
-- Repair Cost Ratio = 0.35 - Takes 105g to fully repair a building that costs 300. Also applies to lumber
-- Repair Time Ratio = 1.5 - Takes 150 seconds to fully repair a building that took 100seconds to build

-- Humans can assist the construction with multiple peasants
-- Rest of the races can assist the repairing (takes 1+ builder in consideration)
-- In that case, extra resources are consumed
-- Powerbuild Cost = THINK_INTERVAL5 - Added for every extra builder repairing the same building
-- Powerbuild Rate = 0.60 - Fastens the ratio by 60%?
    
-- Values are taken from the UnitKV GoldCost LumberCost and BuildTime

function Repair( event )
    local caster = event.caster -- The builder
    local ability = event.ability
    local building = event.target -- The building to repair

    local hero = caster:GetOwner()
    local player = caster:GetPlayerOwner()
    local playerID = hero:GetPlayerID()

    local building_name = building:GetUnitName()
    local building_info = GameRules.UnitKV[building_name]
    local gold_cost = building_info.GoldCost
    local lumber_cost = building_info.LumberCost
    local build_time = building_info.BuildTime

    local state = building.state -- "completed" or "building"
    local health_deficit = building:GetHealthDeficit()

    ToggleOn(ability)

    -- If its an unfinished building, keep track of how much does it require to mark as finished
    if not building.constructionCompleted and not building.health_deficit then
        building.missingHealthToComplete = health_deficit
    end

    -- Scale costs/time according to the stack count of builders reparing this
    if health_deficit > 0 then
        -- Initialize the tracking
        if not building.health_deficit then
            building.health_deficit = health_deficit
            building.gold_used = 0
            building.lumber_used = 0
            building.HPAdjustment = 0
            building.GoldAdjustment = 0
            building.time_started = GameRules:GetGameTime()
        end
        
        local stack_count = building:GetModifierStackCount( "modifier_repairing_building", ability )

        -- HP
        local health_per_second = building:GetMaxHealth() /  ( build_time * 1.5 ) * stack_count
        local health_float = health_per_second - math.floor(health_per_second) -- floating point component
        health_per_second = math.floor(health_per_second) -- round down

        -- Don't expend resources for the first peasant repairing the building if its a construction
        if not building.constructionCompleted then
            stack_count = stack_count - 1
        end

        -- Gold
        local gold_per_second = gold_cost / ( build_time * 1.5 ) * 0.35 * stack_count
        local gold_float = gold_per_second - math.floor(gold_per_second) -- floating point component
        gold_per_second = math.floor(gold_per_second) -- round down

        -- Lumber takes floats just fine
        local lumber_per_second = lumber_cost / ( build_time * 1.5 ) * 0.35 * stack_count

        --[[print("Building is repaired for "..health_per_second)
        if gold_per_second > 0 then
            print("Cost is "..gold_per_second.." gold and "..lumber_per_second.." lumber per second")
        else
            print("Cost is "..gold_float.." gold and "..lumber_per_second.." lumber per second")
        end]]
            
        local healthGain = 0
        if Players:HasEnoughGold( playerID, math.ceil(gold_per_second+gold_float) ) and Players:HasEnoughLumber( playerID, lumber_per_second ) then

            -- Health
            building.HPAdjustment = building.HPAdjustment + health_float
            if building.HPAdjustment > 1 then
                healthGain = health_per_second + 1
                building:SetHealth(building:GetHealth() + healthGain)
                building.HPAdjustment = building.HPAdjustment - 1
            else
                healthGain = health_per_second
                building:SetHealth(building:GetHealth() + health_per_second)
            end
            
            -- Consume Resources
            building.GoldAdjustment = building.GoldAdjustment + gold_float
            if building.GoldAdjustment > 1 then
                Players:ModifyGold(playerID, -gold_per_second - 1)
                building.GoldAdjustment = building.GoldAdjustment - 1
                building.gold_used = building.gold_used + gold_per_second + 1
            else
                Players:ModifyGold(playerID, -gold_per_second)
                building.gold_used = building.gold_used + gold_per_second
            end
            
            Players:ModifyLumber( playerID, -lumber_per_second )
            building.lumber_used = building.lumber_used + lumber_per_second
        else
            -- Remove the modifiers on the building and the builders
            building:RemoveModifierByName("modifier_repairing_building")
            print("Remove the modifiers on the building and the builders")
            for _,builder in pairs(building.units_repairing) do
                if builder and IsValidEntity(builder) then
                    builder:RemoveModifierByName("modifier_builder_repairing")
                end
            end
            print("Repair Ended, not enough resources!")
            building.health_deficit = nil
            building.missingHealthToComplete = nil

            -- Toggle off
            ToggleOff(ability)
        end

        -- Decrease the health left to finish construction and mark building as complete
        if building.missingHealthToComplete then
            building.missingHealthToComplete = building.missingHealthToComplete - healthGain
        end

    -- Building Fully Healed
    else
        -- Remove the modifiers on the building and the builders
        building:RemoveModifierByName("modifier_repairing_building")
        print("Building Fully Healed")
        for _,v in pairs(building.units_repairing) do
            local builder = EntIndexToHScript(v)
            if builder and IsValidEntity(builder) then
                builder:RemoveModifierByName("modifier_builder_repairing")
                builder.state = "idle"

                --This should only be done to the additional assisting builders, not the main one that started the construction
                if not builder.work then
                    BuildingHelper:AdvanceQueue(builder)
                end
            end
        end
        -- Toggle off
        ToggleOff(ability)

        --[[print("Repair End")
        print("Start HP/Gold/Lumber/Time: ", building.health_deficit, gold_cost, lumber_cost, build_time)
        print("Final HP/Gold/Lumber/Time: ", building:GetHealth(), building.gold_used, math.floor(building.lumber_used), GameRules:GetGameTime() - building.time_started)]]
        building.health_deficit = nil
    end

    -- Construction Ended
    if building.missingHealthToComplete and building.missingHealthToComplete <= 0 then
        building.missingHealthToComplete = nil
        building.constructionCompleted = true -- BuildingHelper will track this and know the building ended
    else
        --print("Missing Health to Complete building: ",building.missingHealthToComplete)
    end
end

function BuilderRepairing( event )
    local caster = event.caster
    local ability = event.ability
    local target = caster.repair_target

    print("Builder Repairing ",target:GetUnitName(), caster, ability, target)
    
    caster.state = "repairing"

    -- Apply a modifier stack to the building, to show how many peasants are working on it (and scale the Powerbuild costs)
    local modifierName = "modifier_repairing_building"
    if target:HasModifier(modifierName) then
        target:SetModifierStackCount( modifierName, ability, target:GetModifierStackCount( modifierName, ability ) + 1 )
    else
        ability:ApplyDataDrivenModifier( caster, target, modifierName, { duration = duration } )
        target:SetModifierStackCount( modifierName, ability, 1 )
    end

    -- Keep a list of the units repairing this building
    if not target.units_repairing then
        target.units_repairing = {}
    end

    table.insert(target.units_repairing, caster:GetEntityIndex())
end

function BuilderStopRepairing( event )
    local caster = event.caster
    local ability = event.ability
    local building = caster.repair_target

    local ability_order = event.event_ability
    if ability_order then
        local order_name = ability_order:GetAbilityName()
        if string.match(order_name,"build_") then
            return
        end
    end
    
    caster:RemoveModifierByName("modifier_on_order_cancel_repair")
    caster:RemoveModifierByName("modifier_builder_repairing")
    caster:RemoveGesture(ACT_DOTA_ATTACK)

    caster.state = "idle"

    -- Apply a modifier stack to the building, to show how many builders are working on it (and scale the Powerbuild costs)
    local modifierName = "modifier_repairing_building"
    if building and IsValidEntity(building) and building:HasModifier(modifierName) then
        local current_stack = building:GetModifierStackCount( modifierName, ability )
        if current_stack > 1 then
            building:SetModifierStackCount( modifierName, ability, current_stack - 1 )
        else
            building:RemoveModifierByName( modifierName )
        end
    end

    -- Remove the builder from the list of units repairing the building
    local builder = getIndexTable(building.units_repairing, caster:GetEntityIndex())
    if builder and builder ~= -1 then
        table.remove(building.units_repairing, builder)
    end
end

function RepairAnimation( event )
    local caster = event.caster
    caster:StartGesture(ACT_DOTA_ATTACK)
end
