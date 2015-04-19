 print ('[DOTACRAFT] dotacraft.lua' )

----------------

CORPSE_MODEL = "models/creeps/neutral_creeps/n_creep_troll_skeleton/n_creep_troll_skeleton_fx.vmdl"
CORPSE_DURATION = 88

----------------

ENABLE_HERO_RESPAWN = false              -- Should the heroes automatically respawn on a timer or stay dead until manually respawned
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
XP_PER_LEVEL_TABLE = {
	0, -- 1
	200, -- 2 +200
	500, -- 3 +300
	900, -- 4 +400
	1400, -- 5 +500
	2000, -- 6 +600
	2700, -- 7 +700
	3500, -- 8 +800
	4400, -- 9 +900
	5400 -- 10 +1000
 }

XP_BOUNTY_TABLE = {
	25,
	40,
	60,
	85,
	115,
	150,
	190,
	235,
	285,
	340
}

XP_NEUTRAL_SCALING = {
	0.80,
	0.70, 
	0.62,
	0.55,
	0,
	0,
	0,
	0,
	0,
	0
}

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

	-- Cancel the ghost if the player casts another active ability.
	-- Start of BH Snippet:
	if player.cursorStream ~= nil then
		if not (string.len(abilityname) > 14 and string.sub(abilityname,1,14) == "move_to_point_") then
			if not DontCancelBuildingGhostAbils[abilityname] then
				player:CancelGhost()
			else
				print(abilityname .. " did not cancel building ghost.")
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
	player.food_limit = 0 -- The amount of food available to build units
	player.food_used = 0 -- The amount of food used by this player creatures
	player.buildings = {} -- This keeps the name and quantity of each building, to access in O(1)
	player.units = {} -- This keeps the handle of all the units of the player army, to iterate for unlocking upgrades
	player.structures = {} -- This keeps the handle of the constructed units, to iterate for unlocking upgrades
	player.upgrades = {} -- This kees the name of all the upgrades researched, so each unit can check and upgrade itself on spawn
	player.heroes = {} -- Owned hero units (not this assigned hero, which will be a fake)

	-- Give Initial Lumber
	ModifyLumber(player, 5150)

    -- Create Main Building
    -- This position should be dynamic according to the map starting points
    local position = Vector(6150,5500,128)
    if playerID > 0 then
    	position = Vector(-5916,5831,128)
    end

    -- Stop game logic on the model overview map
    if GetMapName() == "dotacraft" then
    	return
    end

    -- Define the initial unit names to spawn for this hero_race
    local hero_race = hero:GetUnitName()
    local city_center_name = GetCityCenterNameForHeroRace(hero_race)
    local builder_name = GetBuilderNameForHeroRace(hero_race)

	local building = CreateUnitByName(city_center_name, position, true, hero, hero, hero:GetTeamNumber())
	building:SetOwner(hero)
	building:SetControllableByPlayer(playerID, true)
	building:SetAbsOrigin(position)
	building:RemoveModifierByName("modifier_invulnerable")
	player.buildings[city_center_name] = 1
	table.insert(player.structures, building)

	CheckAbilityRequirements( building, player )

	-- Give Initial Food
    ModifyFoodLimit(player, GetFoodProduced(building))

	-- Create Builders
	for i=1,5 do
		local peasant = CreateUnitByName(builder_name, position+RandomVector(300+i*40), true, hero, hero, hero:GetTeamNumber())
		peasant:SetOwner(hero)
		peasant:SetControllableByPlayer(playerID, true)
		table.insert(player.units, peasant)

		-- Increment food used
		ModifyFoodUsed(player, GetFoodCost(peasant))

		-- Go through the abilities and upgrade
		CheckAbilityRequirements( peasant, player )
	end

	-- Hide main hero
	local ability = hero:FindAbilityByName("hide_hero")
	ability:UpgradeAbility(true)
	hero:SetAbilityPoints(0)
	hero:SetAbsOrigin(Vector(position.x,position.y,position.z - 322 ))

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
	local killerEntity
	if event.entindex_attacker then
		killerEntity = EntIndexToHScript(event.entindex_attacker)
	end

	-- START OF BH SNIPPET
	if BuildingHelper:IsBuilding(killedUnit) then
		killedUnit:RemoveBuilding(false)
	end
	-- END OF BH SNIPPET

	-- Player owner of the unit
	local player = killedUnit:GetPlayerOwner()

	if killedUnit:IsRealHero() then
		if player.altar then
			for _,altar in pairs(player.altar_structures) do
				print("ALLOW REVIVAL OF THIS THIS HERO AT THIS ALTAR")

				-- Set the strings for the _acquired ability to find and _revival ability to add
				local level = killedUnit:GetLevel()
				local name = killedUnit.RespawnAbility
				if name then
					local acquired_ability_name = name.."_acquired"
					local revival_ability_name = name.."_revive"..level

					print("FIND "..acquired_ability_name.." AND SWAP TO "..revival_ability_name)

					local ability = altar:FindAbilityByName(acquired_ability_name)
					if ability then
						altar:AddAbility(revival_ability_name)
						altar:SwapAbilities(acquired_ability_name, revival_ability_name, false, true)
						altar:RemoveAbility(acquired_ability_name)

						local new_ability = altar:FindAbilityByName(revival_ability_name)
						if new_ability then
							new_ability:SetLevel(new_ability:GetMaxLevel())
							print("ADDED "..revival_ability_name.." at level "..new_ability:GetMaxLevel())
						else
							print("ABILITY COULDNT BE CHANGED BECAUSE OF REASONS")
						end
					end
				end
			end
		end
	end

	-- Substract the Food Used
	local food_cost = GetFoodCost(killedUnit)
	if food_cost > 0 and player then
		ModifyFoodUsed(player, - food_cost)
	end

	if killedUnit.isBuilding then
		killedUnit:RemoveBuilding(false) -- Building Helper grid cleanup

		-- Substract the Food Produced
		local food_produced = GetFoodProduced(killedUnit)
		if food_produced > 0 and player then
			ModifyFoodLimit(player, - food_produced)
		end
	end

	-- Give Experience to heroes based on the level of the killed creature
	if not killedUnit.isBuilding then
		local XPGain = XP_BOUNTY_TABLE[killedUnit:GetLevel()]

		-- Grant XP in AoE
		local heroesNearby = FindUnitsInRadius( killerEntity:GetTeamNumber(), killedUnit:GetOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		--print("There are ",#heroesNearby," nearby the dead unit, base value for this unit is: "..XPGain)
		for _,hero in pairs(heroesNearby) do
			if hero:IsRealHero() and hero:GetTeam() ~= killedUnit:GetTeam() then

				-- Scale XP if neutral
				local xp = XPGain
				if killedUnit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
					xp = ( XPGain * XP_NEUTRAL_SCALING[hero:GetLevel()] ) / #heroesNearby
				end

				hero:AddExperience(math.floor(xp), false, false)
				--print("granted "..xp.." to "..hero:GetUnitName())
			end
		end		
	end

	-- Table cleanup
	if player then
		if tableContains(player.structures, killedUnit) then
			table.remove(player.structures, getIndex(player.structures,killedUnit))
			print("Building removed from the player structures table")

			-- Check for lose condition - All buildings destroyed
			print("Player "..player:GetPlayerID().." has "..#player.structures.." buildings left")
			if (#player.structures == 0) then
				GameRules:MakeTeamLose(player:GetTeamNumber())
			end

		elseif tableContains(player.units, killedUnit) then
			table.remove(player.units, getIndex(player.units,killedUnit))
			print("Unit removed from the player units table")
		end
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

	-- Remove from units table
	if killedUnit:IsCreature() and player then
		local unit = getIndex(player.units, killedUnit)
		if unit and unit ~= -1 then
			--DeepPrintTable(player.units)
			print("Removing "..unit.." from the player builders")
			table.remove(player.units, unit)
			--DeepPrintTable(player.units)
		end

	-- IF BUILDING DESTROYED, CHECK FOR POSSIBLE DOWNGRADES OF ABILITIES THAT CAN'T BE BUILT ANYMORE
	elseif killedUnit.GetInvulnCount ~= nil then

		-- Remove from it from player building tables
		local building = getIndex(player.structures, killedUnit:GetEntityIndex())
		local building_name = killedUnit:GetUnitName()
		print("Removing "..killedUnit:GetUnitName().." from the player structures")
		table.remove(player.structures, building)

		-- Substract 1 to the player building tracking table for that name
		player.buildings[building_name] = player.buildings[building_name] - 1

    	for k,builder in pairs(player.units) do
    		CheckAbilityRequirements( builder, player )
    	end

    	for k,structure in pairs(player.structures) do
    		CheckAbilityRequirements( structure, player )
    	end
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

	-- Allow cosmetic swapping
	SendToServerConsole( "dota_combines_model 0" )

	-- Commands can be registered for debugging purposes or as functions that can be called by the custom Scaleform UI
	Convars:RegisterCommand( "command_example", Dynamic_Wrap(dotacraft, 'ExampleConsoleCommand'), "A console command example", 0 )

	function GenerateAbilityString(player, ability_table)
		local abilities_string = ""
		local index = 1
		while ability_table[tostring(index)] do
			local ability_name = ability_table[tostring(index)]
			local ability_available = false
			if FindAbilityOnStructures(player, ability_name) or FindAbilityOnUnits(player, ability_name) then
				ability_available = true
			end
			index = index + 1
			if ability_available then
				print(index,ability_name,ability_available)
				abilities_string = abilities_string.."1,"
			else
				abilities_string = abilities_string.."0,"
			end
		end
		return abilities_string
	end

	-- Lumber AbilityValue, credits to zed https://github.com/zedor/AbilityValues
	-- Note: When the abilities change, we need to update this value.
	Convars:RegisterCommand( "ability_values_entity", function(name, entityIndex)
		local cmdPlayer = Convars:GetCommandClient()
		local pID = cmdPlayer:GetPlayerID()

		if cmdPlayer then
			local unit = EntIndexToHScript(tonumber(entityIndex))
			if not IsValidEntity(unit) then
				return
			end
			
			if unit:GetUnitName() == "npc_dota_hero_dragon_knight" then
				local unit_race = "human_race"
				print("Abilities Available:")
				local ability_table = GameRules.Abilities.human_race
				local abilities_string = GenerateAbilityString(cmdPlayer, ability_table)		

				FireGameEvent( 'show_overview_panel', { player_ID = pID, race = unit_race, abilities = abilities_string } )

			elseif unit:GetUnitName() == "npc_dota_hero_furion" then
				local unit_race = "nightelf_race"
				print("Abilities Available:")
				local ability_table = GameRules.Abilities.nightelf_race
				local abilities_string = GenerateAbilityString(cmdPlayer, ability_table)		

				FireGameEvent( 'show_overview_panel', { player_ID = pID, race = unit_race, abilities = abilities_string } )

			else
				print("HIDE PANEL")
				FireGameEvent( 'hide_overview_panel', { player_ID = pID } )
			end

	  		if unit then
	  			--and (unit:GetUnitName() == "human_peasant"
		  		local abilityValues = {}
		  		local itemValues = {}

		  		-- Iterate over the abilities
		  		for i=0,15 do
		  			local ability = unit:GetAbilityByIndex(i)

		  			-- If there's an ability in this slot and its not hidden, define the number to show
		  			if ability and not ability:IsHidden() then
		  				local lumberCost = ability:GetLevelSpecialValueFor("lumber_cost", ability:GetLevel() - 1)
		  				if lumberCost then
		  					table.insert(abilityValues,lumberCost)
		  				else
		  					table.insert(abilityValues,0)
		  				end
				  	end
		  		end

		  		FireGameEvent( 'ability_values_send', { player_ID = pID, 
		    										hue_1 = -10, val_1 = abilityValues[1], 
		    										hue_2 = -10, val_2 = abilityValues[2], 
		    										hue_3 = -10, val_3 = abilityValues[3], 
		    										hue_4 = -10, val_4 = abilityValues[4], 
		    										hue_5 = -10, val_5 = abilityValues[5],
		    										hue_6 = -10, val_6 = abilityValues[6] } )

		  		-- Iterate over the items
		  		for i=0,5 do
		  			local item = unit:GetItemInSlot(i)

		  			-- If there's an item in this slot, define the number to show
		  			if item then
		  				local lumberCost = item:GetSpecialValueFor("lumber_cost")
		  				if lumberCost then
		  					table.insert(itemValues,lumberCost)
		  				else
		  					table.insert(itemValues,0)
		  				end
				  	end
		  		end

		  		FireGameEvent( 'ability_values_send_items', { player_ID = pID, 
		    										hue_1 = 0, val_1 = itemValues[1], 
		    										hue_2 = 0, val_2 = itemValues[2], 
		    										hue_3 = 0, val_3 = itemValues[3], 
		    										hue_4 = 0, val_4 = itemValues[4], 
		    										hue_5 = 0, val_5 = itemValues[5],
		    										hue_6 = 0, val_6 = itemValues[6] } )
		    	
		    else
		    	-- Hide all the values if the unit is not supposed to show any.
		    	FireGameEvent( 'ability_values_send', { player_ID = pID, val_1 = 0, val_2 = 0, val_3 = 0, val_4 = 0, val_5 = 0, val_6 = 0 } )
		    	FireGameEvent( 'ability_values_send_items', { player_ID = pID, val_1 = 0, val_2 = 0, val_3 = 0, val_4 = 0, val_5 = 0, val_6 = 0 } )
		    end
	  	end
	end, "Change AbilityValues", 0 )

 	Convars:RegisterCommand( "player_overview_cast", function(name, ability_to_cast) 
 		local cmdPlayer = Convars:GetCommandClient()
		local pID = cmdPlayer:GetPlayerID()

		if cmdPlayer then
			print("Recieved command to cast "..ability_to_cast.." - Proceeding to find the ability")

			-- Need to protect against:
				-- Queing the same research skill twice
				-- Training peasants after upgrading to keep/castle
				-- Building ghost not appearing
				-- Item build abilities not sending

			if string.find(ability_to_cast, "_train") or string.find(ability_to_cast, "_research") then
				local ability = FindAbilityOnStructures(cmdPlayer, ability_to_cast)

				for _,building in pairs(cmdPlayer.structures) do
					if building:HasAbility(ability_to_cast) then
						local ability_cast = building:FindAbilityByName(ability_to_cast)
						building:CastAbilityImmediately(ability_cast, 0)
					end
				end

			-- _build abilities have the issue of BH/Flash not being able to find a handle
			elseif string.find(ability_to_cast, "_build") then
				local ability = FindAbilityOnUnits(cmdPlayer, ability_to_cast)

				for _,unit in pairs(cmdPlayer.units) do
					if unit:HasAbility(ability_to_cast) then
						local ability_cast = unit:FindAbilityByName(ability_to_cast)
						unit:CastAbilityImmediately(ability_cast, 0)
					end
				end
			end

		end


 	end, "Send an ability to find and cast", 0)


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
	GameRules.AbilityKV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
  	GameRules.UnitKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")
  	GameRules.ItemKV = LoadKeyValues("scripts/npc/npc_items_custom.txt")
  	GameRules.Requirements = LoadKeyValues("scripts/kv/tech_tree.kv")
  	GameRules.Wearables = LoadKeyValues("scripts/kv/wearables.kv")
  	GameRules.Modifiers = LoadKeyValues("scripts/kv/modifiers.kv")
  	GameRules.UnitUpgrades = LoadKeyValues("scripts/kv/unit_upgrades.kv")
  	GameRules.Abilities = LoadKeyValues("scripts/kv/abilities.kv")

  	-- Building Helper by Myll
  	BuildingHelper:Init() -- nHalfMapLength

  	-- Starting positions
  	GameRules.StartingPositions = {}
	local targets = Entities:FindAllByName( "starting_position" )
	for k,v in pairs(targets) do
		table.insert( GameRules.StartingPositions, v:GetOrigin() )
	end
	DeepPrintTable(GameRules.StartingPositions)

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
		mode:SetHUDVisible(12, false)  -- Get Rid of Recommended items
		mode:SetHUDVisible(1, false) -- Get Rid of Heroes on top
		mode:SetHUDVisible(6, false)  -- Get Rid of Shop button
		mode:SetHUDVisible(8, false) -- Get Rid of Quick Buy

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

	--CreateHeroForPlayer("npc_dota_hero_dragon_knight", ply)

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