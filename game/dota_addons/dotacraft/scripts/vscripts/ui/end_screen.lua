function dotacraft:EndScreenRequestData()
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayerID(playerID) then
			local player = PlayerResource:GetPlayer(playerID)
			local info_table = Players:GetPlayerScores( playerID )
			
			CustomGameEventManager:Send_ServerToAllClients("endscreen_data", {key=playerID, table=info_table})
		end
	end
end