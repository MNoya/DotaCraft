print("[DOTACRAFT] ui.lua")

require('ui/trading_alliances')
require('ui/pre_game')
require('ui/end_screen')
require('ui/player_actions')
require('ui/hud')
require('ui/sounds')
require('ui/messages')
require('ui/shop')

function dotacraft:UI_Init()
	GameRules.UI_COLORTABLE = "dotacraft_color_table"
	GameRules.UI_PLAYERTABLE = "dotacraft_player_table"
	GameRules.UI_PREGAMETABLE = "dotacraft_pregame_table_table"
	
	dotacraft:UI_Listeners()
	dotacraft:UI_SetupTables()
end

function dotacraft:OnPlayerSelectedEntities( event )
	local playerID = event.PlayerID

	GameRules.SELECTED_UNITS[playerID] = event.selected_entities
	dotacraft:UpdateRallyFlagDisplays(playerID)
end

-- Register Listeners
function dotacraft:UI_Listeners()
    CustomGameEventManager:RegisterListener( "reposition_player_camera", Dynamic_Wrap(dotacraft, "RepositionPlayerCamera"))
    CustomGameEventManager:RegisterListener( "update_selected_entities", Dynamic_Wrap(dotacraft, 'OnPlayerSelectedEntities'))
    CustomGameEventManager:RegisterListener( "gold_gather_order", Dynamic_Wrap(dotacraft, "GoldGatherOrder")) --Right click through panorama
    CustomGameEventManager:RegisterListener( "repair_order", Dynamic_Wrap(dotacraft, "RepairOrder")) --Right click through panorama
    CustomGameEventManager:RegisterListener( "moonwell_order", Dynamic_Wrap(dotacraft, "MoonWellOrder")) --Right click through panorama
    CustomGameEventManager:RegisterListener( "burrow_order", Dynamic_Wrap(dotacraft, "BurrowOrder")) --Right click through panorama 
    CustomGameEventManager:RegisterListener( "shop_active_order", Dynamic_Wrap(dotacraft, "ShopActiveOrder")) --Right click through panorama 
    CustomGameEventManager:RegisterListener( "right_click_order", Dynamic_Wrap(dotacraft, "RightClickOrder")) --Right click through panorama
    CustomGameEventManager:RegisterListener( "building_rally_order", Dynamic_Wrap(dotacraft, "OnBuildingRallyOrder")) --Right click through panorama
	
	-- PreGame Selection
	CustomGameEventManager:RegisterListener( "update_pregame", Dynamic_Wrap(dotacraft, "PreGameUpdate"))
	CustomGameEventManager:RegisterListener( "pregame_countdown", Dynamic_Wrap(dotacraft, "PreGameStartCountDown"))	
	CustomGameEventManager:RegisterListener( "pregame_lock", Dynamic_Wrap(dotacraft, "PreGameToggleLock"))	
	
	-- Trading Alliances
	CustomGameEventManager:RegisterListener( "trading_alliances_trade_confirm", Dynamic_Wrap(dotacraft, "TradeOffers"))	
	
	-- Endscreen Data
	CustomGameEventManager:RegisterListener( "endscreen_request_data", Dynamic_Wrap(dotacraft, "EndScreenRequestData"))	
end

--[[ UI-BASED CONSOLE COMMANDS --]]
function dotacraft:Skip_Selection()
	CustomGameEventManager:Send_ServerToAllClients("dotacraft_skip_selection", {}) 
end

--[[ SETUP TABLES --]]
function dotacraft:UI_SetupTables()
	-- setup color table
	dotacraft:SetupColorTable()
	
	-- setup race reference table
	if GameRules.raceTable == nil then
		GameRules.raceTable = {}
		
		GameRules.raceTable[1] = "npc_dota_hero_dragon_knight"
		GameRules.raceTable[2] = "npc_dota_hero_huskar"
		GameRules.raceTable[3] = "npc_dota_hero_furion"
		GameRules.raceTable[4] = "npc_dota_hero_life_stealer"
	end
end

function dotacraft:SetupColorTable()
	--print("creating color table")
		
	SetNetTableValue(GameRules.UI_COLORTABLE, "0", 	{r=255, g=3,   b=3	})	-- red
	SetNetTableValue(GameRules.UI_COLORTABLE, "1", 	{r=0, 	g=66,  b=255})	-- blue
	SetNetTableValue(GameRules.UI_COLORTABLE, "2", 	{r=28, 	g=230, b=185})	-- teal
	SetNetTableValue(GameRules.UI_COLORTABLE, "3", 	{r=84, 	g=0,   b=129})	-- purple
	SetNetTableValue(GameRules.UI_COLORTABLE, "4", 	{r=255, g=255, b=1	})	-- yellow
	SetNetTableValue(GameRules.UI_COLORTABLE, "5", 	{r=254, g=138, b=14	})	-- orange
	SetNetTableValue(GameRules.UI_COLORTABLE, "6", 	{r=32, 	g=192, b=0	})	-- green
	SetNetTableValue(GameRules.UI_COLORTABLE, "7",	{r=229, g=91,  b=176})	-- pink
	SetNetTableValue(GameRules.UI_COLORTABLE, "8",	{r=149, g=150, b=151})	-- gray	
	SetNetTableValue(GameRules.UI_COLORTABLE, "9",	{r=126, g=191, b=241})	-- light blue	
	SetNetTableValue(GameRules.UI_COLORTABLE, "10",	{r=16, 	g=98,  b=70 })	-- dark green	
	SetNetTableValue(GameRules.UI_COLORTABLE, "11",	{r=78,  g=42,  b=4  })	-- brown		

end

--[[ PANAROMA DEVELOPER --]]
-- this function is called every state change so that each JS file will recieve the developer args
function dotacraft:PanaromaDeveloperMode(state)
	-- the reason for this function is that some JS are initialised later at the given state defined in the uimanifest.
	-- use this event inside your JS to catch it: 	GameEvents.Subscribe( "panaroma_developer", Developer_Mode ); Developer_Mode is the function inside js

	-- check if developer mode
	if Convars:GetBool("developer") then	
		Timers:CreateTimer(1, function()
			CustomGameEventManager:Send_ServerToAllClients("panaroma_developer", {developer = true})
		end)
	end
end

--[[ UI GLOBALS --]]
function SetNetTableValue(NetTableName, key, table)
	CustomNetTables:SetTableValue(NetTableName, key, table)
end

function GetNetTableValue(NetTableName, key)
    --print("NetTable", key, CustomNetTables:GetTableValue("dotacraft_color_table", key))
    return CustomNetTables:GetTableValue(NetTableName, key)
end

-- Returns a Vector with the color of the player
function dotacraft:ColorForPlayer( playerID )
	local Player_Table = GetNetTableValue(GameRules.UI_PLAYERTABLE, tostring(playerID))
	local color = GetNetTableValue(GameRules.UI_COLORTABLE, tostring(Player_Table.color_id))
	return Vector(color.r, color.g, color.b)
end