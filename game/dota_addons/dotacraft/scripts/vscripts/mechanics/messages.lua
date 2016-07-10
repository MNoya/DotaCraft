function SendErrorMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end

--[[
Author: Steve Yoo(Dun1007)
Date: 7/10/2016

Similar to SendErrorMessage to the bottom, except it checks whether the source of error is currently selected unit/hero.
]]
function SendErrorMessageForSelectedUnit( pID, string, unit )
    --Notifications:ClearBottom(pID)
    --Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
    --EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(pID), "bottom_notification_portrait_unit", {text=string, duration=2, class=nil, style={color='#E62020'}, continue=nil, unit=unit:entindex()} )
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