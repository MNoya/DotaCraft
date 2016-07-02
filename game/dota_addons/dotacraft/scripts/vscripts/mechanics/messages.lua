function SendErrorMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
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