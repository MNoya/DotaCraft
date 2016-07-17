if not UI then
	UI = class({})
end

local ROUND_TIME = 120
function UI:Init()
	GameRules.UI_COLORTABLE = "dotacraft_color_table"
	GameRules.UI_PLAYERTABLE = "dotacraft_player_table"
	GameRules.UI_PREGAMETABLE = "dotacraft_pregame_table_table"
	
	-- setup color table
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "0", {r=255, g=3,   b=3	})	-- red
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "1", {r=0, 	g=66,  b=255})	-- blue
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "2", {r=28, 	g=230, b=185})	-- teal
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "3", {r=84, 	g=0,   b=129})	-- purple
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "4", {r=255, g=255, b=1	})	-- yellow
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "5", {r=254, g=138, b=14	})	-- orange
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "6", {r=32, 	g=192, b=0	})	-- green
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "7",	{r=229, g=91,  b=176})	-- pink
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "8",	{r=149, g=150, b=151})	-- gray	
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "9",	{r=126, g=191, b=241})	-- light blue	
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "10", {r=16, g=98,  b=70 })	-- dark green	
	CustomNetTables:SetTableValue(GameRules.UI_COLORTABLE, "11", {r=78, g=42,  b=4  })	-- brown		
	
	-- setup race reference table
	if GameRules.raceTable == nil then
		GameRules.raceTable = {}
		
		GameRules.raceTable[1] = "npc_dota_hero_dragon_knight"
		GameRules.raceTable[2] = "npc_dota_hero_huskar"
		GameRules.raceTable[3] = "npc_dota_hero_furion"
		GameRules.raceTable[4] = "npc_dota_hero_life_stealer"
	end

	-- Endscreen Data
    CustomGameEventManager:RegisterListener( "endscreen_request_data", Dynamic_Wrap(UI, "EndScreenRequestData"))
	
	-- PreGame Selection
    CustomGameEventManager:RegisterListener( "update_pregame", Dynamic_Wrap(UI, "PreGameUpdate"))
    CustomGameEventManager:RegisterListener( "send_pregame_event", Dynamic_Wrap(UI, "PreGameEvent")) 
end

function UI:HandlePlayerReconnect(player)

end

function UI:EndScreenRequestData()
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayerID(playerID) then
			local player = PlayerResource:GetPlayer(playerID)
			local info_table = Players:GetPlayerScores( playerID )
			
			CustomGameEventManager:Send_ServerToAllClients("endscreen_data", {key=playerID, table=info_table})
		end
	end
end

function UI:GameStateManager( newState )
    if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
    elseif newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		UI:StartPreGameRoundTimer()
    elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
    elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    end
end

function UI:StartPreGameRoundTimer()
	GameRules.PreGameRoundTime = ROUND_TIME;
	Timers:CreateTimer(1, function()
	    local newState = GameRules:State_Get()
		GameRules.PreGameRoundTime = GameRules.PreGameRoundTime - 1;
		UI:SendRoundTimer()
		if GameRules.PreGameRoundTime ~= 0 and newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then return 1 else return nil end
	end)
end

function UI:SendRoundTimer()
	UI:PreGameEvent({ ["Event_Name"] = "roundtimer_update", ["Info"] = {["Time"] = GameRules.PreGameRoundTime} })
end

function UI:PreGameUpdate(data)
    CustomNetTables:SetTableValue("dotacraft_pregame_table", tostring(data.ID), data.Info)
end

function UI:PreGameEvent(data)
	CustomGameEventManager:Send_ServerToAllClients("pregame_event", data);
end

function UI:Skip_Selection()
	CustomGameEventManager:Send_ServerToAllClients("dotacraft_skip_selection", {}) 
end

if not GameRules.UI_PLAYERTABLE then UI:Init() end