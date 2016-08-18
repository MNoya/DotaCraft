function SendErrorMessage(playerID, string)
   CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "dotacraft_error_message", {message=string}) 
end

-- Similar to SendErrorMessage to the bottom, except it checks whether the source of error is currently selected unit/hero.
function SendErrorMessageForSelectedUnit(playerID, string, unit)
    local selected = PlayerResource:GetSelectedEntities(playerID)
    if selected and selected["0"] == unit:GetEntityIndex() then
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "dotacraft_error_message", {message=string})
    end
end

function dotacraft:PrintDefeateMessageForTeam( teamID )
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            local player = PlayerResource:GetPlayer(playerID)
            if player:GetTeamNumber() == teamID then
                local playerName = Players:GetPlayerName(playerID)
                GameRules:SendCustomMessage(playerName.." was defeated", 0, 0)
            end
        end
    end
end

function dotacraft:PrintWinMessageForTeam( teamID )
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            local player = PlayerResource:GetPlayer(playerID)
            if player:GetTeamNumber() == teamID then
                local playerName = PlayerResource:GetPlayerName(playerID)
                if playerName == "" then playerName = "Player "..playerID end
                GameRules:SendCustomMessage(playerName.." was victorious", 0, 0)
            end
        end
    end
end