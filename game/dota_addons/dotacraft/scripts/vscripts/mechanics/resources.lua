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
    local playerID = caster:GetPlayerOwnerID()
    local race = Players:GetRace(playerID)

    local buildings = Players:GetStructures(playerID)
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