if not Teams then
    Teams = class({})
end

function Teams:DetermineStartingPositions()
    self.unassignedPositions = {}

    local targets = ShuffledList(Entities:FindAllByName( "*starting_position" )) --Inside player_start.vmap prefab
    for k,v in pairs(targets) do
        table.insert(self.unassignedPositions, v:GetAbsOrigin())
    end

    self.positions = {}

    -- If its not an FFA match, use the Teams Together logic
    local teamsTogether = not self:IsFFAMatch()
    local totalAssigned = 0
    if teamsTogether then
        local teams = self:GetValidTeams()
        for _,teamID in pairs(teams) do
            local assigned = 0
            local players = self:GetPlayersOnTeam(teamID)
            self:print("Assigning positions to players in team",teamID)
            for _,playerID in pairs(players) do
                -- Choose the first position at random
                if totalAssigned == 0 then
                    local index = RandomInt(1,#self.unassignedPositions)
                    local pos = self.unassignedPositions[index]
                    self.positions[teamID] = {}
                    self.positions[teamID][playerID] = pos
                    table.remove(self.unassignedPositions, index)
                    self:print("Assigning",playerID,"to pos",VectorString(pos))

                -- Choose an opposite team position at random, far away from any team
                elseif assigned == 0 then
                    local pos,index = self:FindEnemyPosition(teamID)
                    if pos then
                        self.positions[teamID] = {}
                        self.positions[teamID][playerID] = pos
                        table.remove(self.unassignedPositions, index)
                        self:print("Assigning",playerID,"to pos",VectorString(pos))
                    else
                        self:print("Error, couldn't assign pos to",playerID,"in team",teamID)
                    end

                -- Choose an allied position, closest to any ally
                else
                    local pos,index = self:FindAlliedPosition(teamID)
                    if pos then
                        self.positions[teamID][playerID] = pos
                        table.remove(self.unassignedPositions, index)
                        self:print("Assigning",playerID,"to pos",VectorString(pos))
                    else
                        self:print("Error, couldn't assign pos to",playerID,"in team",teamID)
                    end
                end

                assigned = assigned + 1
                totalAssigned = totalAssigned + 1
            end
        end       
    else
        for k,v in pairs(self.unassignedPositions) do
            self.positions[k-1] = v
        end
        self.unassignedPositions = {}
    end
end

-- There are enemies out there and we want a safe position for a new team
function Teams:FindEnemyPosition(teamID)
    local furthest
    local index
    local maxDistance = 0
    for i,freePos in pairs(self.unassignedPositions) do
        for enemyTeamID,enemyPositions in pairs(self.positions) do
            for _,enemyPos in pairs(enemyPositions) do
                local thisDistance = (freePos - enemyPos):Length2D()
                if thisDistance > maxDistance then
                    maxDistance = thisDistance
                    furthest = freePos
                    index = i
                end
            end
        end
    end
    return furthest,index
end

-- The team has already assigned a position on the map, we need the closest to any of them
function Teams:FindAlliedPosition(teamID)
    local closest
    local index
    local minDistance = math.huge
    for i,freePos in pairs(self.unassignedPositions) do
        for _,alliedPos in pairs(self.positions[teamID]) do
            local thisDistance = (freePos - alliedPos):Length2D()
            if thisDistance < minDistance then
                minDistance = thisDistance
                closest = freePos
                index = i
            end
        end
    end
    return closest,index
end

-- Gets a list of playerIDs on a team
function Teams:GetPlayersOnTeam(teamID)
    local players = {}
    local maxPlayers = dotacraft:GetMapMaxPlayers()
    for playerID = 0, maxPlayers do
        local playerTable = CustomNetTables:GetTableValue("dotacraft_pregame_table", tostring(playerID))
        if playerTable and playerTable.PlayerIndex ~= 9000 and playerTable.Team == teamID then -- Infekma please
            if playerTable.PlayerIndex == 9001 then -- ugh
                table.insert(players, playerID)
            else
                table.insert(players, playerTable.PlayerIndex)
            end
        end
    end
    return players
end

-- Position assigned by DetermineStartingPositions
function Teams:GetPositionForPlayer(playerID)
    if Teams:IsFFAMatch() then
        return self.positions[playerID]
    else
        local teamID = Teams:GetPlayerTeam(playerID)
        return self.positions[teamID][playerID]
    end
end

-- Returns true if everyone is on their own team, false if there is one team with more than one player in it
function Teams:IsFFAMatch()
    local teams = self:GetValidTeams()
    for _,teamID in pairs(teams) do
        if #self:GetPlayersOnTeam(teamID) > 1 then
            return false
        end
    end
    return true -- Every team has exactly 1 player
end

-- Returns the team of the player before it has been actually assigned to it
function Teams:GetPlayerTeam(playerID)
    local playerTable = CustomNetTables:GetTableValue("dotacraft_pregame_table", tostring(playerID))
    return playerTable.Team
end

-- Returns a list of teamIDs which have at least one players on them
function Teams:GetValidTeams()
    local teams = {}
    local maxPlayers = dotacraft:GetMapMaxPlayers()
    local teamTable = {}
    for playerID = 0, maxPlayers-1 do
        local playerTable = CustomNetTables:GetTableValue("dotacraft_pregame_table", tostring(playerID))
        if playerTable and playerTable.PlayerIndex ~= 9000 then -- Infekma please
            teamTable[playerTable.Team] = true
        end
    end
    for teamID,_ in pairs(teamTable) do
        table.insert(teams, teamID)
    end
    return teams
end

function table.pack(...)
    return { n = select("#", ...); ... }
end

function Teams:print( ... )
    local string = ""
    local args = table.pack(...)
    for i = 1, args.n do
        string = string .. tostring(args[i]) .. " "
    end
    print("[Teams] " .. string)
end