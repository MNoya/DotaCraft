SQUARE_FACTOR = 1.3 --1 is a perfect square, higher numbers will increase the units per row
UNIT_FORMATION_DISTANCE = 130
DEBUG = false

function dotacraft:FilterExecuteOrder( filterTable )
    --[[
    print("-----------------------------------------")
    for k, v in pairs( filterTable ) do
        print("Order: " .. k .. " " .. tostring(v) )
    end
    ]]

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

    -- Don't need this.
    if order_type == DOTA_UNIT_ORDER_RADAR then return end

    -- Remove moving timers
    ForAllSelectedUnits(issuer, function(v)
        if v.moving_timer then
            Timers:RemoveTimer(v.moving_timer)
            v.moving_timer = nil
        end
    end)

    ------------------------------------------------
    --           Ability Multi Order              --
    ------------------------------------------------
    if abilityIndex and abilityIndex ~= 0 and IsMultiOrderAbility(EntIndexToHScript(abilityIndex)) then
        --print("Multi Order Ability")

        local ability = EntIndexToHScript(abilityIndex) 
        local abilityName = ability:GetAbilityName()
        local entityList = PlayerResource:GetSelectedEntities(issuer)
        if not entityList or #entityList == 1 then return true end

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
            unit:MoveToNPCToGiveItem(target,item)
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
    --            Item Pickup Orders              --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_PICKUP_ITEM then
        local drop = EntIndexToHScript(targetIndex)
        local item = drop:GetContainedItem()
        local item_name = item:GetAbilityName()
        
        -- Units can't activate powerups, redirect order to hero if there is one or deny it
        local bPowerUp = item:IsCastOnPickup()
        local bHeroPickup = unit:IsRealHero()
        local bValidPickup = not bPowerUp or bHeroPickup

        if bValidPickup then
            return true
        else
            -- Does the selected group have a hero?
            local selectedUnits = PlayerResource:GetSelectedEntities(issuer)
            local heroes = {}
            for _,ent_index in pairs(selectedUnits) do
                local u = EntIndexToHScript(ent_index)
                if u:IsRealHero() then
                    table.insert(heroes, u)
                end
            end

             -- Try to redirect to the first possible hero
            if #heroes > 0 then
                for _,hero in pairs(heroes) do
                    if bPowerUp or hero:GetNumItemsInInventory() < 6 then
                        -- Recreate the order
                        hero.skip = true
                        ExecuteOrderFromTable({UnitIndex = hero:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_PICKUP_ITEM, TargetIndex = targetIndex, Queue = queue})
                        return false
                    end
                end
            else
                SendErrorMessage(unit:GetPlayerOwnerID(), "#error_unable_to_use_powerups")
            end

            return false
        end
        

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
    end

    ------------------------------------------------
    --              Rally Flag Order              --
    ------------------------------------------------
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

        local point = Vector(x,y,z) -- initial goal
        MoveUnitsInGrid(units, point, order_type, queue)
        
        return false
    end

    return true
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

    if not burrow.peons_inside then
        burrow.peons_inside = {}
    end

    local peons_inside = #burrow.peons_inside

    if peons_inside < 4 then
        local ability = burrow:FindAbilityByName("orc_burrow_peon")
        local selectedEntities = PlayerResource:GetSelectedEntities(pID)

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
    local units = PlayerResource:GetSelectedEntities(pID)

    Players:ClearPlayerFlags(pID)

    for k,v in pairs(units) do
        local building = EntIndexToHScript(v)
        if IsValidAlive(building) and IsCustomBuilding(building) then

            if HasTrainAbility(building) and not IsCustomTower(building) then
                EmitSoundOnClient("DOTA_Item.ObserverWard.Activate", player)
                if rally_type == "position" then
                    --DebugDrawCircle(position, Vector(255,0,0), 255, 20, true, 3)
                   
                   -- TODO: Use API
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

function dotacraft:ResolveRallyPointOrder( unit, building )
    local entityIndex = unit:GetEntityIndex()
    local flag = building.flag
    local rally_type = building.flag_type

    Timers:CreateTimer(0.05, function()

        -- Move to Position
        if rally_type == "position" then

            -- Reposition units nearby the rally flag, including the newly created unit
            RepositionAroundRallyPoint(unit, building, flag)
    
        -- Move to follow NPC
        elseif rally_type == "target" then
            unit:MoveToNPC(flag)        

        -- Move to Gather Tree
        elseif rally_type == "tree" then
            if unit:IsGatherer() then
                unit:GatherFromNearestTree(flag:GetAbsOrigin())
            else
                -- Move
                unit:MoveToPosition(flag:GetAbsOrigin())
            end

        -- Move to Gather Gold
        elseif rally_type == "mine" then
            if unit:IsGatherer() then
                unit:GatherFromNearestGoldMine(flag)
            else
                -- Move
                unit:MoveToPosition(flag:GetAbsOrigin())
            end
        end
    end)    
end

-- Pick which units we want to move
function RepositionAroundRallyPoint(unit, building, point)
    local playerID = unit:GetPlayerOwnerID()
    local origin = building:GetAbsOrigin()
    local radius = UNIT_FORMATION_DISTANCE*1.2
    local units = {}

    local allies = FindAlliesInRadius(unit, radius, point)
    if allies[1] then
        local grouped_allies = GetUnitGroupWithin(allies[1], radius)      
        for _,v in pairs(grouped_allies) do
            if v:GetPlayerOwnerID() == playerID and v:IsIdle() and not IsCustomBuilding(v) then
                units[#units+1] = v:GetEntityIndex()
            end
        end
    end
    units[#units+1] = unit:GetEntityIndex()

    local count = #units
    if count > 0 then
        if count == 1 then
            unit:MoveToPosition(point)
        else
            MoveUnitsInGrid(units, point, DOTA_UNIT_ORDER_MOVE_TO_POSITION, false, (point-origin):Normalized())
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

function MoveUnitsInGrid(units, point, order_type, queue, forward)
    local navPoints = {}
    local first_unit = EntIndexToHScript(units[1])
    local origin = first_unit:GetAbsOrigin()

    if DEBUG then DebugDrawCircle(point, Vector(255,0,0), 100, 18, true, 3) end

    local numUnits = #units
    local unitsPerRow = math.floor(math.sqrt(numUnits/SQUARE_FACTOR))
    local unitsPerColumn = math.floor((numUnits / unitsPerRow))
    local remainder = numUnits - (unitsPerRow*unitsPerColumn) 
    --print(numUnits.." units = "..unitsPerRow.." rows of "..unitsPerColumn.." with a remainder of "..remainder)

    local start = (unitsPerColumn-1)* -.5

    local curX = start
    local curY = 0

    local offsetX = UNIT_FORMATION_DISTANCE
    local offsetY = UNIT_FORMATION_DISTANCE
    local forward = forward or (point-origin):Normalized()
    if forward.x == 0 then forward.x = 0.5 end
    if forward.y == 0 then forward.y = 0.5 end
    local right = RotatePosition(Vector(0,0,0), QAngle(0,90,0), forward)

    for i=1,unitsPerRow do
      for j=1,unitsPerColumn do
        local newPoint = point + (curX * offsetX * right) + (curY * offsetY * forward)
        --print ('grid point (' .. curX .. ', ' .. curY .. '): '..VectorString(newPoint))
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
            table.remove(units, getIndexTable(units, closest_unit_index))
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
                
                ExecuteOrderFromTable({UnitIndex = unit_index, OrderType = order_type, Position = pos, Queue = queue})
            end
        end
    end
end

-- Returns units within a certain radius of each other
function GetUnitGroupWithin(startingUnit, radius)
    local group = {}
    RecursiveFind(startingUnit, radius, group)
        
    return group
end

function RecursiveFind(unit, radius, group)
    local units = FindUnitsInRadius(unit:GetTeamNumber(), unit:GetAbsOrigin(), unit, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES, FIND_ANY_ORDER, true)

    if units then
        -- Add to group
        for k,v in pairs(units) do
            local index = v:GetEntityIndex()
            if not group[index] then
                group[index] = v
                RecursiveFind(v, radius, group)
            end
        end
    else
        return group
    end
end


------------------------------------------------
--              Utility functions             --
------------------------------------------------

-- Returns the closest unit to a point from a table of unit indexes
function GetClosestUnitToPoint( units_table, point )
    local closest_unit = units_table[1]
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
        if EntIndexToHScript(unit_index):GetFormationRank() == rank then
            table.insert(allUnitsOfRank, unit_index)
        end
    end
    if #allUnitsOfRank == 0 then
        return nil
    end
    return allUnitsOfRank
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
    [30] = "DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION",
    [31] = "DOTA_UNIT_ORDER_RADAR",
    [32] = "DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK",
    [33] = "DOTA_UNIT_ORDER_CONTINUE",
}