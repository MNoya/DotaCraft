print ('[DOTACRAFT] dotacraft.lua' )
--[[
    dota_launch_custom_game dotacraft echo_isles
    dota_launch_custom_game dotacraft hills_of_glory
]]

CORPSE_MODEL = "models/creeps/neutral_creeps/n_creep_troll_skeleton/n_creep_troll_skeleton_fx.vmdl"
CORPSE_DURATION = 88

DISABLE_FOG_OF_WAR_ENTIRELY = false
CAMERA_DISTANCE_OVERRIDE = 1600
UNSEEN_FOG_ENABLED = false

UNDER_ATTACK_WARNING_INTERVAL = 60

STARTING_GOLD = 500
STARTING_LUMBER = 150

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

TEAM_COLORS = {}
TEAM_COLORS[DOTA_TEAM_GOODGUYS] = { 52, 85, 255 }   --  Blue
TEAM_COLORS[DOTA_TEAM_BADGUYS]  = { 255, 52, 85 }   --  Red
TEAM_COLORS[DOTA_TEAM_CUSTOM_1] = { 61, 210, 150 }  --  Teal
TEAM_COLORS[DOTA_TEAM_CUSTOM_2] = { 140, 42, 244 }  --  Purple
TEAM_COLORS[DOTA_TEAM_CUSTOM_3] = { 243, 201, 9 }   --  Yellow
TEAM_COLORS[DOTA_TEAM_CUSTOM_4] = { 255, 108, 0 }   --  Orange
TEAM_COLORS[DOTA_TEAM_CUSTOM_5] = { 101, 212, 19 }  --  Green
TEAM_COLORS[DOTA_TEAM_CUSTOM_6] = { 197, 77, 168 }  --  Pink
TEAM_COLORS[DOTA_TEAM_CUSTOM_7] = { 129, 83, 54 }   --  Brown
TEAM_COLORS[DOTA_TEAM_CUSTOM_8] = { 199, 228, 13 }  --  Olive

--------------

-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function dotacraft:InitGameMode()
    print('[DOTACRAFT] Starting to load dotacraft gamemode...')

    -- Setup rules
    LimitPathingSearchDepth(0.5)
    GameRules:SetHeroRespawnEnabled( false )
    GameRules:SetUseUniversalShopMode( false )
    GameRules:SetSameHeroSelectionEnabled( true )
    GameRules:SetHeroSelectionTime( 0 )
    GameRules:SetPreGameTime( 1 )
    GameRules:SetPostGameTime( 9001 )
    GameRules:SetTreeRegrowTime( 10000.0 )
    GameRules:SetUseCustomHeroXPValues ( true )
    GameRules:SetGoldPerTick(0)
    GameRules:SetUseBaseGoldBountyOnHeroes( false ) -- Need to check legacy values
    GameRules:SetHeroMinimapIconScale( 1 )
    GameRules:SetCreepMinimapIconScale( 1 )
    GameRules:SetRuneMinimapIconScale( 1 )
    GameRules:SetFirstBloodActive( false )
    GameRules:SetHideKillMessageHeaders( true )
    GameRules:EnableCustomGameSetupAutoLaunch( false )

    -- Set game mode rules
    GameMode = GameRules:GetGameModeEntity()        
    GameMode:SetRecommendedItemsDisabled( true )
    GameMode:SetBuybackEnabled( false )
    GameMode:SetTopBarTeamValuesOverride ( true )
    GameMode:SetTopBarTeamValuesVisible( true )
    GameMode:SetUnseenFogOfWarEnabled( UNSEEN_FOG_ENABLED ) 
    GameMode:SetTowerBackdoorProtectionEnabled( false )
    GameMode:SetGoldSoundDisabled( false )
    GameMode:SetRemoveIllusionsOnDeath( true )
    GameMode:SetAnnouncerDisabled( true )
    GameMode:SetLoseGoldOnDeath( false )
    GameMode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
    GameMode:SetUseCustomHeroLevels ( true )
    GameMode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )
    GameMode:SetFogOfWarDisabled( DISABLE_FOG_OF_WAR_ENTIRELY )
    GameMode:SetStashPurchasingDisabled( true )
    GameMode:SetMaximumAttackSpeed( 500 )

    -- Team Colors
    for team,color in pairs(TEAM_COLORS) do
      SetTeamCustomHealthbarColor(team, color[1], color[2], color[3])
    end

    print('[DOTACRAFT] Game Rules set')

    for teamID=DOTA_TEAM_FIRST,DOTA_TEAM_CUSTOM_MAX do
        GameRules:SetCustomGameTeamMaxPlayers( teamID, 10 )
    end

    -- Keep track of the last time each player was damaged (to play warnings/"we are under attack")
    GameRules.PLAYER_BUILDINGS_DAMAGED = {} 
    GameRules.PLAYER_DAMAGE_WARNING = {}

    -- Event Hooks
    ListenToGameEvent('entity_killed', Dynamic_Wrap(dotacraft, 'OnEntityKilled'), self)
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(dotacraft, 'OnConnectFull'), self)
    ListenToGameEvent('player_connect', Dynamic_Wrap(dotacraft, 'PlayerConnect'), self)
    ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(dotacraft, 'OnAbilityUsed'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(dotacraft, 'OnNPCSpawned'), self)
    ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(dotacraft, 'OnPlayerPickHero'), self)
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(dotacraft, 'OnGameRulesStateChange'), self)
    ListenToGameEvent('entity_hurt', Dynamic_Wrap(dotacraft, 'OnEntityHurt'), self)
    ListenToGameEvent('tree_cut', Dynamic_Wrap(dotacraft, 'OnTreeCut'), self)
    ListenToGameEvent('player_chat', Dynamic_Wrap(dotacraft, 'OnPlayerChat'), self)

    -- Filters
    GameMode:SetExecuteOrderFilter( Dynamic_Wrap( dotacraft, "FilterExecuteOrder" ), self )
    GameMode:SetDamageFilter( Dynamic_Wrap( dotacraft, "FilterDamage" ), self )
    GameMode:SetTrackingProjectileFilter( Dynamic_Wrap( dotacraft, "FilterProjectile" ), self )

    -- Lua Modifiers
    LinkLuaModifier("modifier_hex_frog", "libraries/modifiers/modifier_hex", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_hex_sheep", "libraries/modifiers/modifier_hex", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_model_scale", "libraries/modifiers/modifier_model_scale", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_client_convars", "libraries/modifiers/modifier_client_convars", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_autoattack", "units/attacks", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_autoattack_passive", "units/attacks", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_druid_bear_model", "units/nightelf/modifier_druid_model", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_druid_crow_model", "units/nightelf/modifier_druid_model", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_crypt_fiend_burrow_model", "units/undead/modifier_crypt_fiend_burrow_model", LUA_MODIFIER_MOTION_NONE)
    
    -- Remove building invulnerability
    local allBuildings = Entities:FindAllByClassname('npc_dota_building')
    for i = 1, #allBuildings, 1 do
        local building = allBuildings[i]
        if building:HasModifier('modifier_invulnerable') then
            building:RemoveModifierByName('modifier_invulnerable')
        end
    end

    -- Don't end the game if everyone is unassigned
    SendToServerConsole("dota_surrender_on_disconnect 0")

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

    -- Change random seed
    local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
    math.randomseed(tonumber(timeTxt))

    -- Initialized tables for tracking state
    self.vUserIds = {}
    self.vPlayerUserIds = {}
    self.vSteamIds = {}
    self.vBots = {}
    self.vBroadcasters = {}

    self.vPlayers = {}
    self.vRadiant = {}
    self.vDire = {}

    self.nRadiantKills = 0
    self.nDireKills = 0

    GameRules.DefeatedTeamCount = 0

    dotacraft:LoadKV()

    -- Keeps the blighted gridnav positions
    GameRules.Blight = {}

    -- Attack net table
    Attacks:Init()
    
    -- Starting positions
    GameRules.StartingPositions = {}
    local targets = Entities:FindAllByName( "*starting_position" ) --Inside player_start.vmap prefab
    for k,v in pairs(targets) do
        local pos_table = {}
        pos_table.position = v:GetOrigin()
        pos_table.playerID = -1
        GameRules.StartingPositions[k-1] = pos_table
    end

    if not UI_PLAYERTABLE then
       dotacraft:UI_Init()
    end
    print('[DOTACRAFT] Done loading dotacraft gamemode!')
end

function dotacraft:LoadKV()
    GameRules.Requirements = LoadKeyValues("scripts/kv/tech_tree.kv")
    GameRules.Wearables = LoadKeyValues("scripts/kv/wearables.kv")
    GameRules.Modifiers = LoadKeyValues("scripts/kv/modifiers.kv")
    GameRules.UnitUpgrades = LoadKeyValues("scripts/kv/unit_upgrades.kv")
    GameRules.Abilities = LoadKeyValues("scripts/kv/abilities.kv")
    GameRules.Drops = LoadKeyValues("scripts/kv/map_drops.kv")
    GameRules.Items = LoadKeyValues("scripts/kv/items.kv")
    GameRules.Damage = LoadKeyValues("scripts/kv/damage_table.kv")
end

function dotacraft:OnScriptReload()
    dotacraft:LoadKV()
end

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
    
    local entIndex = keys.index+1
    -- The Player entity of the joining user
    local ply = EntIndexToHScript(entIndex)

    -- The Player ID of the joining player
    local playerID = ply:GetPlayerID()

    -- Update the user ID table with this user
    self.vUserIds[keys.userid] = ply
    self.vPlayerUserIds[playerID] = keys.userid

    -- If the player is a broadcaster flag it in the Broadcasters table
    if PlayerResource:IsBroadcaster(playerID) then
        self.vBroadcasters[keys.userid] = 1
        return
    end
end

function dotacraft:OnFirstPlayerLoaded()
    print("[DOTACRAFT] First Player has loaded")
end

function dotacraft:OnAllPlayersLoaded()
    print("[DOTACRAFT] All Players have loaded into the game")

    print("[DOTACRAFT] Initializing Neutrals")
    GameRules.ALLNEUTRALS = Entities:FindAllByClassname("npc_dota_creature")
    for k,npc in pairs(GameRules.ALLNEUTRALS) do
        if npc:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
            Units:Init(npc)
        end
    end
end

function dotacraft:OnHeroInGame(hero)
    local hero_name = hero:GetUnitName()
    print("[DOTACRAFT] OnHeroInGame "..hero_name)

    if hero:HasAbility("hide_hero") then
        Timers:CreateTimer(0.03, function() 
            dotacraft:InitializePlayer(hero)
        end)
    else
        print("[DOTACRAFT] Hero spawned in game for first time -- " .. hero:GetUnitName())

        if Convars:GetBool("developer") then
            for i=1,9 do
                hero:HeroLevelUp(false)
            end
        end

        Attributes:ModifyBonuses(hero)

        -- Innate abilities
        if hero:HasAbility("nightelf_shadow_meld") then
            hero:FindAbilityByName("nightelf_shadow_meld"):SetLevel(1)
        end

        if hero:HasAbility("blood_mage_orbs") then
            hero:FindAbilityByName("blood_mage_orbs"):SetLevel(1)
        end

        if hero:HasAbility("firelord_arcana_model") then
            hero:FindAbilityByName("firelord_arcana_model"):SetLevel(1)
        end
    end
end

function dotacraft:InitializePlayer( hero )
    local player = hero:GetPlayerOwner()
    local playerID = hero:GetPlayerID()

    print("[DOTACRAFT] Initializing main hero entity for player "..playerID)

    Players:Init(playerID, hero)

    -- Client Settings
    hero:AddNewModifier(hero, nil, "modifier_client_convars", {})

    -- Create Main Building, define the initial unit names to spawn for this hero_race
    local position = Players:AssignEmptyPositionForPlayer(playerID)
    local hero_name = hero:GetUnitName()
    local race = hero:GetKeyValue("Race")
    local city_center_name = GetCityCenterNameForHeroRace(hero_name)
    local builder_name = GetBuilderNameForHeroRace(hero_name)
    local construction_size = BuildingHelper:GetConstructionSize(city_center_name) 
    local pathing_size = BuildingHelper:GetBlockPathingSize(city_center_name)

    local building = BuildingHelper:PlaceBuilding(player, city_center_name, position, construction_size, pathing_size, 0)
    Players:AddStructure(playerID, building)
    Players:SetMainCityCenter(playerID, building)
    CheckAbilityRequirements( building, playerID )

    -- Give Initial Food, Gold and Lumber
    dotacraft:InitializeResources( hero, building )

    -- Create Builders in between the gold mine and the city center
    local race_setup_table = {}
    race_setup_table.builder_name = GetBuilderNameForHeroRace(hero_name)
    race_setup_table.num_builders = 5
    race_setup_table.angle = 360 / race_setup_table.num_builders
    race_setup_table.closest_mine = Gatherer:GetClosestGoldMineToPosition(position)
    race_setup_table.closest_mine_pos = race_setup_table.closest_mine:GetAbsOrigin()
    race_setup_table.mid_point = race_setup_table.closest_mine_pos + (position-race_setup_table.closest_mine_pos)/2

    -- Special spawn rules
    if race == "undead" then
        -- Haunt the closest gold mine
        -- Hide the targeted gold mine    
        -- Create blight
        dotacraft:InitializeUndead( hero, race_setup_table, building )
    elseif race == "nightelf" then
        -- Apply rooted particles
        -- Entangle the closest gold mine
        -- Hide the targeted gold mine   
        dotacraft:InitializeNightElf( hero, race_setup_table, building )
    end

    -- Spawn as many builders as this race requires
    dotacraft:InitializeBuilders( hero, race_setup_table, building )

    -- Hide main hero under the main base
    -- Snap the camera to the created building and add it to selection
    -- Find neutrals near the starting zone and remove them
    dotacraft:InitializeTownHall( hero , position, building )

    -- Test options
    if Convars:GetBool("developer") then
        dotacraft:DeveloperMode(player)
    end

    -- Show UI elements for this race
    local player_race = Players:GetRace(playerID)
    CustomGameEventManager:Send_ServerToPlayer(player, "player_show_ui", { race = player_race, initial_builders = num_builders })

    -- Keep track of the Idle Builders and send them to the panorama UI every time the count updates
    dotacraft:TrackIdleWorkers( hero )

    --------------------------------------------
    -- Test game logic on the model overview map
    if GetMapName() == "1_dotacraft" then
        
        local races = {['human']=0,['orc']=0,['nightelf']=0,['undead']=0}
        races[race] = 1 -- Skip the picked race
        local startID = playerID
        for k,v in pairs(races) do
            if v == 0 then
                local position = Players:AssignEmptyPositionForPlayer(playerID)
                local hero_name = GetHeroNameForRace(k)
                local city_center_name = GetCityCenterNameForHeroRace(hero_name)
                local building = BuildingHelper:PlaceBuilding(player, city_center_name, position)
                Players:AddStructure(playerID, building)
                Players:SetMainCityCenter(playerID, building)
                CheckAbilityRequirements( building, playerID )

                -- Create Builders in between the gold mine and the city center
                local race_setup_table = {}
                race_setup_table.builder_name = GetBuilderNameForHeroRace(hero_name)
                race_setup_table.num_builders = 5
                race_setup_table.angle = 360 / race_setup_table.num_builders
                race_setup_table.closest_mine = Gatherer:GetClosestGoldMineToPosition(position)
                race_setup_table.closest_mine_pos = race_setup_table.closest_mine:GetAbsOrigin()
                race_setup_table.mid_point = race_setup_table.closest_mine_pos + (position-race_setup_table.closest_mine_pos)/2

                -- Special spawn rules
                if k == "undead" then
                    dotacraft:InitializeUndead( hero, race_setup_table, building )
                elseif k == "nightelf" then
                    dotacraft:InitializeNightElf( hero, race_setup_table, building )
                end
                
                dotacraft:InitializeBuilders( hero, race_setup_table )
            end
        end
    end
end

function dotacraft:InitializeResources( hero, building )
    local playerID = hero:GetPlayerID()
    -- Give Initial Food
    Players:ModifyFoodLimit(playerID, GetFoodProduced(building))

    -- Give Initial Gold and Lumber
    Players:SetGold(playerID, STARTING_GOLD)
    Players:ModifyLumber(playerID, STARTING_LUMBER)
end

function dotacraft:InitializeBuilders( hero, race_setup_table )
    local playerID = hero:GetPlayerID()
    local units = Players:GetUnits(playerID)

    for i=1,race_setup_table.num_builders do    
        local rotate_pos = race_setup_table.mid_point + Vector(1,0,0) * 100
        local builder_pos = RotatePosition(race_setup_table.mid_point, QAngle(0, race_setup_table.angle*i, 0), rotate_pos)

        local builder = CreateUnitByName(race_setup_table.builder_name, builder_pos, true, hero, hero, hero:GetTeamNumber())
        builder:SetOwner(hero)
        builder:SetControllableByPlayer(playerID, true)
        Players:AddUnit(playerID, builder)
        builder.state = "idle"

        -- Increment food used
        Players:ModifyFoodUsed(playerID, GetFoodCost(builder))

        -- Go through the abilities and upgrade
        CheckAbilityRequirements( builder, playerID )
    end
end

function dotacraft:InitializeUndead( hero, race_setup_table, building )
    local playerID = hero:GetPlayerID()
    local player = hero:GetPlayerOwner()

    race_setup_table.num_builders = 3
    local ghoul = CreateUnitByName("undead_ghoul", race_setup_table.mid_point+Vector(1,0,0) * 200, true, hero, hero, hero:GetTeamNumber())
    ghoul:SetOwner(hero)
    ghoul:SetControllableByPlayer(playerID, true)
    Players:ModifyFoodUsed(playerID, GetFoodCost(ghoul))
    Players:AddUnit(playerID, ghoul)

    -- Haunt the closest gold mine
    local construction_size = BuildingHelper:GetConstructionSize("undead_haunted_gold_mine")
    local haunted_gold_mine = BuildingHelper:PlaceBuilding(player, "undead_haunted_gold_mine", race_setup_table.closest_mine_pos, construction_size, 0)
    Players:AddStructure(playerID, haunted_gold_mine)

    haunted_gold_mine.counter_particle = ParticleManager:CreateParticle("particles/custom/gold_mine_counter.vpcf", PATTACH_CUSTOMORIGIN, entangled_gold_mine)
    ParticleManager:SetParticleControl(haunted_gold_mine.counter_particle, 0, Vector(race_setup_table.closest_mine_pos.x,race_setup_table.closest_mine_pos.y,race_setup_table.closest_mine_pos.z+200))
    haunted_gold_mine.builders = {}

     -- Hide the targeted gold mine    
    ApplyModifier(race_setup_table.closest_mine, "modifier_unselectable")

    -- Create sigil prop
    local modelName = "models/props_magic/bad_sigil_ancient001.vmdl"
    haunted_gold_mine.sigil = SpawnEntityFromTableSynchronous("prop_dynamic", {model = modelName, DefaultAnim = 'bad_sigil_ancient001_rotate'})
    haunted_gold_mine.sigil:SetAbsOrigin(Vector(race_setup_table.closest_mine_pos.x, race_setup_table.closest_mine_pos.y, race_setup_table.closest_mine_pos.z-60))
    haunted_gold_mine.sigil:SetModelScale(haunted_gold_mine:GetModelScale())

    -- Create blight
    Timers:CreateTimer(function() 
        CreateBlight(haunted_gold_mine:GetAbsOrigin(), "small")
        CreateBlight(building:GetAbsOrigin(), "large")
    end)

    haunted_gold_mine.mine = race_setup_table.closest_mine -- A reference to the mine that the haunted mine is associated with
    race_setup_table.closest_mine.building_on_top = haunted_gold_mine -- A reference to the building that haunts this gold mine]]
end

function dotacraft:InitializeNightElf( hero, race_setup_table, building )
    local playerID = hero:GetPlayerID()
    local player = hero:GetPlayerOwner()

    -- Apply rooted particles
    local uproot_ability = building:FindAbilityByName("nightelf_uproot")
    uproot_ability:ApplyDataDrivenModifier(building, building, "modifier_rooted_ancient", {})
    
    -- Entangle the closest gold mine
    local construction_size = BuildingHelper:GetConstructionSize("nightelf_entangled_gold_mine")
    local entangled_gold_mine = BuildingHelper:PlaceBuilding(player, "nightelf_entangled_gold_mine", race_setup_table.closest_mine_pos, construction_size, 0, angle)
    entangled_gold_mine:SetForwardVector(race_setup_table.closest_mine:GetForwardVector())
    Players:AddStructure(playerID, entangled_gold_mine)

    entangled_gold_mine:SetOwner(hero)
    entangled_gold_mine:SetControllableByPlayer(playerID, true)
    entangled_gold_mine.counter_particle = ParticleManager:CreateParticle("particles/custom/gold_mine_counter.vpcf", PATTACH_CUSTOMORIGIN, entangled_gold_mine)
    ParticleManager:SetParticleControl(entangled_gold_mine.counter_particle, 0, Vector(race_setup_table.closest_mine_pos.x,race_setup_table.closest_mine_pos.y,race_setup_table.closest_mine_pos.z+200))
    entangled_gold_mine.builders = {}

    entangled_gold_mine.mine = race_setup_table.closest_mine -- A reference to the mine that the entangled mine is associated with
    entangled_gold_mine.city_center = building -- A reference to the city center that entangles this mine
    building.entangled_gold_mine = entangled_gold_mine -- A reference to the entangled building of the city center
    race_setup_table.closest_mine.building_on_top = entangled_gold_mine -- A reference to the building that entangles this gold mine

     -- Hide the targeted gold mine    
    ApplyModifier(race_setup_table.closest_mine, "modifier_unselectable")

    building:SwapAbilities("nightelf_entangle_gold_mine", "nightelf_entangle_gold_mine_passive", false, true)
end

function dotacraft:InitializeTownHall( hero, position, building )
    local player = hero:GetPlayerOwner()
    local playerID = hero:GetPlayerID()

    -- Hide main hero under the main base
    local ability = hero:FindAbilityByName("hide_hero")
    ability:UpgradeAbility(true)
    hero:SetAbilityPoints(0)
    hero:SetAbsOrigin(Vector(position.x,position.y,position.z - 420 ))
    Timers:CreateTimer(function() hero:SetAbsOrigin(Vector(position.x,position.y,position.z - 420 )) return 1 end)
    hero:AddNoDraw()

    -- Snap the camera to the created building and add it to selection
    for i=1,15 do
        Timers:CreateTimer(i*0.03, function()
            PlayerResource:SetCameraTarget(playerID, hero)
        end)
    end

    Timers:CreateTimer(0.5, function()
        PlayerResource:SetCameraTarget(playerID, nil)
        PlayerResource:NewSelection(playerID, building)
    end)

    -- Find neutrals near the starting zone and remove them
    local neutrals = FindUnitsInRadius(hero:GetTeamNumber(), position, nil, 600, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, true)
    for k,v in pairs(neutrals) do
        if v:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
            v:RemoveSelf()
        end
    end
end

function dotacraft:OnGameInProgress()
    print("[DOTACRAFT] The game has officially begun")

    -- Setup shops (Tavern, Mercenary, Goblin Merchant and Lab)
    local shops = Entities:FindAllByName("*shop*")
    for k,v in pairs(shops) do
        if v.AddAbility then
          TeachAbility(v,"ability_shop")
        end
    end

    -- Setup easy/medium/hard minimap icons
    Minimap:InitializeCampIcons()

    GameRules.DayTime = true
    Timers:CreateTimer(240, function() 
        if GameRules.DayTime then
            LightsOut()
        else
            RiseAndShine()
        end
        return 240
    end)
end

-- Creeps go into sleep mode
function LightsOut()
    print("[DOTACRAFT] Night Time")
    GameRules.DayTime = false
end

-- Wake up creeps
function RiseAndShine()
    print("[DOTACRAFT] Day Time")
    GameRules.DayTime = true
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

gamestates =
{
    [0] = "DOTA_GAMERULES_STATE_INIT",
    [1] = "DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD",
    [2] = "DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP",
    [3] = "DOTA_GAMERULES_STATE_HERO_SELECTION",
    [4] = "DOTA_GAMERULES_STATE_STRATEGY_TIME",
    [5] = "DOTA_GAMERULES_STATE_TEAM_SHOWCASE",
    [6] = "DOTA_GAMERULES_STATE_PRE_GAME",
    [7] = "DOTA_GAMERULES_STATE_GAME_IN_PROGRESS",
    [8] = "DOTA_GAMERULES_STATE_POST_GAME",
    [9] = "DOTA_GAMERULES_STATE_DISCONNECT"
}

-- The overall game state has changed
function dotacraft:OnGameRulesStateChange(keys)
    local newState = GameRules:State_Get()

    print("[DOTACRAFT] GameRules State Changed: ",gamestates[newState])
        
    -- send the panaroma developer at each stage to ensure all js are exposed to it
    dotacraft:PanaromaDeveloperMode(newState)
    
    if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
        if PlayerResource:HaveAllPlayersJoined() then
            dotacraft:OnAllPlayersLoaded()
        end
    elseif newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        Scores:Init() -- Start score tracking for all players
    elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        dotacraft:OnGameInProgress()
    elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
        dotacraft:OnPreGame()
    end
end

-- An NPC has spawned somewhere in game.  This includes heroes
function dotacraft:OnNPCSpawned(keys)
    --print("[DOTACRAFT] NPC Spawned")
    --DeepPrintTable(keys)
    local npc = EntIndexToHScript(keys.entindex)

    -- Ignore specific units
    local unitName = npc:GetUnitName()
    if unitName == "npc_dota_hero_treant" then return end
    if unitName == "npc_dota_thinker" then return end
    if unitName == "" then return end

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

    Units:Init(npc)
end

-- An entity somewhere has been hurt.
function dotacraft:OnEntityHurt(keys)
    --print("[DOTACRAFT] Entity Hurt")
    ----DeepPrintTable(keys)
    local damagebits = keys.damagebits
    local attacker = keys.entindex_attacker
    local damaged = keys.entindex_killed
    local inflictor = keys.entindex_inflictor
    local victim
    local cause
    local damagingAbility

    if attacker and damaged then
        cause = EntIndexToHScript(keys.entindex_attacker)
        victim = EntIndexToHScript(keys.entindex_killed)        
        
        if inflictor then
            damagingAbility = EntIndexToHScript( keys.entindex_inflictor )
        end
    end

    -- Cheat code host only
    if GameRules.WhosYourDaddy and victim and attacker then
        local attackerID = cause:GetPlayerOwnerID()
        if attackerID == 0 then
            victim:Kill(nil, cause)
        end
    end

    local time = GameRules:GetGameTime()
    if victim and IsCustomBuilding(victim) then
        local pID = victim:GetPlayerOwnerID()
        if pID then
            -- Set the new attack time
            GameRules.PLAYER_BUILDINGS_DAMAGED[pID] = time  

            -- Define the warning 
            local last_warning = GameRules.PLAYER_DAMAGE_WARNING[pID]

            -- If its the first time being attacked or its been long since the last warning, show a warning
            if not last_warning or (time - last_warning) > UNDER_ATTACK_WARNING_INTERVAL then

                -- Damage Particle
                local particle = ParticleManager:CreateParticleForPlayer("particles/generic_gameplay/screen_damage_indicator.vpcf", PATTACH_EYES_FOLLOW, victim, victim:GetPlayerOwner())
                ParticleManager:SetParticleControl(particle, 1, victim:GetAbsOrigin())
                Timers:CreateTimer(3, function() ParticleManager:DestroyParticle(particle, false) end)

                -- Ping
                local origin = victim:GetAbsOrigin()
                MinimapEvent( victim:GetTeamNumber(), victim, origin.x, origin.y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 1 )
                MinimapEvent( victim:GetTeamNumber(), victim, origin.x, origin.y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, 3 )

                -- Update the last warning to the current time
                GameRules.PLAYER_DAMAGE_WARNING[pID] = time
            else
                -- Ping on each building, every 2 seconds at most
                local last_damaged = victim.last_damaged
                if not last_damaged or (time - last_damaged) > 2 then
                    victim.last_damaged = time
                    local origin = victim:GetAbsOrigin()
                    MinimapEvent( victim:GetTeamNumber(), victim, origin.x, origin.y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, 2 )
                end
            end
        end
    end



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
    local player = PlayerResource:GetPlayer(keys.PlayerID)
    local playerHero = player:GetAssignedHero()
    
    
    -- re-create js hero panels for player
    local heroes = playerHero.heroes
    for _,hero in pairs(heroes) do
        CreateHeroPanel(hero)
    end
    
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

-- A tree was cut down
function dotacraft:OnTreeCut(keys)
    print ('[DOTACRAFT] OnTreeCut')

    local treeX = keys.tree_x
    local treeY = keys.tree_y
    local treePos = Vector(treeX,treeY,0)
    
    -- Check for Night Elf Sentinels and Wisps
    local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, treePos, nil, 64, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, 0, FIND_ANY_ORDER, false)
    for _,v in pairs(units) do
        local unit_name = v:GetUnitName()
        if unit_name == "nightelf_sentinel_owl" then
            v:ForceKill(false)
        elseif unit_name == "nightelf_wisp" then
            local gather_ability = v:FindAbilityByName("nightelf_gather")
            v:RemoveModifierByName("modifier_gathering_lumber")
            v.state = "idle"
            v:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
            ToggleOff(gather_ability)
        end
    end
end

-- A player picked a hero
function dotacraft:OnPlayerPickHero(keys)
    print ('[DOTACRAFT] OnPlayerPickHero')
    --DeepPrintTable(keys)
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

    local killed = EntIndexToHScript(event.entindex_killed)
    local attacker
    if event.entindex_attacker then
        attacker = EntIndexToHScript(event.entindex_attacker)
    end

    -- Safeguard
    if killed.reincarnating then return end
    if killed.upgraded then return end

    -- Killed credentials
    local killed_player = killed:GetPlayerOwner()
    local killed_playerID = killed:GetPlayerOwnerID()
    local killed_teamNumber = killed:GetTeamNumber()
    local killed_hero = PlayerResource:GetSelectedHeroEntity(killed_playerID)

    -- Attacker credentials
    local attacker_player = attacker and attacker:GetPlayerOwner()
    local attacker_playerID = attacker and attacker:GetPlayerOwnerID()
    local attacker_teamNumber = attacker and attacker:GetTeamNumber()
    local attacker_hero = attacker_playerID and PlayerResource:GetSelectedHeroEntity(attacker_playerID)

    -- Check for neutral item drops
    if killed_teamNumber == DOTA_TEAM_NEUTRALS and killed:IsCreature() then
        DropItems( killed )

        if attacker_playerID then
            Scores:IncrementItemsObtained( attacker_playerID )
        end
    end

    -- Remove dead units from selection group
    PlayerResource:RemoveFromSelection(killed_playerID, killed)

    -- Hero Killed
    if killed:IsRealHero() then
        print("A Hero was killed")
        
        -- add hero to tavern, this function also works out cost etc
        unit_shops:AddHeroToTavern(killed)
        
        if Players:HasAltar(killed_playerID) then

            local playerAltars = Players:GetAltars(killed_playerID)
            print("Player has "..#playerAltars.." valid altars")
            for _,altar in pairs(playerAltars) do
                -- Set the strings for the _acquired ability to find and _revival ability to add
                local level = killed:GetLevel()
                local name = killed.RespawnAbility

                print("ALLOW REVIVAL OF THIS THIS HERO AT THIS ALTAR - Ability: ",name)

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
                            print("ABILITY COULDNT BE CHANGED BECAUSE NO "..revival_ability_name.." WAS FOUND ON THIS ALTAR")
                        end
                    else
                        -- The ability couldn't be found (a neutral hero), add it
                        print("ABILITY COULDNT BE CHANGED BECAUSE NO "..acquired_ability_name.." WAS FOUND ON THIS ALTAR")

                    end
                end
            end
        
        else
            print("Hero Killed but player doesn't have an altar to revive it")
        end
    end
    
    -- Building Killed
    if IsCustomBuilding(killed) then

        -- Cleanup building tables
        Players:RemoveStructure( killed_playerID, killed )
        killed:AddNoDraw()

        if attacker_playerID and attacker_playerID ~= -1 and attacker_playerID ~= killed_playerID then
            Scores:IncrementBuildingsRazed( attacker_playerID, killed )
        end

        if killed:GetUnitName() == "haunted_gold_mine" then
            if IsValidEntity(killed.sigil) then
                killed.sigil:RemoveSelf()
            end
        end

        -- Substract the Food Produced
        local food_produced = GetFoodProduced(killed)
        if food_produced ~= 0 and killed.state ~= "canceled" then
            Players:ModifyFoodLimit(killed_playerID, - food_produced)
        end

        -- Check units and structures for downgrades
        local playerUnits = Players:GetUnits( killed_playerID )
        for k,unit in pairs(playerUnits) do
            CheckAbilityRequirements( unit, killed_playerID )
        end

        local playerStructures = Players:GetStructures( killed_playerID )
        for k,structure in pairs(playerStructures) do
            CheckAbilityRequirements( structure, killed_playerID )
        end

        -- If the destroyed building was a city center, update the level
        if IsCityCenter(killed) then
            Players:CheckCurrentCityCenters(killed_playerID)
        end

        -- Check for lose condition - All buildings destroyed
        print("Player "..killed_playerID.." has "..#playerStructures.." buildings left")
        if (#playerStructures == 0) then
            dotacraft:CheckDefeatCondition(killed_teamNumber)
        end
    
    -- Unit Killed (Hero or Creature)
    else
        if not attacker then return end

        -- Skip corpses
        if killed.corpse_expiration then return end

        -- CLeanup unit table
        if killed_hero then
            Players:RemoveUnit( killed_playerID, killed )
        end

        if attacker_playerID and attacker_playerID ~= -1 then
            print(attacker_playerID)
            if killed:IsRealHero() then
                Scores:IncrementHeroesKilled( attacker_playerID, killed )
            elseif killed:IsCreature() then
                Scores:IncrementUnitsKilled( attacker_playerID, killed )
            end
        end

        -- Give Experience to heroes based on the level of the killed creature
        local XPGain = XP_BOUNTY_TABLE[killed:GetLevel()]

        -- Grant XP in AoE
        local heroesNearby = FindUnitsInRadius( attacker:GetTeamNumber(), killed:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
        --print("There are ",#heroesNearby," nearby the dead unit, base value for this unit is: "..XPGain)
        for _,hero in pairs(heroesNearby) do
            if hero:IsRealHero() and hero:GetTeam() ~= killed:GetTeam() then

                -- Scale XP if neutral
                local xp = XPGain
                if killed:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
                    xp = math.floor(( XPGain * XP_NEUTRAL_SCALING[hero:GetLevel()] ) / #heroesNearby)
                end

                hero:AddExperience(xp, false, false)

                Scores:IncrementXPGained( playerID, xp )
                --print("granted "..xp.." to "..hero:GetUnitName())
            end 
        end

        -- Substract the Food Used
        local food_cost = GetFoodCost(killed)
        if killed_hero and food_cost > 0 then
            Players:ModifyFoodUsed(killed_playerID, - food_cost)
        end
    end

    -- If the unit is supposed to leave a corpse, create a dummy_unit to use abilities on it.
    Timers:CreateTimer(1, function() 
    if LeavesCorpse( killed ) then
            -- Create and set model
            local corpse = CreateUnitByName("dummy_unit", killed:GetAbsOrigin(), true, nil, nil, killed:GetTeamNumber())
            corpse:SetModel(CORPSE_MODEL)

            -- Set the corpse invisible until the dota corpse disappears
            corpse:AddNoDraw()
            
            -- Keep a reference to its name and expire time
            corpse.corpse_expiration = GameRules:GetGameTime() + CORPSE_DURATION
            corpse.unit_name = killed:GetUnitName()

            -- Set custom corpse visible
            Timers:CreateTimer(3, function() if IsValidEntity(corpse) then corpse:RemoveNoDraw() end end)

            -- Remove itself after the corpse duration
            Timers:CreateTimer(CORPSE_DURATION, function()
                if corpse and IsValidEntity(corpse) then
                    corpse:RemoveSelf()
                end
            end)
        end
    end)
end

-- Hides or shows the rally flag particles for the player (avoids visual clutter)
function dotacraft:UpdateRallyFlagDisplays( playerID )
    local player = PlayerResource:GetPlayer(playerID)
    local units = PlayerResource:GetSelectedEntities(playerID)

    Players:ClearPlayerFlags(playerID)

    for k,v in pairs(units) do
        local building = EntIndexToHScript(v)
        if IsValidAlive(building) and IsCustomBuilding(building) and not IsCustomTower(building) then
            CreateRallyFlagForBuilding( building )
        end
    end
end

function dotacraft:MakePlayerLose( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local playerStructures = Players:GetStructures(playerID)
    for k,v in pairs(playerStructures) do
        if IsValidAlive(v) then
            v:Kill(nil, hero)
        end
    end
    hero.structures = {}

    dotacraft:CheckDefeatCondition( hero:GetTeamNumber() )
end

-- Whenever a building is destroyed and the player structures hit 0, check for defeat & win condition
-- In team games, teams are defeated as a whole instead of each player (because of resource trading and other shenanigans)
-- Defeat condition: All players of the same team have 0 buildings
-- Win condition: All teams have been defeated but one (i.e. there are only structures left standing for players of the same team)
function dotacraft:CheckDefeatCondition( teamNumber )

    --SetNetTableValue("dotacraft_player_table", tostring(player:GetPlayerID()), {Status = "defeated"})

    -- Check the player structures of all the members of that team to determine defeat
    local teamMembers = 0
    local defeatedTeamMembers = 0
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            local player = PlayerResource:GetPlayer(playerID)
            if player:GetTeamNumber() == teamNumber then
                teamMembers = teamMembers + 1
                local playerStructures = Players:GetStructures(playerID)
                if #playerStructures == 0 then
                    defeatedTeamMembers = defeatedTeamMembers + 1
                end
            end         
        end
    end

    print("CheckDefeatCondition: There are ["..teamMembers.."] players in Team "..teamNumber.." and ["..defeatedTeamMembers.."] without structures left standing")
    
    if defeatedTeamMembers == teamMembers then
        print("All players of team "..teamNumber.." are defeated")
        GameRules.DefeatedTeamCount = GameRules.DefeatedTeamCount + 1
        dotacraft:PrintDefeateMessageForTeam( teamNumber )
    end

    -- Victory: Only 1 team left standing
    local teamCount = dotacraft:GetTeamCount()
    print("Team Count: "..teamCount,"Defeated Teams: "..GameRules.DefeatedTeamCount)

    if GameRules.DefeatedTeamCount+1 >= teamCount then
        local winningTeam = dotacraft:GetWinningTeam() or DOTA_TEAM_NEUTRALS
        print("Winning Team: ",winningTeam)
        dotacraft:PrintWinMessageForTeam(winningTeam)

        -- Revert client convars
        for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
            if PlayerResource:IsValidPlayerID(playerID) then
                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                hero:RemoveModifierByName("modifier_client_convars")
            end
        end

        GameRules:SetGameWinner(winningTeam)
    end

end

-- Returns an Int with the number of teams with valid players in them
function dotacraft:GetTeamCount()
    local teamCount = 0
    for i=DOTA_TEAM_FIRST,DOTA_TEAM_CUSTOM_MAX do
        local playerCount = PlayerResource:GetPlayerCountForTeam(i)
        if playerCount > 0 then
            teamCount = teamCount + 1
            print("  Team ["..i.."] has "..playerCount.." players")
        end
    end
    return teamCount
end

-- This should only be called when all teams but one are defeated
-- Returns the first player with a building left standing
function dotacraft:GetWinningTeam()
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            local player = PlayerResource:GetPlayer(playerID)
            local playerStructures = Players:GetStructures( playerID )
            if #playerStructures > 0 then
                return player:GetTeamNumber()
            end
        end
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

function dotacraft:FilterProjectile( filterTable )
    local attacker_index = filterTable["entindex_source_const"]
    local victim_index = filterTable["entindex_target_const"]

    if not victim_index or not attacker_index then
        return true
    end

    local victim = EntIndexToHScript( victim_index )
    local attacker = EntIndexToHScript( attacker_index )
    local is_attack = tobool(filterTable["is_attack"])
    local move_speed = filterTable["move_speed"]

    if is_attack and HasArtilleryAttack(attacker) then
        AttackGroundPos(attacker, victim:GetAbsOrigin(), move_speed)
        return false
    end

    return true
end