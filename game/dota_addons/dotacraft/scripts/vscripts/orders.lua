function dotacraft:FilterExecuteOrder( filterTable )
    --[[
    print("-----------------------------------------")
    for k, v in pairs( filterTable ) do
        print("Order: " .. k .. " " .. tostring(v) )
    end
    ]]

    local DEBUG = false

    local units = filterTable["units"]
    local order_type = filterTable["order_type"]
    local issuer = filterTable["issuer_player_id_const"]
    local abilityIndex = filterTable["entindex_ability"]
    local targetIndex = filterTable["entindex_target"]
    local x = tonumber(filterTable["position_x"])
    local y = tonumber(filterTable["position_y"])
    local z = tonumber(filterTable["position_z"])
    local point = Vector(x,y,z)
    local queue = filterTable["queue"] == 1

    local numUnits = 0
    local numBuildings = 0
    if units then
        for n,unit_index in pairs(units) do
            local unit = EntIndexToHScript(unit_index)
            if unit and IsValidEntity(unit) then
                unit.current_order = order_type -- Track the last executed order
                unit.orderTable = filterTable -- Keep the whole order table, to resume it later if needed
                
                if not unit:IsBuilding() and not IsCustomBuilding(unit) then
                    numUnits = numUnits + 1
                elseif unit:IsBuilding() or IsCustomBuilding(unit) then
                    numBuildings = numBuildings + 1
                end
            end
        end
    end

    -- Skip Prevents order loops
    local unit = EntIndexToHScript(units["0"])
    if unit then
        if unit.skip then
            unit.skip = false
            return true
        end
    end

    ------------------------------------------------
    --           Ability Multi Order              --
    ------------------------------------------------
    if abilityIndex and abilityIndex ~= 0 and IsMultiOrderAbility(EntIndexToHScript(abilityIndex)) then
        --print("Multi Order Ability")

        local ability = EntIndexToHScript(abilityIndex) 
        local abilityName = ability:GetAbilityName()
        local entityList = GetSelectedEntities(unit:GetPlayerOwnerID())
        if not entityList then return true end
        for _,entityIndex in pairs(entityList) do
            local caster = EntIndexToHScript(entityIndex)
            -- Make sure the original caster unit doesn't cast twice
            if caster and caster ~= unit and caster:HasAbility(abilityName) then
                local abil = caster:FindAbilityByName(abilityName)
                if abil and abil:IsFullyCastable() then

                    caster.skip = true
                    if order_type == DOTA_UNIT_ORDER_CAST_POSITION then
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = order_type, Position = point, AbilityIndex = abil:GetEntityIndex(), Queue = queue})

                    elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET then
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = order_type, TargetIndex = targetIndex, AbilityIndex = abil:GetEntityIndex(), Queue = queue})

                    else --order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET or order_type == DOTA_UNIT_ORDER_CAST_TOGGLE or order_type == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = order_type, AbilityIndex = abil:GetEntityIndex(), Queue = queue})
                    end
                end
            end
        end
        return true
    end

    ------------------------------------------------
    --              Sell Item Orders              --
    ------------------------------------------------
    if order_type == DOTA_UNIT_ORDER_SELL_ITEM then
        
        local item = EntIndexToHScript(filterTable.entindex_ability)
        local item_name = item:GetAbilityName()
        print(unit:GetUnitName().." "..ORDERS[order_type].." "..item_name)

        local player = unit:GetPlayerOwner()
        local pID = player:GetPlayerID()

        local bSellCondition = unit:CanSellItems() and item:IsSellable()
        if bSellCondition then
            SellCustomItem(unit, item)
        else
            SendErrorMessage( pID, "#error_cant_sell" )
        end

        return false

    ------------------------------------------------
    --              Drag Item Orders              --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_GIVE_ITEM then

        local item = EntIndexToHScript(filterTable.entindex_ability)
        local item_name = item:GetAbilityName()
        local target = EntIndexToHScript(filterTable.entindex_target)
        print(unit:GetUnitName().." "..units["0"].." "..ORDERS[order_type].." "..item_name.." -> "..target:GetUnitName().." "..filterTable.entindex_target)

        local bDroppable = item:IsDroppable()
        local bSellable = item:IsSellable()
        local bFriendly = IsAlliedUnit(unit, target) or IsNeutralUnit(target)
        local bValidBuilding = not IsCustomBuilding(target) or (IsCustomShop(target) and bSellable) -- Only drag sellable items on shop buildings
        
        local bDragCondition = bDroppable and bFriendly and bValidBuilding

        if bDragCondition then
            unit:MoveToNPCToGiveItem(target, item)
        else
            local pID = unit:GetPlayerOwnerID()
            if not bDroppable then
                SendErrorMessage( pID, "#error_cant_drop" )
            elseif not bFriendly then
                SendErrorMessage( pID, "#error_cant_take_items" )
            elseif not bValidBuilding then
                SendErrorMessage( pID, "#error_must_target_shop" )
            end
        end

        return false

    ------------------------------------------------
    --               Attack Orders                --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_ATTACK_TARGET then
        local target = EntIndexToHScript(targetIndex)
        local errorMsg = nil

        if not target then print("ERROR, ATTACK WITHOUT TARGET") return true end

        for n, unit_index in pairs(units) do 
            local unit = EntIndexToHScript(unit_index)
            if unit then
                if UnitCanAttackTarget(unit, target) then
                    unit.attack_target_order = target
                    unit.skip = true

                    -- Send the attack
                    ExecuteOrderFromTable({ UnitIndex = unit_index, OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET, TargetIndex = targetIndex, Queue = queue})

                else
                    unit.skip = true
                    
                    -- Move to position
                    ExecuteOrderFromTable({ UnitIndex = unit_index, OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE, Position = target:GetAbsOrigin(), Queue = queue})
                    
                    if not errorMsg then
                        local error_type = GetMovementCapability(target)
                        if error_type == "air" then
                            errorMsg = "#error_cant_target_air"
                        elseif error_type == "ground" then
                            errorMsg = "#error_must_target_air"
                        end

                        SendErrorMessage( unit:GetPlayerOwnerID(), errorMsg )
                    end
                end
            end
        end
        errorMsg = nil
        return false

    ------------------------------------------------
    --             No Target Orders               --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET and abilityIndex and abilityIndex ~= 0 then
        
        local ability = EntIndexToHScript(abilityIndex)
        if not ability then
            print("Error: CAST_NO_TARGET with an incorrect index")
            return true
        end
        local abilityName = ability:GetAbilityName()
        local entityList = GetSelectedEntities(unit:GetPlayerOwnerID())

        if string.match(abilityName, "_return_resources") then
            for k,entityIndex in pairs(entityList) do
                local unit = EntIndexToHScript(entityIndex)
                unit.skip = true

                local return_ability = FindReturnAbility(unit)
                if return_ability and not return_ability:IsHidden() then
                    --print("Order: Return resources")
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = queue})
                end
            end
        end
        return true

    ------------------------------------------------
    --          Tree Gather Multi Orders          --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET_TREE then
        local unit = EntIndexToHScript(units["0"])
        if DEBUG then print("DOTA_UNIT_ORDER_CAST_TARGET_TREE ",unit) end
    
        local abilityIndex = filterTable["entindex_ability"]
        local ability = EntIndexToHScript(abilityIndex) 
        local abilityName = ability:GetAbilityName()

        local treeID = filterTable["entindex_target"]
        local tree_index = GetEntityIndexForTreeId(treeID)
        local tree_handle = EntIndexToHScript(tree_index)

        local position = tree_handle:GetAbsOrigin()
        if DEBUG then
            DebugDrawCircle(position, Vector(255,0,0), 100, 150, true, 5)
            DebugDrawLine(unit:GetAbsOrigin(), position, 255, 255, 255, true, 5)
            print("Ability "..abilityName.." cast on tree number ",targetIndex, " handle index ",tree_handle:GetEntityIndex(),"position ",position)
        end
        if not string.match(abilityName, "gather") then
            return true
        end

        if DEBUG then DebugDrawText(unit:GetAbsOrigin(), "LOOKING FOR TREE INDEX "..targetIndex, true, 10) end
        
        -- Get the currently selected units and send new orders
        local entityList = GetSelectedEntities(unit:GetPlayerOwnerID())
        if not entityList then
            return true
        end

        local numBuilders = 0
        for k,entityIndex in pairs(entityList) do
            if CanGatherLumber(EntIndexToHScript(entityIndex)) then
                numBuilders = numBuilders + 1
            end
        end

        if numBuilders == 1 then
            return true
        end

        if abilityName == "nightelf_gather" then
            for k,entityIndex in pairs(entityList) do
                --print("GatherTreeOrder for unit index ",entityIndex, position)

                --Execute the order to a navigable tree
                local unit = EntIndexToHScript(entityIndex)
                local empty_tree = FindEmptyNavigableTreeNearby(unit, position, 150 + 20 * numBuilders)
                if empty_tree then
                    local tree_index = GetTreeIdForEntityIndex( empty_tree:GetEntityIndex() )
                    empty_tree.builder = unit -- Assign the wisp to this tree, so next time this isn't empty
                    unit.skip = true
                    local gather_ability = unit:FindAbilityByName("nightelf_gather")
                    if gather_ability and gather_ability:IsFullyCastable() then
                        --print("Order: Cast on Tree ",tree_index)
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                    end
                else
                    --print("No Empty Tree?")
                end
            end

        elseif string.match(abilityName,"_gather") then

            for k,entityIndex in pairs(entityList) do
                --print("GatherTreeOrder for unit index ",entityIndex, position)

                --Execute the order to a navigable tree
                local unit = EntIndexToHScript(entityIndex)
                local race = GetUnitRace(unit)
                local empty_tree = FindEmptyNavigableTreeNearby(unit, position, 150 + 20 * numBuilders)
                if empty_tree then 

                    empty_tree.builder = unit
                    unit.skip = true
                    local gather_ability = FindGatherAbility(unit)
                    local return_ability = FindReturnAbility(unit)
                    if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                        local tree_index = GetTreeIdForEntityIndex( empty_tree:GetEntityIndex() )
                        --print("Order: Cast on Tree ",tree_index)
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                    elseif return_ability and not return_ability:IsHidden() then
                        --print("Order: Return resources")
                        unit.skip = false -- Let it propagate to all selected units
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = queue})
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
    local TREE_RADIUS = 50
    local trees = GridNav:GetAllTreesAroundPoint(point, TREE_RADIUS, true)
    local entityIndex = units["0"]
    local unit = EntIndexToHScript(entityIndex)

    if order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION and CanGatherLumber(unit) and #trees>0 then
        
        local race = GetUnitRace(unit)
        local gather_ability = FindGatherAbility(unit)
        local return_ability = FindReturnAbility(unit)
        local pID = unit:GetPlayerOwnerID()
        local player = PlayerResource:GetPlayer(pID)
        local entityList = GetSelectedEntities(pID)
        local numBuilders = 0
        for k,entityIndex in pairs(entityList) do
            if CanGatherLumber(EntIndexToHScript(entityIndex)) then
                numBuilders = numBuilders + 1
            end
        end

        -- If clicking near a tree
        if CanGatherLumber(unit) and #trees>0 then
            if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                local empty_tree = FindEmptyNavigableTreeNearby(unit, point, TREE_RADIUS)
                if empty_tree then
                    local tree_index = GetTreeIdForEntityIndex( empty_tree:GetEntityIndex() )
                    --print("Order: Cast on Tree ",tree_index)
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                end
            elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
                -- Can the unit still gather more resources?
                if (unit.lumber_gathered and unit.lumber_gathered < Units:GetLumberCapacity(unit)) and not unit:HasModifier("modifier_returning_gold") then
                    --print("Keep gathering")

                    -- Swap to a gather ability and keep extracting
                    local empty_tree = FindEmptyNavigableTreeNearby(unit, point, TREE_RADIUS)
                    if empty_tree then
                        local tree_index = GetTreeIdForEntityIndex( empty_tree:GetEntityIndex() )
                        unit:SwapAbilities(gather_ability:GetAbilityName(), return_ability:GetAbilityName(), true, false)
                        --print("Order: Cast on Tree ",tree_index)
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                    end
                else
                    -- Return
                    local empty_tree = FindEmptyNavigableTreeNearby(unit, point, TREE_RADIUS)
                    unit.target_tree = empty_tree --The new selected tree
                    --print("Order: Return resources")
                    unit.skip = false -- Let it propagate to all selected units
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = queue})
                end
            end
            return false
        else
            return true
        end
    end

    if order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION and numBuildings > 0 then
        if unit and IsCustomBuilding(unit) then

            local event = { pID = issuer, mainSelected = unit:GetEntityIndex(), rally_type = "position", pos_x = x, pos_y = y, pos_z = z }
            dotacraft:OnBuildingRallyOrder( event )
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
            if unit and not unit:IsBuilding() and not IsCustomBuilding(unit) then
                _units[#_units+1] = unit_index
            end
        end
        units = _units

        local x = tonumber(filterTable["position_x"])
        local y = tonumber(filterTable["position_y"])
        local z = tonumber(filterTable["position_z"])

        local SQUARE_FACTOR = 1.3 --1 is a perfect square, higher numbers will increase the units per row

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

        local offsetX = 150
        local offsetY = 150
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
                    
                    ExecuteOrderFromTable({ UnitIndex = unit_index, OrderType = order_type, Position = pos, Queue = queue})
                end
            end
        end
        return false
    
    ------------------------------------------------
    --        Gold Gather/Repair Multi Order      --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET then
        local unit = EntIndexToHScript(units["0"])
    
        local abilityIndex = filterTable["entindex_ability"]
        local ability = EntIndexToHScript(abilityIndex) 
        local abilityName = ability:GetAbilityName()

        local targetIndex = filterTable["entindex_target"]
        local target_handle = EntIndexToHScript(targetIndex)
        local target_name = target_handle:GetUnitName()

        if target_name == "gold_mine" or
          ( (target_name == "nightelf_entangled_gold_mine" or target_name == "undead_haunted_mine" ) and target_handle:GetTeamNumber() == unit:GetTeamNumber()) then

            local gold_mine = target_handle
            
            -- Get the currently selected units and send new orders
            local pID = unit:GetPlayerOwnerID()
            local player = PlayerResource:GetPlayer(pID)
            local entityList = GetSelectedEntities(pID)
            if not entityList then
                return true
            end

            for k,entityIndex in pairs(entityList) do
                local unit = EntIndexToHScript(entityIndex)
                local race = GetUnitRace(unit)
                local gather_ability = FindGatherAbility(unit)
                local return_ability = FindReturnAbility(unit)

                -- Gold gather
                if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                    unit.skip = true
                    --print("Order: Cast on ",gold_mine:GetUnitName())
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
                    -- Can the unit still gather more resources?
                    if (unit.lumber_gathered and unit.lumber_gathered < Units:GetLumberCapacity(unit)) and not unit:HasModifier("modifier_returning_gold") then
                        --print("Keep gathering")

                        -- Swap to a gather ability and keep extracting
                        unit.skip = true
                        unit:SwapAbilities(gather_ability:GetAbilityName(), return_ability:GetAbilityName(), true, false)
                        --print("Order: Cast on ",gold_mine:GetUnitName())
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                    else
                        -- Return
                        unit.target_mine = gold_mine
                        --print("Order: Return resources")
                        unit.skip = false -- Let it propagate to all selected units
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = queue})
                    end
                end
            end
            
        elseif (IsCustomBuilding(target_handle) or IsMechanical(target_handle)) and target_handle:GetTeamNumber() == unit:GetTeamNumber() then
            --print("Order: Repair ",target_handle:GetUnitName())

            -- Get the currently selected units and send new orders
            local entityList = GetSelectedEntities(unit:GetPlayerOwnerID())
            if not entityList then
                return true
            end

            for k,entityIndex in pairs(entityList) do

                local unit = EntIndexToHScript(entityIndex)
                local race = GetUnitRace(unit)
                local repair_ability = unit:FindAbilityByName(race.."_gather")

                -- Repair
                if repair_ability and repair_ability:IsFullyCastable() and not repair_ability:IsHidden() then
                    --print("Order: Repair ",building:GetUnitName())
                    unit.skip = true
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = repair_ability:GetEntityIndex(), Queue = queue})
                
                elseif repair_ability and repair_ability:IsFullyCastable() and repair_ability:IsHidden() then
                    --print("Order: Repair ",building:GetUnitName())
        
                    -- Swap to the repair ability and send repair order
                    unit:SwapAbilities(race.."_gather", race.."_return_resources", true, false)
                    unit.skip = true
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = repair_ability:GetEntityIndex(), Queue = queue})
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
    local player = PlayerResource:GetPlayer(pID)
    local entityIndex = event.mainSelected
    local targetIndex = event.targetIndex
    local gold_mine = EntIndexToHScript(targetIndex)
    local queue = tobool(event.queue)
    dotacraft:RightClickOrder(event)

    local unit = EntIndexToHScript(entityIndex)
    local race = GetUnitRace(unit)
    local gather_ability = unit:FindAbilityByName(race.."_gather")

    -- Gold gather
    if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
        --print("Order: Cast on ",gold_mine:GetUnitName())
        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
    elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
        -- Can the unit still gather more resources?
        if (unit.lumber_gathered and unit.lumber_gathered < Units:GetLumberCapacity(unit)) and not unit:HasModifier("modifier_returning_gold") then
            --print("Keep gathering")

            -- Swap to a gather ability and keep extracting
            unit:SwapAbilities(race.."_gather", race.."_return_resources", true, false)
            --print("Order: Cast on ",gold_mine:GetUnitName())
            ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
        else
            -- Return
            local return_ability = unit:FindAbilityByName(race.."_return_resources")
            unit.target_mine = gold_mine
            --print("Order: Return resources")
            unit.skip = false -- Let it propagate to all selected units
            ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = queue})
        end
    end
end

------------------------------------------------
--              Replenish Right-Click         --
------------------------------------------------
function dotacraft:MoonWellOrder( event )
    local pID = event.pID
    local entityIndex = event.mainSelected
    local target = EntIndexToHScript(entityIndex)
    local targetIndex = event.targetIndex
    local moon_well = EntIndexToHScript(targetIndex)
    dotacraft:RightClickOrder(event)

    local replenish = moon_well:FindAbilityByName("nightelf_replenish_mana_and_life")
    moon_well:CastAbilityOnTarget(target, replenish, moon_well:GetPlayerOwnerID())
end

------------------------------------------------
--                Burrow Right-Click          --
------------------------------------------------
function dotacraft:BurrowOrder( event )
    local pID = event.pID
    local entityIndex = event.mainSelected
    local burrowIndex = event.targetIndex
    local burrow = EntIndexToHScript(burrowIndex)
    dotacraft:RightClickOrder(event)

    if not burrow.peons_inside then
        burrow.peons_inside = {}
    end

    local peons_inside = #burrow.peons_inside

    if peons_inside < 4 then
        local ability = burrow:FindAbilityByName("orc_burrow_peon")
        local selectedEntities = GetSelectedEntities(pID)

        -- Send the main unit
        ExecuteOrderFromTable({ UnitIndex = burrowIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = entityIndex, AbilityIndex = ability:GetEntityIndex(), Queue = false})
        
        -- Send the others
        local maxPeons = 4 - peons_inside
        for _,entityIndex in pairs(selectedEntities) do
            local unit = EntIndexToHScript(entityIndex)
            if unit:GetUnitName() == "orc_peon" then
                if maxPeons > 0 then
                    maxPeons = maxPeons - 1
                    ExecuteOrderFromTable({ UnitIndex = burrowIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = entityIndex, AbilityIndex = ability:GetEntityIndex(), Queue = false})
                else
                    break
                end
            end
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
    local queue = tobool(event.queue)
    dotacraft:RightClickOrder(event)

    local unit = EntIndexToHScript(entityIndex)
    local race = GetUnitRace(unit)
    local repair_ability = unit:FindAbilityByName(race.."_gather")

    -- Repair
    if repair_ability and repair_ability:IsFullyCastable() and not repair_ability:IsHidden() then
        --print("Order: Repair ",building:GetUnitName())
        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = repair_ability:GetEntityIndex(), Queue = queue})
    elseif repair_ability and repair_ability:IsFullyCastable() and repair_ability:IsHidden() then
        --print("Order: Repair ",building:GetUnitName())
        
        -- Swap to the repair ability and send repair order
        unit:SwapAbilities(race.."_gather", race.."_return_resources", true, false)
        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = repair_ability:GetEntityIndex(), Queue = queue})
    end
end

------------------------------------------------
--            Shop->Unit Right-Click          --
--            Unit->Shop Left-Click           --
------------------------------------------------
function dotacraft:ShopActiveOrder( event )
    local pID = event.PlayerID
    local shop = EntIndexToHScript(event.shop)
    local unit = EntIndexToHScript(event.unit)
    local player = PlayerResource:GetPlayer(pID)

    -- Send true in panorama order, false if autoassigned
    shop.targeted = event.targeted or false

    -- Set the current unit of this shop for this player
    shop.current_unit[pID] = unit
    
    if shop.active_particle[pID] then
        ParticleManager:DestroyParticle(shop.active_particle[pID], true)
    end
    shop.active_particle[pID] = ParticleManager:CreateParticleForPlayer("particles/custom/shop_arrow.vpcf", PATTACH_OVERHEAD_FOLLOW, unit, player)

    ParticleManager:SetParticleControl(shop.active_particle[pID], 0, unit:GetAbsOrigin())
end

------------------------------------------------
--             Generic Right-Click            --
------------------------------------------------ 
function dotacraft:RightClickOrder( event )
    local pID = event.pID
    local selectedEntities = GetSelectedEntities(pID)

    for _,entityIndex in pairs(selectedEntities) do
        local unit = EntIndexToHScript(entityIndex)
        if IsValidAlive(unit) and unit:HasModifier("modifier_hold_position") then
            unit:RemoveModifierByName("modifier_hold_position")
        end
    end
end

------------------------------------------------
--          Rally Point Right-Click           --
------------------------------------------------
function dotacraft:OnBuildingRallyOrder( event )

    -- Arguments
    local pID = event.pID
    local mainSelected = event.mainSelected
    local rally_type = event.rally_type
    local targetIndex = event.targetIndex -- Only on "mine" or "target" rally type
    local position = event.position -- Only on "position" rally type
    if position then
        position = Vector(position["0"], position["1"], position["2"])
    else
        position = Vector(event.pos_x, event.pos_y, event.pos_z)
    end

    local player = PlayerResource:GetPlayer(pID)
    local units = GetSelectedEntities(pID)

    Players:ClearPlayerFlags(pID)

    for k,v in pairs(units) do
        local building = EntIndexToHScript(v)
        if IsValidAlive(building) and IsCustomBuilding(building) then

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
                            building.flag_type = "tree"

                            -- Custom origin particle on top of the tree
                            CreateRallyFlagForBuilding( building )
                        end
                    else
                        building.flag = position
                        building.flag_type = "position"
                        CreateRallyFlagForBuilding( building )

                        -- Extra X
                        local teamNumber = building:GetTeamNumber()
                        local color = TEAM_COLORS[teamNumber]
                        local Xparticle = ParticleManager:CreateParticleForTeam("particles/custom/x_marker.vpcf", PATTACH_CUSTOMORIGIN, building, teamNumber)
                        ParticleManager:SetParticleControl(Xparticle, 0, position)
                        ParticleManager:SetParticleControl(Xparticle, 15, Vector(color[1], color[2], color[3])) --Color   
                    end

                elseif rally_type == "target" or rally_type == "mine" then

                    -- Attach the flag to the target
                    local target = EntIndexToHScript(targetIndex)
                    building.flag = target
                    building.flag_type = rally_type
                   
                    CreateRallyFlagForBuilding( building )
                end
            end
        end
    end
end


function CreateRallyFlagForBuilding( building )
    local flag_type = building.flag_type
    local teamNumber = building:GetTeamNumber()
    local color = TEAM_COLORS[teamNumber]
    local particleName = "particles/custom/rally_flag.vpcf"
    local origin = building:GetAbsOrigin()
    local particle
    local position
    local orientation

    if flag_type == "tree" then
        local tree_pos = building.flag:GetAbsOrigin()
        particle = ParticleManager:CreateParticleForTeam(particleName, PATTACH_CUSTOMORIGIN, building, teamNumber)
        position = Vector(tree_pos.x, tree_pos.y, tree_pos.z+250)
        orientation = position

    elseif flag_type == "position" then
        particle = ParticleManager:CreateParticleForTeam(particleName, PATTACH_CUSTOMORIGIN, building, teamNumber)
        position = building.flag
        orientation = origin

    elseif flag_type == "target" or flag_type == "mine" then
        local target = building.flag
        if target and IsValidEntity(target) then
            position = target:GetAbsOrigin()
                        
            if flag_type == "mine" then
                particle = ParticleManager:CreateParticleForTeam(particleName, PATTACH_CUSTOMORIGIN, target, teamNumber)
                position.z = position.z + 350
            else
                particle = ParticleManager:CreateParticleForTeam(particleName, PATTACH_OVERHEAD_FOLLOW, target, teamNumber)
            end

            orientation = target:GetAbsOrigin() * target:GetForwardVector()
        end
    else
        return
    end

    ParticleManager:SetParticleControl(particle, 0, position) -- Position
    ParticleManager:SetParticleControl(particle, 1, orientation) --Orientation
    ParticleManager:SetParticleControl(particle, 15, Vector(color[1], color[2], color[3])) --Color

    local line = ParticleManager:CreateParticleForTeam("particles/custom/range_finder_line.vpcf", PATTACH_CUSTOMORIGIN, building, teamNumber)
    local spawn_pos = building.initial_spawn_position or building:GetAbsOrigin()
    spawn_pos = (spawn_pos + (origin-spawn_pos)/10)
    ParticleManager:SetParticleControl(line, 0, spawn_pos)
    ParticleManager:SetParticleControl(line, 1, spawn_pos)
    ParticleManager:SetParticleControl(line, 2, position)
    ParticleManager:SetParticleControl(line, 15, Vector(color[1], color[2], color[3])) --Color

    -- Stores the particle to remove it when the selection changes
    local flags = Players:GetPlayerFlags(building:GetPlayerOwnerID())
    local buildingIndex = building:GetEntityIndex()
    flags[buildingIndex] = flags[buildingIndex] or {}
    flags[buildingIndex].flagParticle = particle
    flags[buildingIndex].lineParticle = line
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
    return GameRules.UnitKV[unit:GetUnitName()]["FormationRank"] or 0
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


ORDERS = {
    [0] = "DOTA_UNIT_ORDER_NONE",
    [1] = "DOTA_UNIT_ORDER_MOVE_TO_POSITION",
    [2] = "DOTA_UNIT_ORDER_MOVE_TO_TARGET",
    [3] = "DOTA_UNIT_ORDER_ATTACK_MOVE",
    [4] = "DOTA_UNIT_ORDER_ATTACK_TARGET",
    [5] = "DOTA_UNIT_ORDER_CAST_POSITION",
    [6] = "DOTA_UNIT_ORDER_CAST_TARGET",
    [7] = "DOTA_UNIT_ORDER_CAST_TARGET_TREE",
    [8] = "DOTA_UNIT_ORDER_CAST_NO_TARGET",
    [9] = "DOTA_UNIT_ORDER_CAST_TOGGLE",
    [10] = "DOTA_UNIT_ORDER_HOLD_POSITION",
    [11] = "DOTA_UNIT_ORDER_TRAIN_ABILITY",
    [12] = "DOTA_UNIT_ORDER_DROP_ITEM",
    [13] = "DOTA_UNIT_ORDER_GIVE_ITEM",
    [14] = "DOTA_UNIT_ORDER_PICKUP_ITEM",
    [15] = "DOTA_UNIT_ORDER_PICKUP_RUNE",
    [16] = "DOTA_UNIT_ORDER_PURCHASE_ITEM",
    [17] = "DOTA_UNIT_ORDER_SELL_ITEM",
    [18] = "DOTA_UNIT_ORDER_DISASSEMBLE_ITEM",
    [19] = "DOTA_UNIT_ORDER_MOVE_ITEM",
    [20] = "DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO",
    [21] = "DOTA_UNIT_ORDER_STOP",
    [22] = "DOTA_UNIT_ORDER_TAUNT",
    [23] = "DOTA_UNIT_ORDER_BUYBACK",
    [24] = "DOTA_UNIT_ORDER_GLYPH",
    [25] = "DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH",
    [26] = "DOTA_UNIT_ORDER_CAST_RUNE",
    [27] = "DOTA_UNIT_ORDER_PING_ABILITY",
    [28] = "DOTA_UNIT_ORDER_MOVE_TO_DIRECTION",
    [29] = "DOTA_UNIT_ORDER_PATROL",
}