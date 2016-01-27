function dotacraft:OnPreGame()
	print("[DOTACRAFT] OnPreGame")
	local Finished = false
	local currentIndex = 0
	while not Finished do
		
		local Player_Table = GetNetTableValue("dotacraft_pregame_table", tostring(currentIndex))
		local NextTable = GetNetTableValue("dotacraft_pregame_table", tostring(currentIndex+1))
		if not NextTable then
			Finished = true
		end
		local playerID = Player_Table.PlayerIndex
		local color = Player_Table.Color
		local team = Player_Table.Team
		local race = GameRules.raceTable[Player_Table.Race]
		
		-- if race is nil it means that the id supplied is random since that is the only fallout index
		if race == nil then
			race = GameRules.raceTable[RandomInt(1, 4)]
		end
		
		if PlayerResource:IsValidPlayerID(playerID) then
			-- player stuff
			local PlayerColor = GetNetTableValue("dotacraft_color_table", tostring(color))
			PlayerResource:SetCustomPlayerColor(playerID, PlayerColor.r, PlayerColor.g, PlayerColor.b)
			PlayerResource:SetCustomTeamAssignment(playerID, team)
			--PrecacheUnitByNameAsync(race, function() --Race Heroes are already precached
				local player = PlayerResource:GetPlayer(playerID)
				local hero = CreateHeroForPlayer(race, player)
				
				hero.color_id = color
				
				print("[DOTACRAFT] CreateHeroForPlayer: ",playerID,race,team)
 		elseif playerID > 9000 then
			-- Create ai player here
		else
			-- do nothing
		end
		
		currentIndex = currentIndex + 1
 	end
	
	--[[
	for playerID=0,DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayerID(playerID) && PlayerResource:GetTeam(playerID) == 1 then
			-- spectator
		end
	end
	--]]
	
 	-- Add gridnav blockers to the gold mines
	GameRules.GoldMines = Entities:FindAllByModel('models/mine/mine.vmdl')
	for k,gold_mine in pairs (GameRules.GoldMines) do
		local location = gold_mine:GetAbsOrigin()
		local construction_size = BuildingHelper:GetConstructionSize(gold_mine)
		local pathing_size = BuildingHelper:GetBlockPathingSize(gold_mine)
		BuildingHelper:SnapToGrid(construction_size, location)

		local gridNavBlockers = BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)
        BuildingHelper:AddGridType(construction_size, location, "GoldMine")
		gold_mine:SetAbsOrigin(location)
	    gold_mine.blockers = gridNavBlockers

	    -- Find and store the mine entrance
		local mine_entrance = Entities:FindAllByNameWithin("*mine_entrance", location, 300)
		for k,v in pairs(mine_entrance) do
			gold_mine.entrance = v:GetAbsOrigin()
		end

		-- Find and store the mine light
	end
end

function dotacraft:PreGameUpdate(data)
	SetNetTableValue("dotacraft_pregame_table", tostring(data.PanelID), {Team = data.Team, Color = data.Color, Race = data.Race, PlayerIndex = data.PlayerIndex})
end

function dotacraft:PreGameToggleLock(data)
	CustomGameEventManager:Send_ServerToAllClients("pregame_toggle_lock", {})
end

function dotacraft:PreGameStartCountDown(data)
	CustomGameEventManager:Send_ServerToAllClients("pregame_countdown_start", {})
end
