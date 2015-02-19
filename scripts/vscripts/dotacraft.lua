print ('[DOTACRAFT] dotacraft.lua' )

----------------

CORPSE_MODEL = "models/creeps/neutral_creeps/n_creep_troll_skeleton/n_creep_troll_skeleton_fx.vmdl"
CORPSE_DURATION = 88

----------------

ENABLE_HERO_RESPAWN = true              -- Should the heroes automatically respawn on a timer or stay dead until manually respawned
UNIVERSAL_SHOP_MODE = false             -- Should the main shop contain Secret Shop items as well as regular items
ALLOW_SAME_HERO_SELECTION = true        -- Should we let people select the same hero as each other

HERO_SELECTION_TIME = 30.0              -- How long should we let people select their hero?
PRE_GAME_TIME = 30.0                    -- How long after people select their heroes should the horn blow and the game start?
POST_GAME_TIME = 60.0                   -- How long should we let people look at the scoreboard before closing the server automatically?
TREE_REGROW_TIME = 60.0                 -- How long should it take individual trees to respawn after being cut down/destroyed?

GOLD_PER_TICK = 0                     -- How much gold should players get per tick?
GOLD_TICK_TIME = 5                      -- How long should we wait in seconds between gold ticks?

RECOMMENDED_BUILDS_DISABLED = false     -- Should we disable the recommened builds for heroes (Note: this is not working currently I believe)
CAMERA_DISTANCE_OVERRIDE = 1600       -- How far out should we allow the camera to go?  1134 is the default in Dota

MINIMAP_ICON_SIZE = 1                   -- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE = 1             -- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE = 1              -- What icon size should we use for runes?

RUNE_SPAWN_TIME = 120                    -- How long in seconds should we wait between rune spawns?
CUSTOM_BUYBACK_COST_ENABLED = true      -- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED = true  -- Should we use a custom buyback time?
BUYBACK_ENABLED = false                 -- Should we allow people to buyback when they die?

DISABLE_FOG_OF_WAR_ENTIRELY = false      -- Should we disable fog of war entirely for both teams?
--USE_STANDARD_DOTA_BOT_THINKING = false  -- Should we have bots act like they would in Dota? (This requires 3 lanes, normal items, etc)
USE_STANDARD_HERO_GOLD_BOUNTY = true    -- Should we give gold for hero kills the same as in Dota, or allow those values to be changed?

USE_CUSTOM_TOP_BAR_VALUES = true        -- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE = true                  -- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR = true             -- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals)  Requires USE_CUSTOM_TOP_BAR_VALUES

ENABLE_TOWER_BACKDOOR_PROTECTION = false-- Should we enable backdoor protection for our towers?
REMOVE_ILLUSIONS_ON_DEATH = false       -- Should we remove all illusions if the main hero dies?
DISABLE_GOLD_SOUNDS = false             -- Should we disable the gold sound when players get gold?

END_GAME_ON_KILLS = true                -- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 50         -- How many kills for a team should signify an end of game?

USE_CUSTOM_HERO_LEVELS = true           -- Should we allow heroes to have custom levels?
MAX_LEVEL = 10                          -- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES = true             -- Should we use custom XP values to level up heroes, or the default Dota numbers?

-- Fill this table up with the required XP per level if you want to change it
XP_PER_LEVEL_TABLE = {}
for i=1,MAX_LEVEL do
	XP_PER_LEVEL_TABLE[i] = i * 100
end

-- Generated from template
if dotacraft == nil then
	print ( '[DOTACRAFT] creating dotacraft game mode' )
	dotacraft = class({})
end


--[[
This function should be used to set up Async precache calls at the beginning of the game.  The Precache() function 
in addon_game_mode.lua used to and may still sometimes have issues with client's appropriately precaching stuff.
If this occurs it causes the client to never precache things configured in that block.

In this function, place all of your PrecacheItemByNameAsync and PrecacheUnitByNameAsync.  These calls will be made
after all players have loaded in, but before they have selected their heroes. PrecacheItemByNameAsync can also
be used to precache dynamically-added datadriven abilities instead of items.  PrecacheUnitByNameAsync will 
precache the precache{} block statement of the unit and all precache{} block statements for every Ability# 
defined on the unit.

This function should only be called once.  If you want to/need to precache more items/abilities/units at a later
time, you can call the functions individually (for example if you want to precache units in a new wave of
holdout).
]]
function dotacraft:PostLoadPrecache()
		print("[DOTACRAFT] Performing Post-Load precache")    
	--PrecacheItemByNameAsync("item_example_item", function(...) end)
	--PrecacheItemByNameAsync("example_ability", function(...) end)

	PrecacheUnitByNameAsync("npc_dota_hero_viper", function(...) end)
	PrecacheUnitByNameAsync("npc_dota_hero_enigma", function(...) end)
	--PrecacheUnitByNameAsync("npc_precache_everything", function(...) end)
end

--[[
This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
It can be used to initialize state that isn't initializeable in Initdotacraft() but needs to be done before everyone loads in.
]]
function dotacraft:OnFirstPlayerLoaded()
	print("[DOTACRAFT] First Player has loaded")
end

--[[
This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function dotacraft:OnAllPlayersLoaded()
	print("[DOTACRAFT] All Players have loaded into the game")
end

--[[
This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
levels, changing the starting gold, removing/adding abilities, adding physics, etc.

The hero parameter is the hero entity that just spawned in
]]
function dotacraft:OnHeroInGame(hero)
	print("[DOTACRAFT] Hero spawned in game for first time -- " .. hero:GetUnitName())

	dotacraft:ModifyStatBonuses(hero)

--[[ Multiteam configuration, currently unfinished

local team = "team1"
local playerID = hero:GetPlayerID()
if playerID > 3 then
team = "team2"
end
print("setting " .. playerID .. " to team: " .. team)
MultiTeam:SetPlayerTeam(playerID, team)]]

-- This line for example will set the starting gold of every hero to 500 unreliable gold
hero:SetGold(5000, false)

-- These lines will create an item and add it to the player, effectively ensuring they start with the item
--local item = CreateItem("item_multiteam_action", hero, hero)
--hero:AddItem(item)

--[[ --These lines if uncommented will replace the W ability of any hero that loads into the game
--with the "example_ability" ability

local abil = hero:GetAbilityByIndex(1)
hero:RemoveAbility(abil:GetAbilityName())
hero:AddAbility("example_ability")]]
end

--[[
This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function dotacraft:OnGameInProgress()
	print("[DOTACRAFT] The game has officially begun")

Timers:CreateTimer(30, -- Start this timer 30 game-time seconds later
	function()
		print("This function is called 30 seconds after the game begins, and every 30 seconds thereafter")
	return 30.0 -- Rerun this timer every 30 game-time seconds 
	end)
end




-- Cleanup a player when they leave
function dotacraft:OnDisconnect(keys)
	print('[DOTACRAFT] Player Disconnected ' .. tostring(keys.userid))
	--DeepPrintTable(keys)

	local name = keys.name
	local networkid = keys.networkid
	local reason = keys.reason
	local userid = keys.userid

end

-- The overall game state has changed
function dotacraft:OnGameRulesStateChange(keys)
	print("[DOTACRAFT] GameRules State Changed")
	--DeepPrintTable(keys)

	local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		self.bSeenWaitForPlayers = true
	elseif newState == DOTA_GAMERULES_STATE_INIT then
		Timers:RemoveTimer("alljointimer")
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		local et = 6
		if self.bSeenWaitForPlayers then
			et = .01
		end
		Timers:CreateTimer("alljointimer", {
			useGameTime = true,
			endTime = et,
			callback = function()
			if PlayerResource:HaveAllPlayersJoined() then
				dotacraft:PostLoadPrecache()
				dotacraft:OnAllPlayersLoaded()
				return 
			end
			return 1
		end
		})
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		dotacraft:OnGameInProgress()
	end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function dotacraft:OnNPCSpawned(keys)
	--print("[DOTACRAFT] NPC Spawned")
	--DeepPrintTable(keys)
	local npc = EntIndexToHScript(keys.entindex)

	if npc:IsHero() then
		npc.strBonus = 0
        npc.intBonus = 0
        npc.agilityBonus = 0
        npc.attackspeedBonus = 0
    end

	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		dotacraft:OnHeroInGame(npc)
	end
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function dotacraft:OnEntityHurt(keys)
	--print("[DOTACRAFT] Entity Hurt")
	----DeepPrintTable(keys)
	local entCause = EntIndexToHScript(keys.entindex_attacker)
	local entVictim = EntIndexToHScript(keys.entindex_killed)
end

-- An item was picked up off the ground
function dotacraft:OnItemPickedUp(keys)
	print ( '[DOTACRAFT] OnItemPurchased' )
	--DeepPrintTable(keys)

	local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
	local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function dotacraft:OnPlayerReconnect(keys)
	print ( '[DOTACRAFT] OnPlayerReconnect' )
	--DeepPrintTable(keys) 
end

-- An item was purchased by a player
function dotacraft:OnItemPurchased( keys )
	print ( '[DOTACRAFT] OnItemPurchased' )
	--DeepPrintTable(keys)

	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end

	-- The name of the item purchased
	local itemName = keys.itemname 

	-- The cost of the item purchased
	local itemcost = keys.itemcost

end

-- An ability was used by a player
function dotacraft:OnAbilityUsed(keys)

	local player = EntIndexToHScript(keys.PlayerID)
	local abilityname = keys.abilityname
	local hero = player:GetAssignedHero()

	-- Cancel the ghost if the player casts another active ability.
	-- Start of BH Snippet:
	if hero ~= nil then
		local abil = hero:FindAbilityByName(abilityname)
		if player.cursorStream ~= nil then
			if not (string.len(abilityname) > 14 and string.sub(abilityname,1,14) == "move_to_point_") then
				if not DontCancelBuildingGhostAbils[abilityname] then
					player.cancelBuilding = true
				else
					print(abilityname .. " did not cancel building ghost.")
				end
			end
		end
	end
	-- End of BH Snippet
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function dotacraft:OnNonPlayerUsedAbility(keys)
	print('[DOTACRAFT] OnNonPlayerUsedAbility')
	--DeepPrintTable(keys)

	local abilityname=  keys.abilityname
end

-- A player changed their name
function dotacraft:OnPlayerChangedName(keys)
	print('[DOTACRAFT] OnPlayerChangedName')
	--DeepPrintTable(keys)

	local newName = keys.newname
	local oldName = keys.oldName
end

-- A player leveled up an ability
function dotacraft:OnPlayerLearnedAbility( keys)
	print ('[DOTACRAFT] OnPlayerLearnedAbility')
	--DeepPrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function dotacraft:OnAbilityChannelFinished(keys)
	print ('[DOTACRAFT] OnAbilityChannelFinished')
	--DeepPrintTable(keys)

	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

-- A player leveled up
function dotacraft:OnPlayerLevelUp(keys)
	print ('[DOTACRAFT] OnPlayerLevelUp')
	--DeepPrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local level = keys.level
end

-- A player last hit a creep, a tower, or a hero
function dotacraft:OnLastHit(keys)
	print ('[DOTACRAFT] OnLastHit')
	--DeepPrintTable(keys)

	local isFirstBlood = keys.FirstBlood == 1
	local isHeroKill = keys.HeroKill == 1
	local isTowerKill = keys.TowerKill == 1
	local player = PlayerResource:GetPlayer(keys.PlayerID)
end

-- A tree was cut down by tango, quelling blade, etc
function dotacraft:OnTreeCut(keys)
	print ('[DOTACRAFT] OnTreeCut')
	--DeepPrintTable(keys)

	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

-- A rune was activated by a player
function dotacraft:OnRuneActivated (keys)
	print ('[DOTACRAFT] OnRuneActivated')
	--DeepPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local rune = keys.rune

	--[[ Rune Can be one of the following types
	DOTA_RUNE_DOUBLEDAMAGE
	DOTA_RUNE_HASTE
	DOTA_RUNE_HAUNTED
	DOTA_RUNE_ILLUSION
	DOTA_RUNE_INVISIBILITY
	DOTA_RUNE_MYSTERY
	DOTA_RUNE_RAPIER
	DOTA_RUNE_REGENERATION
	DOTA_RUNE_SPOOKY
	DOTA_RUNE_TURBO
	]]
end

-- A player took damage from a tower
function dotacraft:OnPlayerTakeTowerDamage(keys)
	print ('[DOTACRAFT] OnPlayerTakeTowerDamage')
	--DeepPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local damage = keys.damage
end

-- A player picked a hero
function dotacraft:OnPlayerPickHero(keys)
	print ('[DOTACRAFT] OnPlayerPickHero')
	--DeepPrintTable(keys)

	local hero = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
	local playerID = hero:GetPlayerID()

	--[[local level = MAX_LEVEL
	for i=1,level-1 do
		hero:HeroLevelUp(false)
	end]]

	-- Initialize Variables for Tracking
	player.lumber = 0
	player.buildings = {}
	player.builders = {}

	-- Give Initial Lumber
	player.lumber = 1000
	print("Lumber Gained. " .. hero:GetUnitName() .. " is currently at " .. player.lumber)
    FireGameEvent('cgm_player_lumber_changed', { player_ID = pID, lumber = player.lumber })

    -- Create Main Building
    local position = Vector(6150,5500,128) -- This position should be dynamic according to the map starting points
	local building = CreateUnitByName("human_town_hall", position, true, hero, hero, hero:GetTeamNumber())
	building:SetOwner(hero)
	building:SetControllableByPlayer(playerID, true)
	building:SetAbsOrigin(position)
	building:RemoveModifierByName("modifier_invulnerable")
	player.buildings["human_town_hall"] = 1

	-- Create Builders
	for i=1,5 do
		local peasant = CreateUnitByName("human_peasant", position+RandomVector(300+i*20), true, hero, hero, hero:GetTeamNumber())
		peasant:SetOwner(hero)
		peasant:SetControllableByPlayer(playerID, true)
		table.insert(player.builders, peasant)

		-- Go through the abilities and upgrade
		CheckAbilityRequirements( peasant, player )
	end

end


-- Go through every ability and check if the requirements are met
function CheckAbilityRequirements( unit, player )

	local requirements = GameRules.Requirements
	local buildings = player.buildings
	local requirement_failed = false

	-- The disabled abilities end with this affix
	local len = string.len("_disabled")

	for abilitySlot=0,15 do
		local ability = unit:GetAbilityByIndex(abilitySlot)

		-- If the ability exists, check its requirements
		if ability then
			local disabled_ability_name = ability:GetAbilityName()

			-- Check the table of requirements in the KV file
			if requirements[disabled_ability_name] then
				local requirement_count = #requirements[disabled_ability_name]
				print(disabled_ability_name.. "has "..requirement_count.." Requirements")
						
				-- Go through each requirement line and check if the player has that building on its list
				for k,v in pairs(requirements[disabled_ability_name]) do
					print("Building Name","Need","Have")
					print(k,v,buildings[k])

					-- Look for the building and update counter
					if buildings[k] and buildings[k] > 0 then
						print("Found at least one "..k)
					else
						print("Failed one of the requirements for "..disabled_ability_name..", no "..k.." found")
						requirement_failed = true
						break
					end
				end

				if not requirement_failed then
					-- Cut the _disabled to learn the new ability 
					local ability_len = string.len(disabled_ability_name)
					local ability_name = string.sub(disabled_ability_name, 1 , ability_len - len)

					print("Requirement is met, swapping "..disabled_ability_name.." for "..ability_name)
					unit:AddAbility(ability_name)
					unit:SwapAbilities(disabled_ability_name, ability_name, false, true)
					unit:RemoveAbility(disabled_ability_name)

					-- Set the new ability level
					local ability = unit:FindAbilityByName(ability_name)
					ability:SetLevel(ability:GetMaxLevel())
				end				
			end
		end	
	end
end



-- A player killed another player in a multi-team context
function dotacraft:OnTeamKillCredit(keys)
	print ('[DOTACRAFT] OnTeamKillCredit')
	--DeepPrintTable(keys)

	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
	local numKills = keys.herokills
	local killerTeamNumber = keys.teamnumber
	end

-- An entity died
function dotacraft:OnEntityKilled( event )
	--print( '[DOTACRAFT] OnEntityKilled Called' )

	-- The Unit that was Killed
	local killedUnit = EntIndexToHScript(event.entindex_killed)
	-- The Killing entity
	if event.entindex_attacker then
		local killerEntity = EntIndexToHScript(event.entindex_attacker)
	end

	-- If the unit is supposed to leave a corpse, create a dummy_unit to use abilities on it.
	Timers:CreateTimer(1, function() 
	if LeavesCorpse( killedUnit ) then
			-- Create and set model
			local corpse = CreateUnitByName("dummy_unit", killedUnit:GetAbsOrigin(), true, nil, nil, killedUnit:GetTeamNumber())
			corpse:SetModel(CORPSE_MODEL)

			-- Set the corpse invisible until the dota corpse disappears
			corpse:AddNoDraw()
			
			-- Keep a reference to its name and expire time
			corpse.corpse_expiration = GameRules:GetGameTime() + CORPSE_DURATION
			corpse.unit_name = killedUnit:GetUnitName()

			-- Set custom corpse visible
			Timers:CreateTimer(3, function() corpse:RemoveNoDraw() end)

			-- Remove itself after the corpse duration
			Timers:CreateTimer(CORPSE_DURATION, function()
				if corpse and IsValidEntity(corpse) then
					print("removing corpse")
					corpse:RemoveSelf()
				end
			end)
		end
	end)

end

-- Custom Corpse Mechanic
function LeavesCorpse( unit )
	
	-- Heroes don't leave corpses (includes illusions)
	if unit:IsHero() then
		return false

	-- Ignore buildings	
	elseif unit.GetInvulnCount ~= nil then
		return false

	-- Ignore units that start with dummy keyword	
	elseif string.find(unit:GetUnitName(), "dummy") then
		return false

	-- Ignore units that were specifically set to leave no corpse
	elseif unit.no_corpse then
		return false

	-- ?
	--elseif unit.AddAbility == nil then
	--	return false

	-- Leave corpse
	else
		print("Leave corpse")
		return true
	end
end


-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function dotacraft:Initdotacraft()
	dotacraft = self
	print('[DOTACRAFT] Starting to load dotacraft gamemode...')

	-- Setup rules
	GameRules:SetHeroRespawnEnabled( ENABLE_HERO_RESPAWN )
	GameRules:SetUseUniversalShopMode( UNIVERSAL_SHOP_MODE )
	GameRules:SetSameHeroSelectionEnabled( ALLOW_SAME_HERO_SELECTION )
	GameRules:SetHeroSelectionTime( HERO_SELECTION_TIME )
	GameRules:SetPreGameTime( PRE_GAME_TIME)
	GameRules:SetPostGameTime( POST_GAME_TIME )
	GameRules:SetTreeRegrowTime( TREE_REGROW_TIME )
	GameRules:SetUseCustomHeroXPValues ( USE_CUSTOM_XP_VALUES )
	GameRules:SetGoldPerTick(GOLD_PER_TICK)
	GameRules:SetGoldTickTime(GOLD_TICK_TIME)
	GameRules:SetRuneSpawnTime(RUNE_SPAWN_TIME)
	GameRules:SetUseBaseGoldBountyOnHeroes(USE_STANDARD_HERO_GOLD_BOUNTY)
	GameRules:SetHeroMinimapIconScale( MINIMAP_ICON_SIZE )
	GameRules:SetCreepMinimapIconScale( MINIMAP_CREEP_ICON_SIZE )
	GameRules:SetRuneMinimapIconScale( MINIMAP_RUNE_ICON_SIZE )
	print('[DOTACRAFT] GameRules set')

	InitLogFile( "log/dotacraft.txt","")

	-- Event Hooks
	-- All of these events can potentially be fired by the game, though only the uncommented ones have had
	-- Functions supplied for them.  If you are interested in the other events, you can uncomment the
	-- ListenToGameEvent line and add a function to handle the event
	--ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(dotacraft, 'OnPlayerLevelUp'), self)
	--ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(dotacraft, 'OnAbilityChannelFinished'), self)
	--ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(dotacraft, 'OnPlayerLearnedAbility'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(dotacraft, 'OnEntityKilled'), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(dotacraft, 'OnConnectFull'), self)
	--ListenToGameEvent('player_disconnect', Dynamic_Wrap(dotacraft, 'OnDisconnect'), self)
	--ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(dotacraft, 'OnItemPurchased'), self)
	--ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(dotacraft, 'OnItemPickedUp'), self)
	--ListenToGameEvent('last_hit', Dynamic_Wrap(dotacraft, 'OnLastHit'), self)
	--ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(dotacraft, 'OnNonPlayerUsedAbility'), self)
	--ListenToGameEvent('player_changename', Dynamic_Wrap(dotacraft, 'OnPlayerChangedName'), self)
	--ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(dotacraft, 'OnRuneActivated'), self)
	--ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(dotacraft, 'OnPlayerTakeTowerDamage'), self)
	--ListenToGameEvent('tree_cut', Dynamic_Wrap(dotacraft, 'OnTreeCut'), self)
	--ListenToGameEvent('entity_hurt', Dynamic_Wrap(dotacraft, 'OnEntityHurt'), self)
	ListenToGameEvent('player_connect', Dynamic_Wrap(dotacraft, 'PlayerConnect'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(dotacraft, 'OnAbilityUsed'), self)
	--ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(dotacraft, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(dotacraft, 'OnNPCSpawned'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(dotacraft, 'OnPlayerPickHero'), self)
	--ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(dotacraft, 'OnTeamKillCredit'), self)
	--ListenToGameEvent("player_reconnected", Dynamic_Wrap(dotacraft, 'OnPlayerReconnect'), self)
	--ListenToGameEvent('player_spawn', Dynamic_Wrap(dotacraft, 'OnPlayerSpawn'), self)
	--ListenToGameEvent('dota_unit_event', Dynamic_Wrap(dotacraft, 'OnDotaUnitEvent'), self)
	--ListenToGameEvent('nommed_tree', Dynamic_Wrap(dotacraft, 'OnPlayerAteTree'), self)
	--ListenToGameEvent('player_completed_game', Dynamic_Wrap(dotacraft, 'OnPlayerCompletedGame'), self)
	--ListenToGameEvent('dota_match_done', Dynamic_Wrap(dotacraft, 'OnDotaMatchDone'), self)
	--ListenToGameEvent('dota_combatlog', Dynamic_Wrap(dotacraft, 'OnCombatLogEvent'), self)
	--ListenToGameEvent('dota_player_killed', Dynamic_Wrap(dotacraft, 'OnPlayerKilled'), self)
	--ListenToGameEvent('player_team', Dynamic_Wrap(dotacraft, 'OnPlayerTeam'), self)

	-- Remove building invulnerability
	print("Make buildings vulnerable")
	local allBuildings = Entities:FindAllByClassname('npc_dota_building')
	for i = 1, #allBuildings, 1 do
		local building = allBuildings[i]
		if building:HasModifier('modifier_invulnerable') then
			building:RemoveModifierByName('modifier_invulnerable')
		end
	end


	-- Commands can be registered for debugging purposes or as functions that can be called by the custom Scaleform UI
	Convars:RegisterCommand( "command_example", Dynamic_Wrap(dotacraft, 'ExampleConsoleCommand'), "A console command example", 0 )

	-- Fill server with fake clients
	-- Fake clients don't use the default bot AI for buying items or moving down lanes and are sometimes necessary for debugging
	Convars:RegisterCommand('fake', function()
		-- Check if the server ran it
		if not Convars:GetCommandClient() then
		  -- Create fake Players
			SendToServerConsole('dota_create_fake_clients')

			Timers:CreateTimer('assign_fakes', {
			  	useGameTime = false,
			  	endTime = Time(),
			  	callback = function(dotacraft, args)
			  	local userID = 20
			  	for i=0, 9 do
			  		userID = userID + 1
			        -- Check if this player is a fake one
			        if PlayerResource:IsFakeClient(i) then
			          	-- Grab player instance
			          	local ply = PlayerResource:GetPlayer(i)
			          	-- Make sure we actually found a player instance
			        	if ply then
				          	CreateHeroForPlayer('npc_dota_hero_axe', ply)
			          		self:OnConnectFull({ userid = userID, index = ply:entindex()-1 })
				          	ply:GetAssignedHero():SetControllableByPlayer(0, true)
			    		end
			      	end
			  	end
			end})
		end
	end, 'Connects and assigns fake Players.', 0)

	--[[This block is only used for testing events handling in the event that Valve adds more in the future
	Convars:RegisterCommand('events_test', function()
	  dotacraft:StartEventTest()
	  end, "events test", 0)]]

	-- Change random seed
	local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
	math.randomseed(tonumber(timeTxt))

	-- Initialized tables for tracking state
	self.vUserIds = {}
	self.vSteamIds = {}
	self.vBots = {}
	self.vBroadcasters = {}

	self.vPlayers = {}
	self.vRadiant = {}
	self.vDire = {}

	self.nRadiantKills = 0
	self.nDireKills = 0

	self.bSeenWaitForPlayers = false

	-- Full units file to get the custom values
  	GameRules.UnitKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")
  	GameRules.Requirements = LoadKeyValues("scripts/kv/tech_tree.kv")

  	-- Building Helper by Myll
  	BuildingHelper:Init() -- nHalfMapLength

	print('[DOTACRAFT] Done loading dotacraft gamemode!\n\n')
end

mode = nil

-- This function is called as the first player loads and sets up the dotacraft parameters
function dotacraft:Capturedotacraft()
	if mode == nil then
		-- Set dotacraft parameters
		mode = GameRules:GetGameModeEntity()        
		mode:SetRecommendedItemsDisabled( RECOMMENDED_BUILDS_DISABLED )
		mode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
		mode:SetCustomBuybackCostEnabled( CUSTOM_BUYBACK_COST_ENABLED )
		mode:SetCustomBuybackCooldownEnabled( CUSTOM_BUYBACK_COOLDOWN_ENABLED )
		mode:SetBuybackEnabled( BUYBACK_ENABLED )
		mode:SetTopBarTeamValuesOverride ( USE_CUSTOM_TOP_BAR_VALUES )
		mode:SetTopBarTeamValuesVisible( TOP_BAR_VISIBLE )
		mode:SetUseCustomHeroLevels ( USE_CUSTOM_HERO_LEVELS )
		mode:SetCustomHeroMaxLevel ( MAX_LEVEL )
		mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

		--mode:SetBotThinkingEnabled( USE_STANDARD_DOTA_BOT_THINKING )
		mode:SetTowerBackdoorProtectionEnabled( ENABLE_TOWER_BACKDOOR_PROTECTION )

		mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
		mode:SetGoldSoundDisabled( DISABLE_GOLD_SOUNDS )
		mode:SetRemoveIllusionsOnDeath( REMOVE_ILLUSIONS_ON_DEATH )

		mode:SetHUDVisible(9, false)  -- Get Rid of Courier

		--GameRules:GetGameModeEntity():SetThink( "Think", self, "GlobalThink", 2 )

		--self:SetupMultiTeams()
		--self:OnFirstPlayerLoaded()
	end 
end

-- Multiteam support is unfinished currently
--[[function dotacraft:SetupMultiTeams()
MultiTeam:start()
MultiTeam:CreateTeam("team1")
MultiTeam:CreateTeam("team2")
end]]

-- This function is called 1 to 2 times as the player connects initially but before they 
-- have completely connected
function dotacraft:PlayerConnect(keys)
	print('[DOTACRAFT] PlayerConnect')
	--DeepPrintTable(keys)

	if keys.bot == 1 then
	-- This user is a Bot, so add it to the bots table
	self.vBots[keys.userid] = 1
	end
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function dotacraft:OnConnectFull(keys)
	print ('[DOTACRAFT] OnConnectFull')
	--DeepPrintTable(keys)
	dotacraft:Capturedotacraft()

	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)

	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()

	-- Update the user ID table with this user
	self.vUserIds[keys.userid] = ply

	-- Update the Steam ID table
	self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply

	-- If the player is a broadcaster flag it in the Broadcasters table
	if PlayerResource:IsBroadcaster(playerID) then
		self.vBroadcasters[keys.userid] = 1
		return
	end
end

-- This is an example console command
function dotacraft:ExampleConsoleCommand()
	print( '******* Example Console Command ***************' )
	local cmdPlayer = Convars:GetCommandClient()
	if cmdPlayer then
		local playerID = cmdPlayer:GetPlayerID()
		if playerID ~= nil and playerID ~= -1 then
	  	-- Do something here for the player who called this command
	  	PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_viper", 1000, 1000)
		end
	end

	print( '*********************************************' )
end


--Custom Stat Rules
function dotacraft:ModifyStatBonuses(unit)
	local spawnedUnitIndex = unit
	print("Modifying Stats Bonus")
		Timers:CreateTimer(DoUniqueString("updateHealth_" .. spawnedUnitIndex:GetPlayerID()), {
		endTime = 0.25,
		callback = function()
			-- ==================================
			-- Adjust health based on strength
			-- ==================================
 
			-- Get player strength
			local strength = spawnedUnitIndex:GetStrength()
			--Check if strBonus is stored on hero, if not set it to 0
			if spawnedUnitIndex.strBonus == nil then
				spawnedUnitIndex.strBonus = 0
			end
 
			-- If player strength is different this time around, start the adjustment
			if strength ~= spawnedUnitIndex.strBonus then
				-- Modifier values
				local bitTable = {128,64,32,16,8,4,2,1}
 
				-- Gets the list of modifiers on the hero and loops through removing and health modifier
				local modCount = spawnedUnitIndex:GetModifierCount()
				for i = 0, modCount do
					for u = 1, #bitTable do
						local val = bitTable[u]
						if spawnedUnitIndex:GetModifierNameByIndex(i) == "modifier_health_mod_" .. val  then
							spawnedUnitIndex:RemoveModifierByName("modifier_health_mod_" .. val)
						end
					end
				end
 
				-- Creates temporary item to steal the modifiers from
				local healthUpdater = CreateItem("item_health_modifier", nil, nil) 
				for p=1, #bitTable do
					local val = bitTable[p]
					local count = math.floor(strength / val)
					if count >= 1 then
						healthUpdater:ApplyDataDrivenModifier(spawnedUnitIndex, spawnedUnitIndex, "modifier_health_mod_" .. val, {})
						strength = strength - val
					end
				end
				-- Cleanup
				UTIL_RemoveImmediate(healthUpdater)
				healthUpdater = nil
			end
			-- Updates the stored strength bonus value for next timer cycle
			spawnedUnitIndex.strBonus = spawnedUnitIndex:GetStrength()
			spawnedUnitIndex.HealthTomesStack = spawnedUnitIndex:GetModifierStackCount("tome_health_modifier", spawnedUnitIndex)
			-- ==================================
			-- Adjust mana based on intellect
			-- ==================================
 
			-- Get player intellect
			local intellect = spawnedUnitIndex:GetIntellect()
 
			--Check if intBonus is stored on hero, if not set it to 0
			if spawnedUnitIndex.intBonus == nil then
				spawnedUnitIndex.intBonus = 0
			end
 
			-- If player intellect is different this time around, start the adjustment
			if intellect ~= spawnedUnitIndex.intBonus then
				-- Modifier values
				local bitTable = {128,64,32,16,8,4,2,1}
 
				-- Gets the list of modifiers on the hero and loops through removing and mana modifier
				local modCount = spawnedUnitIndex:GetModifierCount()
				for i = 0, modCount do
					for u = 1, #bitTable do
						local val = bitTable[u]
						if spawnedUnitIndex:GetModifierNameByIndex(i) == "modifier_mana_mod_" .. val  then
							spawnedUnitIndex:RemoveModifierByName("modifier_mana_mod_" .. val)
						end
					end
				end
 
				-- Creates temporary item to steal the modifiers from
				local manaUpdater = CreateItem("item_mana_modifier", nil, nil) 
				for p=1, #bitTable do
					local val = bitTable[p]
					local count = math.floor(intellect / val)
					if count >= 1 then
						manaUpdater:ApplyDataDrivenModifier(spawnedUnitIndex, spawnedUnitIndex, "modifier_mana_mod_" .. val, {})
						intellect = intellect - val
					end
				end
				-- Cleanup
				UTIL_RemoveImmediate(healthUpdater)
				manaUpdater = nil
			end
			-- Updates the stored intellect bonus value for next timer cycle
			spawnedUnitIndex.intBonus = spawnedUnitIndex:GetIntellect()
	
			-- ==================================
			-- Adjust attackspeed based on agility
			-- ==================================
 
			-- Get player agility
			local agility = spawnedUnitIndex:GetAgility()
 
			--Check if intBonus is stored on hero, if not set it to 0
			if spawnedUnitIndex.attackspeedBonus == nil then
				spawnedUnitIndex.attackspeedBonus = 0
			end
 
			-- If player agility is different this time around, start the adjustment
			if agility ~= spawnedUnitIndex.attackspeedBonus then
				-- Modifier values
				local bitTable = {128,64,32,16,8,4,2,1}
 
				-- Gets the list of modifiers on the hero and loops through removing and attackspeed modifier
				local modCount = spawnedUnitIndex:GetModifierCount()
				for i = 0, modCount do
					for u = 1, #bitTable do
						local val = bitTable[u]
						if spawnedUnitIndex:GetModifierNameByIndex(i) == "modifier_attackspeed_mod_" .. val  then
							spawnedUnitIndex:RemoveModifierByName("modifier_attackspeed_mod_" .. val)
						end
					end
				end
 
				-- Creates temporary item to steal the modifiers from
				local attackspeedUpdater = CreateItem("item_attackspeed_modifier", nil, nil) 
				for p=1, #bitTable do
					local val = bitTable[p]
					local count = math.floor(agility / val)
					if count >= 1 then
						attackspeedUpdater:ApplyDataDrivenModifier(spawnedUnitIndex, spawnedUnitIndex, "modifier_attackspeed_mod_" .. val, {})
						agility = agility - val
					end
				end
				-- Cleanup
				UTIL_RemoveImmediate(healthUpdater)
				attackspeedUpdater = nil
			end
			-- Updates the stored agility bonus value for next timer cycle
			spawnedUnitIndex.attackspeedBonus = spawnedUnitIndex:GetAgility()
			
			
			-- ==================================
			-- Adjust armor based on agi 
			-- Added as +Armor and not Base Armor because there's no BaseArmor modifier (please...)
			-- ==================================

			-- Get player primary stat value
			local agility = spawnedUnitIndex:GetAgility()

			--Check if primaryStatBonus is stored on hero, if not set it to 0
			if spawnedUnitIndex.agilityBonus == nil then
				spawnedUnitIndex.agilityBonus = 0
			end

			-- If player int is different this time around, start the adjustment
			if agility ~= spawnedUnitIndex.agilityBonus then
				-- Modifier values
				local bitTable = {64,32,16,8,4,2,1}

				-- Gets the list of modifiers on the hero and loops through removing and armor modifier
				for u = 1, #bitTable do
					local val = bitTable[u]
					if spawnedUnitIndex:HasModifier( "modifier_armor_mod_" .. val)  then
						spawnedUnitIndex:RemoveModifierByName("modifier_armor_mod_" .. val)
					end
					
					if spawnedUnitIndex:HasModifier( "modifier_negative_armor_mod_" .. val)  then
						spawnedUnitIndex:RemoveModifierByName("modifier_negative_armor_mod_" .. val)
					end
				end
				print("========================")
				agility = agility / 7
				print("Agi / 7: "..agility)
				-- Remove Armor
				-- Creates temporary item to steal the modifiers from
				local armorUpdater = CreateItem("item_armor_modifier", nil, nil) 
				for p=1, #bitTable do
					local val = bitTable[p]
					local count = math.floor(agility / val)
					if count >= 1 then
						armorUpdater:ApplyDataDrivenModifier(spawnedUnitIndex, spawnedUnitIndex, "modifier_negative_armor_mod_" .. val, {})
						print("Adding modifier_negative_armor_mod_" .. val)
						agility = agility - val
					end
				end

				agility = spawnedUnitIndex:GetAgility()
				agility = agility / 3
				print("Agi / 3: "..agility)
				for p=1, #bitTable do
					local val = bitTable[p]
					local count = math.floor(agility / val)
					if count >= 1 then
						armorUpdater:ApplyDataDrivenModifier(spawnedUnitIndex, spawnedUnitIndex, "modifier_armor_mod_" .. val, {})
						agility = agility - val
						print("Adding modifier_armor_mod_" .. val)
					end
				end

				-- Cleanup
				UTIL_RemoveImmediate(armorUpdater)
				armorUpdater = nil
			end
			-- Updates the stored Int bonus value for next timer cycle
			spawnedUnitIndex.agilityBonus = spawnedUnitIndex:GetAgility()

			return 0.25
		end
	})

end