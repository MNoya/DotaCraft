function dotacraft:FilterExecuteOrder( filterTable )
    --[[for k, v in pairs( filterTable ) do
        print("Order: " .. k .. " " .. tostring(v) )
    end]]

    local DEBUG = false

    local units = filterTable["units"]
    local order_type = filterTable["order_type"]
    local issuer = filterTable["issuer_player_id_const"]

    local numUnits = 0
    local numBuildings = 0
    if units then
        for n,unit_index in pairs(units) do
            local unit = EntIndexToHScript(unit_index)
            if not unit:IsBuilding() and not IsCustomBuilding(unit) then
                numUnits = numUnits + 1
            elseif unit:IsBuilding() or IsCustomBuilding(unit) then
                numBuildings = numBuildings + 1
            end
        end
    end

    if order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM or order_type == DOTA_UNIT_ORDER_SELL_ITEM then
        local purchaser = EntIndexToHScript(units["0"])
        print(purchaser:GetUnitName().." order item purchase/sell")
        if OnEnemyShop(purchaser) then
            print(" Order denied")
            return false
        else
            print(" Order allowed")
        end

    ------------------------------------------------
    --             No Target Orders               --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET then
        local unit = EntIndexToHScript(units["0"])
        if unit.skip then
            print("Skip")
            unit.skip = false
            return true
        else
            print("Execute this order")
        end

        local abilityIndex = filterTable["entindex_ability"]
        local ability = EntIndexToHScript(abilityIndex) 
        local abilityName = ability:GetAbilityName()

        local entityList = GetSelectedEntities(unit:GetPlayerOwnerID())

        if abilityName == "human_return_resources" then
            for k,entityIndex in pairs(entityList) do
                local unit = EntIndexToHScript(entityIndex)
                unit.skip = true

                local return_ability = unit:FindAbilityByName("human_return_resources")
                if return_ability and not return_ability:IsHidden() then
                    print("Order: Return resources")
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = false})
                end
            end
        end

    ------------------------------------------------
    --          Tree Gather Multi Orders          --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET_TREE then
        local unit = EntIndexToHScript(units["0"])
        print("DOTA_UNIT_ORDER_CAST_TARGET_TREE ",unit)
        if unit.skip_gather_check then
            print("Skip")
            unit.skip_gather_check = false
            return true
        else
            print("Execute this order")
        end

        local abilityIndex = filterTable["entindex_ability"]
        local ability = EntIndexToHScript(abilityIndex) 
        local abilityName = ability:GetAbilityName()

        local targetIndex = filterTable["entindex_target"]
        local tree_handle = TreeIndexToHScript(targetIndex)
        local position = tree_handle:GetAbsOrigin()
        if DEBUG then DebugDrawCircle(position, Vector(255,0,0), 100, 150, true, 5) end
        if DEBUG then DebugDrawLine(unit:GetAbsOrigin(), position, 255, 255, 255, true, 5) end
        print("Ability "..abilityName.." cast on tree number ",targetIndex, " handle index ",tree_handle:GetEntityIndex(),"position ",position)
        if abilityName == "nightelf_war_club" then
            return true
        end

        if DEBUG then DebugDrawText(unit:GetAbsOrigin(), "LOOKING FOR TREE INDEX "..targetIndex, true, 10) end
        
        -- Get the currently selected units and send new orders
        local entityList = GetSelectedEntities(unit:GetPlayerOwnerID())
        --print("Currently Selected Units:")
        --DeepPrintTable(entityList)
        if not entityList then
            return true
        end

        local numBuilders = 0
        for k,entityIndex in pairs(entityList) do
            if IsBuilder(EntIndexToHScript(entityIndex)) then
                numBuilders = numBuilders + 1
            end
        end

        if numBuilders == 1 then
            return true
        end

        local nearby_trees = GridNav:GetAllTreesAroundPoint(position, 150, true)
        if DEBUG then DebugDrawCircle(position, Vector(0,0,255), 100, 150, true, 5) end
        print(#nearby_trees,"trees nearby for ",numBuilders," builders")

        if abilityName == "nightelf_gather" then
            for k,entityIndex in pairs(entityList) do
                print("GatherTreeOrder for unit index ",entityIndex, position)

                --Execute the order to a navigable tree
                local unit = EntIndexToHScript(entityIndex)
                local empty_tree = FindEmptyNavigableTreeNearby(unit, position, 150 + 20 * numBuilders)
                if empty_tree then
                    local tree_index = GetTreeIndexFromHandle( empty_tree )
                    empty_tree.builder = unit -- Assign the wisp to this tree, so next time this isn't empty
                    unit.skip_gather_check = true
                    local gather_ability = unit:FindAbilityByName("nightelf_gather")
                    if gather_ability and gather_ability:IsFullyCastable() then
                        print("Order: Cast on Tree ",tree_index)
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
                    end
                else
                    print("No Empty Tree?")
                end
            end
        elseif abilityName == "human_gather" then

            for k,entityIndex in pairs(entityList) do
                print("GatherTreeOrder for unit index ",entityIndex, position)

                --Execute the order to a navigable tree
                local unit = EntIndexToHScript(entityIndex)
                local tree = FindEmptyNavigableTreeNearby(unit, position, 150 + 20 * numBuilders)
                if tree then 
                    --[[if not tree.peasants then
                        tree.peasants = 0
                    end
                    tree.peasants = tree.peasants + 1 -- Add one to the peasants assigned to this tree]]

                    tree.builder = unit
                    unit.skip_gather_check = true
                    local gather_ability = unit:FindAbilityByName("human_gather")
                    local return_ability = unit:FindAbilityByName("human_return_resources")
                    if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                        local tree_index = GetTreeIndexFromHandle( tree )
                        print("Order: Cast on Tree ",tree_index)
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
                    elseif return_ability and not return_ability:IsHidden() then
                        print("Order: Return resources")
                        unit.skip_gather_check = false -- Let it propagate to all selected units
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = false})
                    end
                else
                    print("No Empty Tree?")
                end
            end
        end

        -- Drop the original order
        return false
    end

    ------------------------------------------------
    --          Tree Gather Right-Click           --
    ------------------------------------------------
    local x = tonumber(filterTable["position_x"])
    local y = tonumber(filterTable["position_y"])
    local z = tonumber(filterTable["position_z"])
    local point = Vector(x,y,z) -- initial goal
    local TREE_RADIUS = 100
    local trees = GridNav:GetAllTreesAroundPoint(point, TREE_RADIUS, true)
    local entityIndex = units["0"]
    local unit = EntIndexToHScript(entityIndex)

    if order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION and IsBuilder(unit) and #trees>0 then
        
        local race = GetUnitRace(unit)
        local gather_ability = unit:FindAbilityByName(race.."_gather")
        local entityList = GetSelectedEntities(unit:GetPlayerOwnerID())
        local numBuilders = 0
        for k,entityIndex in pairs(entityList) do
            if IsBuilder(EntIndexToHScript(entityIndex)) then
                numBuilders = numBuilders + 1
            end
        end

        -- If clicking near a tree
        if IsBuilder(unit) and #trees>0 then
            if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                local empty_tree = FindEmptyNavigableTreeNearby(unit, point, TREE_RADIUS * 20 + numBuilders)
                if empty_tree then
                    local tree_index = GetTreeIndexFromHandle( empty_tree )
                    print("Order: Cast on Tree ",tree_index)
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
                end
            elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
                -- Can the unit still gather more resources?
                if (unit.lumber_gathered and unit.lumber_gathered < 10) and not unit:HasModifier("modifier_returning_gold") then
                    --print("Keep gathering")

                    -- Swap to a gather ability and keep extracting
                    local empty_tree = FindEmptyNavigableTreeNearby(unit, point, TREE_RADIUS)
                    if empty_tree then
                        local tree_index = GetTreeIndexFromHandle( empty_tree )
                        unit:SwapAbilities(race.."_gather", race.."_return_resources", true, false)
                        print("Order: Cast on Tree ",tree_index)
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
                    end
                else
                    -- Return
                    local return_ability = unit:FindAbilityByName(race.."_return_resources")
                    local empty_tree = FindEmptyNavigableTreeNearby(unit, point, TREE_RADIUS)
                    unit.target_tree = empty_tree --The new selected tree
                    print("Order: Return resources")
                    unit.skip_gather_check = false -- Let it propagate to all selected units
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = false})
                end
            end
            return false
        else
            return true
        end
    end
    
    ------------------------------------------------
    --           Grid Unit Formation              --
    ------------------------------------------------
    if (order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION or order_type == DOTA_UNIT_ORDER_ATTACK_MOVE) and numUnits > 1 then

        -- Get buildings out of the units table
        local _units = {}
        for n, unit_index in pairs(units) do 
            local unit = EntIndexToHScript(unit_index)
            if not unit:IsBuilding() and not IsCustomBuilding(unit) then
                _units[#_units+1] = unit_index
            end
        end
        units = _units

        local x = tonumber(filterTable["position_x"])
        local y = tonumber(filterTable["position_y"])
        local z = tonumber(filterTable["position_z"])

        local SQUARE_FACTOR = 1.5 --1 is a perfect square, higher numbers will increase

        local navPoints = {}
        local first_unit = EntIndexToHScript(units[1])
        local origin = first_unit:GetAbsOrigin()

        local point = Vector(x,y,z) -- initial goal

		if DEBUG then DebugDrawCircle(point, Vector(255,0,0), 100, 18, true, 3) end

        local unitsPerRow = math.floor(math.sqrt(numUnits/SQUARE_FACTOR))
        local unitsPerColumn = math.floor((numUnits / unitsPerRow))
        local remainder = numUnits - (unitsPerRow*unitsPerColumn) 
        --print(numUnits.." units = "..unitsPerRow.." rows of "..unitsPerColumn.." with a remainder of "..remainder)

        local start = (unitsPerColumn-1)* -.5

        local curX = start
        local curY = 0

        local offsetX = 100
        local offsetY = 100
        local forward = (point-origin):Normalized()
        local right = RotatePosition(Vector(0,0,0), QAngle(0,90,0), forward)

        for i=1,unitsPerRow do
          for j=1,unitsPerColumn do
            --print ('grid point (' .. curX .. ', ' .. curY .. ')')
            local newPoint = point + (curX * offsetX * right) + (curY * offsetY * forward)
			if DEBUG then 
                DebugDrawCircle(newPoint, Vector(0,0,0), 255, 25, true, 5)
                DebugDrawText(newPoint, curX .. ', ' .. curY, true, 10) 
            end
            navPoints[#navPoints+1] = newPoint
            curX = curX + 1
          end
          curX = start
          curY = curY - 1
        end

        local curX = ((remainder-1) * -.5)

        for i=1,remainder do 
			--print ('grid point (' .. curX .. ', ' .. curY .. ')')
			local newPoint = point + (curX * offsetX * right) + (curY * offsetY * forward)
			if DEBUG then 
                DebugDrawCircle(newPoint, Vector(0,0,255), 255, 25, true, 5)
                DebugDrawText(newPoint, curX .. ', ' .. curY, true, 10) 
            end
			navPoints[#navPoints+1] = newPoint
			curX = curX + 1
        end

        for i=1,#navPoints do 
            local point = navPoints[i]
            --print(i,navPoints[i])
        end

        -- Sort the units by distance to the nav points
        sortedUnits = {}
        for i=1,#navPoints do
            local point = navPoints[i]
            local closest_unit_index = GetClosestUnitToPoint(units, point)
            if closest_unit_index then
                --print("Closest to point is ",closest_unit_index," - inserting in table of sorted units")
                table.insert(sortedUnits, closest_unit_index)

                --print("Removing unit of index "..closest_unit_index.." from the table:")
                --DeepPrintTable(units)
                units = RemoveElementFromTable(units, closest_unit_index)
            end
        end

        -- Sort the units by rank (1)
        unitsByRank = {}
        for i=0,4 do
            local units = GetUnitsWithFormationRank(sortedUnits, i)
            if units then
                unitsByRank[i] = units
            end
        end

        -- Order each unit sorted to move to its respective Nav Point
        local n = 0
        for i=0,4 do
            if unitsByRank[i] then
                for _,unit_index in pairs(unitsByRank[i]) do
                    local unit = EntIndexToHScript(unit_index)
                    --print("Issuing a New Movement Order to unit index: ",unit_index)

                    local pos = navPoints[tonumber(n)+1]
                    --print("Unit Number "..n.." moving to ", pos)
                    n = n+1
                    
                    ExecuteOrderFromTable({ UnitIndex = unit_index, OrderType = order_type, Position = pos, Queue = false})
                end
            end
        end
        return false
    
    ------------------------------------------------
    --          Gold Gather Multi Order           --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET then
        local unit = EntIndexToHScript(units["0"])
        if unit.skip_gather_check then
            print("Skip")
            unit.skip_gather_check = false
            return true
        else
            print("Execute this order")
        end

        local abilityIndex = filterTable["entindex_ability"]
        local ability = EntIndexToHScript(abilityIndex) 
        local abilityName = ability:GetAbilityName()

        local targetIndex = filterTable["entindex_target"]
        local target_handle = EntIndexToHScript(targetIndex)

        if target_handle:GetUnitName() == "gold_mine" then
            local gold_mine = target_handle        
            -- Get the currently selected units and send new orders
            local entityList = GetSelectedEntities(unit:GetPlayerOwnerID())
            --print("Currently Selected Units:")
            --DeepPrintTable(entityList)
            if not entityList then
                return true
            end

            for k,entityIndex in pairs(entityList) do
                local unit = EntIndexToHScript(entityIndex)
                local race = GetUnitRace(unit)
                local gather_ability = unit:FindAbilityByName(race.."_gather")          

                -- Gold gather
                if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                    unit.skip_gather_check = true
                    print("Order: Cast on ",gold_mine:GetUnitName())
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
                elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
                    -- Can the unit still gather more resources?
                    if (unit.lumber_gathered and unit.lumber_gathered < 10) and not unit:HasModifier("modifier_returning_gold") then
                        --print("Keep gathering")

                        -- Swap to a gather ability and keep extracting
                        unit.skip_gather_check = true
                        unit:SwapAbilities(race.."_gather", race.."_return_resources", true, false)
                        print("Order: Cast on ",gold_mine:GetUnitName())
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
                    else
                        -- Return
                        local return_ability = unit:FindAbilityByName(race.."_return_resources")
                        unit.target_mine = gold_mine
                        print("Order: Return resources")
                        unit.skip_gather_check = false -- Let it propagate to all selected units
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = false})
                    end
                end
            end
        end

    end

    return true
end

------------------------------------------------
--          Gold Gather Right-Click           --
------------------------------------------------
function dotacraft:GoldGatherOrder( event )
    local pID = event.pID
    local entityIndex = event.mainSelected
    local targetIndex = event.targetIndex
    local gold_mine = EntIndexToHScript(targetIndex)
    local selectedEntities = GetSelectedEntities(pID)
    print("GOLD GATHER")

    local unit = EntIndexToHScript(entityIndex)
    local race = GetUnitRace(unit)
    local gather_ability = unit:FindAbilityByName(race.."_gather")

    -- Gold gather
    if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
        print("Order: Cast on ",gold_mine:GetUnitName())
        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
    elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
        -- Can the unit still gather more resources?
        if (unit.lumber_gathered and unit.lumber_gathered < 10) and not unit:HasModifier("modifier_returning_gold") then
            --print("Keep gathering")

            -- Swap to a gather ability and keep extracting
            unit:SwapAbilities(race.."_gather", race.."_return_resources", true, false)
            print("Order: Cast on ",gold_mine:GetUnitName())
            ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
        else
            -- Return
            local return_ability = unit:FindAbilityByName(race.."_return_resources")
            unit.target_mine = gold_mine
            print("Order: Return resources")
            unit.skip_gather_check = false -- Let it propagate to all selected units
            ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = false})
        end
    end
end

------------------------------------------------
--             Repair Right-Click             --
------------------------------------------------
function dotacraft:RepairOrder( event )
    local pID = event.pID
    local entityIndex = event.mainSelected
    local targetIndex = event.targetIndex
    local building = EntIndexToHScript(targetIndex)
    local selectedEntities = GetSelectedEntities(pID)

    local unit = EntIndexToHScript(entityIndex)
    local race = GetUnitRace(unit)
    local repair_ability = unit:FindAbilityByName(race.."_gather")

    -- Repair
    if repair_ability and repair_ability:IsFullyCastable() and not repair_ability:IsHidden() then
        print("Order: Repair ",building:GetUnitName())
        --ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = repair_ability:GetEntityIndex(), Queue = false})

        -- Kill previous repair process if there is one
        unit:RemoveModifierByName("modifier_peasant_repairing")
        unit:RemoveModifierByName("modifier_on_order_cancel_repair")
        
        unit:CastAbilityOnTarget(EntIndexToHScript(targetIndex), repair_ability, pID)
    elseif repair_ability and repair_ability:IsFullyCastable() and repair_ability:IsHidden() then
        print("Order: Repair ",building:GetUnitName())
        
        -- Kill previous repair process if there is one
        unit:RemoveModifierByName("modifier_peasant_repairing")
        unit:RemoveModifierByName("modifier_on_order_cancel_repair")

        -- Swap to the repair ability and send repair order
        unit:SwapAbilities(race.."_gather", race.."_return_resources", true, false)
        unit:CastAbilityOnTarget(EntIndexToHScript(targetIndex), repair_ability, pID)
    end
end

------------------------------------------------
--          Rally Point Right-Click           --
------------------------------------------------
function dotacraft:OnBuildingRallyOrder( event )
    print("OnBuildingRallyOrder")

    -- Arguments
    local pID = event.pID
    local mainSelected = event.mainSelected
    local rally_type = event.rally_type
    local targetIndex = event.targetIndex -- Only on "mine" or "target" rally type
    local position = event.position -- Only on "position" rally type
    if position then
        position = Vector(position["0"], position["1"], position["2"])
    end

    local building = EntIndexToHScript(mainSelected)
    local player = PlayerResource:GetPlayer(pID)
    --if IsCustomBuilding(building) and not IsCustomTower(building) then

    -- Remove the old flag if there is one
    if building.flag and IsValidEntity(building.flag) then
        if player.flagParticle then
            ParticleManager:DestroyParticle(player.flagParticle, true)
            player.flagParticle = nil
        end
        -- If it has a position flag, remove the dummy (this destroys the particle)
        if building.flag.type == "position" then
            building.flag:RemoveSelf()
        end
    end

    if HasTrainAbility(building) and not IsCustomTower(building) then
        EmitSoundOnClient("DOTA_Item.ObserverWard.Activate", player)
        if rally_type == "position" then
            --DebugDrawCircle(position, Vector(255,0,0), 255, 20, true, 3)
           
            -- Tree rally
            local trees = GridNav:GetAllTreesAroundPoint(position, 50, true)
            if #trees>0 then
                local target_tree = trees[1]
                if target_tree then
                    local tree_pos = target_tree:GetAbsOrigin()
        
                    building.flag = target_tree
                    building.flag.type = "tree"

                    -- Custom origin particle on top of the tree
                    CreateRallyFlagForBuilding( building )
                end
            else

                -- Make a flag dummy on the position
                local teamNumber = building:GetTeamNumber()
                building.flag = CreateUnitByName("dummy_unit", position, false, building, building, teamNumber)
                building.flag.type = "position"

                CreateRallyFlagForBuilding( building )

                -- Extra X
                local color = TEAM_COLORS[teamNumber]
                local Xparticle = ParticleManager:CreateParticleForTeam("particles/custom/x_marker.vpcf", PATTACH_ABSORIGIN_FOLLOW, building.flag, teamNumber)
                ParticleManager:SetParticleControl(Xparticle, 15, Vector(color[1], color[2], color[3])) --Color   
            end

        elseif rally_type == "target" or rally_type == "mine" then

            -- Attach the flag to the target
            local target = EntIndexToHScript(targetIndex)
            building.flag = target
            building.flag.type = rally_type
           
            CreateRallyFlagForBuilding( building )
        end
    end
end

function CreateRallyFlagForBuilding( building )
    local flag_type = building.flag.type
    local teamNumber = building:GetTeamNumber()
    local color = TEAM_COLORS[teamNumber]
    local particleName = "particles/custom/rally_flag.vpcf"
    local particle
    if flag_type == "tree" then
        local tree_pos = building.flag:GetAbsOrigin()
        particle = ParticleManager:CreateParticleForTeam(particleName, PATTACH_CUSTOMORIGIN, building, teamNumber)
        ParticleManager:SetParticleControl(particle, 0, Vector(tree_pos.x, tree_pos.y, tree_pos.z+250)) -- Position
        ParticleManager:SetParticleControl(particle, 1, building:GetAbsOrigin()) --Orientation
        ParticleManager:SetParticleControl(particle, 15, Vector(color[1], color[2], color[3])) --Color
    elseif flag_type == "position" then
        local position = building.flag:GetAbsOrigin()
        particle = ParticleManager:CreateParticleForTeam(particleName, PATTACH_ABSORIGIN_FOLLOW, building.flag, teamNumber)
        ParticleManager:SetParticleControl(particle, 0, position) -- Position
        ParticleManager:SetParticleControl(particle, 1, building:GetAbsOrigin()) --Orientation
        ParticleManager:SetParticleControl(particle, 15, Vector(color[1], color[2], color[3])) --Color
    elseif flag_type == "target" or flag_type == "mine" then
        local target = building.flag
        if target and IsValidEntity(target) then
            particle = ParticleManager:CreateParticleForTeam(particleName, PATTACH_OVERHEAD_FOLLOW, target, teamNumber)
            ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin()) -- Position
            ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin() * target:GetForwardVector()) --Orientation
            ParticleManager:SetParticleControl(particle, 15, Vector(color[1], color[2], color[3])) --Color
        end
    end

    -- Stores the particle on the player handle to remove it when the selection changes
    local player = building:GetPlayerOwner()
    player.flagParticle = particle
end

------------------------------------------------
--              Utility functions             --
------------------------------------------------

-- Returns the closest unit to a point from a table of unit indexes
function GetClosestUnitToPoint( units_table, point )
    local closest_unit = units_table["0"]
    if not closest_unit then
        closest_unit = units_table[1]
    end
    if closest_unit then   
        local min_distance = (point - EntIndexToHScript(closest_unit):GetAbsOrigin()):Length()

        for _,unit_index in pairs(units_table) do
            local distance = (point - EntIndexToHScript(unit_index):GetAbsOrigin()):Length()
            if distance < min_distance then
                closest_unit = unit_index
                min_distance = distance
            end
        end
        return closest_unit
    else
        return nil
    end
end

-- Returns a table of units by index with the rank passed
function GetUnitsWithFormationRank( units_table, rank )
    local allUnitsOfRank = {}
    for _,unit_index in pairs(units_table) do
        if GetFormationRank( EntIndexToHScript(unit_index) ) == rank then
            table.insert(allUnitsOfRank, unit_index)
        end
    end
    if #allUnitsOfRank == 0 then
        return nil
    end
    return allUnitsOfRank
end

-- Returns the FormationRank defined in npc_units_custom
function GetFormationRank( unit )
    local rank = 0
    if unit:IsHero() then
        rank = GameRules.HeroKV[unit:GetUnitName()]["FormationRank"]
    elseif unit:IsCreature() then
        rank = GameRules.UnitKV[unit:GetUnitName()]["FormationRank"]
    end
    return rank
end

-- Does awful table-recreation because table.remove refuses to work. Lua pls
function RemoveElementFromTable(table, element)
    local new_table = {}
    for k,v in pairs(table) do
        if v and v ~= element then
            new_table[#new_table+1] = v
        end
    end

    return new_table
end


-- Returns wether the unit is trying to buy from an enemy shop
function OnEnemyShop( unit )
    local teamID = unit:GetTeamNumber()
    local position = unit:GetAbsOrigin()
    local own_base_name = "team_"..teamID
    local nearby_entities = Entities:FindAllByNameWithin("team_*", position, 1000)

    if (#nearby_entities > 0) then
        for k,ent in pairs(nearby_entities) do
            if not string.match(ent:GetName(), own_base_name) then
                print("OnEnemyShop true")
                return true
            end
        end
    end
    return false
end










--[[
DOTA_UNIT_ORDER_ATTACK_MOVE: 3
DOTA_UNIT_ORDER_ATTACK_TARGET: 4
DOTA_UNIT_ORDER_BUYBACK: 23
DOTA_UNIT_ORDER_CAST_NO_TARGET: 8
DOTA_UNIT_ORDER_CAST_POSITION: 5
DOTA_UNIT_ORDER_CAST_RUNE: 26
DOTA_UNIT_ORDER_CAST_TARGET: 6
DOTA_UNIT_ORDER_CAST_TARGET_TREE: 7
DOTA_UNIT_ORDER_CAST_TOGGLE: 9
DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO: 20
DOTA_UNIT_ORDER_DISASSEMBLE_ITEM: 18
DOTA_UNIT_ORDER_DROP_ITEM: 12
DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH: 25
DOTA_UNIT_ORDER_GIVE_ITEM: 13
DOTA_UNIT_ORDER_GLYPH: 24
DOTA_UNIT_ORDER_HOLD_POSITION: 10
DOTA_UNIT_ORDER_MOVE_ITEM: 19
DOTA_UNIT_ORDER_MOVE_TO_DIRECTION: 28
DOTA_UNIT_ORDER_MOVE_TO_POSITION: 1
DOTA_UNIT_ORDER_MOVE_TO_TARGET: 2
DOTA_UNIT_ORDER_NONE: 0
DOTA_UNIT_ORDER_PICKUP_ITEM: 14
DOTA_UNIT_ORDER_PICKUP_RUNE: 15
DOTA_UNIT_ORDER_PING_ABILITY: 27
DOTA_UNIT_ORDER_PURCHASE_ITEM: 16
DOTA_UNIT_ORDER_SELL_ITEM: 17
DOTA_UNIT_ORDER_STOP: 21
DOTA_UNIT_ORDER_TAUNT: 22
DOTA_UNIT_ORDER_TRAIN_ABILITY: 11
]]