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
        print("Currently Selected Units:")
        local entityList = GetSelectedEntities(unit:GetPlayerOwnerID())
        DeepPrintTable(entityList)
        if not entityList then
            return true
        end

        local nearby_trees = GridNav:GetAllTreesAroundPoint(position, 150, true)
        if DEBUG then DebugDrawCircle(position, Vector(0,0,255), 100, 150, true, 5) end
        print(#nearby_trees,"trees nearby")

        for k,entityIndex in pairs(entityList) do
            print("GatherTreeOrder for unit index ",entityIndex, position)

            --Execute the order to this tree or some other, do some logic here to distribute them smartly
            local some_tree = nearby_trees[RandomInt(1, #nearby_trees)]
            DebugDrawCircle(some_tree:GetAbsOrigin(), Vector(0,0,255), 255, 20, true, 5)
            
            local unit = EntIndexToHScript(entityIndex)
            unit.skip_gather_check = true
            local gather_ability = unit:FindAbilityByName("human_gather")
            local return_ability = unit:FindAbilityByName("human_return_resources")
            if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                local tree_index = GetTreeIndexFromHandle( some_tree )
                print("Order: Cast on Tree ",tree_index)
                ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
            elseif return_ability then
                print("Order: Return resources")
                ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = false})
            end
        end

        -- Drop the original order
        return false


    elseif units and (order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION or order_type == DOTA_UNIT_ORDER_ATTACK_MOVE) and numUnits > 1 then

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

        ------------------------------------------------
        --           Grid Unit Formation              --
        ------------------------------------------------
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

        -- Sort the units by rank (0,1,2,3)
        unitsByRank = {}
        for i=0,3 do
            local units = GetUnitsWithFormationRank(sortedUnits, i)
            if units then
                unitsByRank[i] = units
            end
        end

        -- Order each unit sorted to move to its respective Nav Point
        local n = 0
        for i=0,3 do
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
    --          Rally Point Right-Click           --
    ------------------------------------------------
    elseif units and order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION and numBuildings > 0 then
        local first_unit = EntIndexToHScript(units["0"])
        if IsCustomBuilding(first_unit) and not IsCustomTower(first_unit) then
            local x = tonumber(filterTable["position_x"])
            local y = tonumber(filterTable["position_y"])
            local z = tonumber(filterTable["position_z"])
            local point = Vector(x,y,z)
            if DEBUG then DebugDrawCircle(point, Vector(255,0,0), 255, 20, true, 3) end

            -- If there's an old flag, remove it
            if first_unit.flag and IsValidEntity(first_unit.flag) then
                first_unit.flag:RemoveSelf()
            end

            -- Make a flag dummy
            first_unit.flag = CreateUnitByName("dummy_unit", point, false, first_unit, first_unit, first_unit:GetTeamNumber())

            local color = TEAM_COLORS[first_unit:GetTeamNumber()]
            local particle = ParticleManager:CreateParticleForTeam("particles/custom/rally_flag.vpcf", PATTACH_ABSORIGIN_FOLLOW, first_unit.flag, first_unit:GetTeamNumber())
            ParticleManager:SetParticleControl(particle, 0, point) -- Position
            ParticleManager:SetParticleControl(particle, 1, first_unit:GetAbsOrigin()) --Orientation
            ParticleManager:SetParticleControl(particle, 15, Vector(color[1], color[2], color[3])) --Color
        elseif IsCustomTower(first_unit) then
            ExecuteOrderFromTable({ UnitIndex = units["0"], OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE, Position = pos, Queue = false})
            return false
        end
    end

    return true
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