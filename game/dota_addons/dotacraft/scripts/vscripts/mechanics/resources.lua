-- Modifies the lumber of this player. Accepts negative values
function ModifyLumber( player, lumber_value )
    if lumber_value == 0 then return end
    if lumber_value > 0 then
        player.lumber = player.lumber + lumber_value
        CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = math.floor(player.lumber) })
    else
        if PlayerHasEnoughLumber( player, math.abs(lumber_value) ) then
            player.lumber = player.lumber + lumber_value
            CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = math.floor(player.lumber) })
        end
    end
end

-- Modifies the food limit of this player. Accepts negative values
function ModifyFoodLimit( player, food_limit_value )
    player.food_limit = player.food_limit + food_limit_value
    if player.food_limit > 100 and not GameRules.PointBreak then
        player.food_limit = 100
    end
    CustomGameEventManager:Send_ServerToPlayer(player, 'player_food_changed', { food_used = player.food_used, food_limit = player.food_limit }) 
end

-- Modifies the food used of this player. Accepts negative values
-- Can go over the limit if a build is destroyed while the unit is already spawned/training
function ModifyFoodUsed( player, food_used_value )
    player.food_used = player.food_used + food_used_value
    CustomGameEventManager:Send_ServerToPlayer(player, 'player_food_changed', { food_used = player.food_used, food_limit = player.food_limit })
end

function GetClosestEntityToPosition(list, position)
    local distance = 20000
    local closest = nil

    for k,ent in pairs(list) do
        local this_distance = (position - ent:GetAbsOrigin()):Length()
        if this_distance < distance then
            distance = this_distance
            closest = k
        end
    end

    return closest  
end

function GetClosestGoldMineToPosition( position )
    local allGoldMines = Entities:FindAllByModel('models/mine/mine.vmdl') --Target name in Hammer
    local distance = 20000
    local closest_mine = nil
    for k,gold_mine in pairs (allGoldMines) do
        local mine_location = gold_mine:GetAbsOrigin()
        local this_distance = (position - mine_location):Length()
        if this_distance < distance then
            distance = this_distance
            closest_mine = gold_mine
        end
    end
    return closest_mine
end

function IsMineOccupiedByTeam( mine, teamID )
    return (IsValidEntity(mine.building_on_top) and mine.building_on_top:GetTeamNumber() == teamID)
end

-- Goes through the structures of the player finding the closest valid resource deposit of this type
function FindClosestResourceDeposit( caster, resource_type )
    local position = caster:GetAbsOrigin()
    
    -- Find a building to deliver
    local player = caster:GetPlayerOwner()
    local race = GetPlayerRace(player)
    if not player then print("ERROR, NO PLAYER") return end
    local buildings = player.structures
    local distance = 20000
    local closest_building = nil

    if resource_type == "gold" then
        for _,building in pairs(buildings) do
            if building and IsValidEntity(building) and building:IsAlive() then
                if IsValidGoldDepositName( building:GetUnitName(), race ) and building.state == "complete" then
                    local this_distance = (position - building:GetAbsOrigin()):Length()
                    if this_distance < distance then
                        distance = this_distance
                        closest_building = building
                    end
                end
            end
        end

    elseif resource_type == "lumber" then
        for _,building in pairs(buildings) do
            if building and IsValidEntity(building) and building:IsAlive() then
                if IsValidLumberDepositName( building:GetUnitName(), race ) and building.state == "complete" then
                    local this_distance = (position - building:GetAbsOrigin()):Length()
                    if this_distance < distance then
                        distance = this_distance
                        closest_building = building
                    end
                end
            end
        end
    end
    if not closest_building then
        print("[ERROR] CANT FIND A DEPOSIT RESOURCE FOR "..resource_type.."! This shouldn't happen")
    end
    return closest_building     

end

function IsValidGoldDepositName( building_name, race )
    local GOLD_DEPOSITS = GameRules.Buildings[race]["gold"]
    for name,_ in pairs(GOLD_DEPOSITS) do
        if GOLD_DEPOSITS[building_name] then
            return true
        end
    end

    return false
end

function IsValidLumberDepositName( building_name, race )
    local LUMBER_DEPOSITS = GameRules.Buildings[race]["lumber"]
    for name,_ in pairs(LUMBER_DEPOSITS) do
        if LUMBER_DEPOSITS[building_name] then
            return true
        end
    end

    return false
end