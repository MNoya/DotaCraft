print ('[DOTACRAFT] dotacraft.lua' )
--[[
    dota_launch_custom_game dotacraft echo_isles
    dota_launch_custom_game dotacraft hills_of_glory
]]

DISABLE_FOG_OF_WAR_ENTIRELY = false
UNSEEN_FOG_ENABLED = false

UNDER_ATTACK_WARNING_INTERVAL = 60

STARTING_GOLD = 500
STARTING_LUMBER = 150

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

    -- Modifier Applier
    GameRules.Applier = CreateItem("item_apply_modifiers", nil, nil)

    -- Event Hooks
    ListenToGameEvent('entity_killed', Dynamic_Wrap(dotacraft, 'OnEntityKilled'), self)
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(dotacraft, 'OnConnectFull'), self)
    ListenToGameEvent('player_connect', Dynamic_Wrap(dotacraft, 'PlayerConnect'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(dotacraft, 'OnNPCSpawned'), self)
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(dotacraft, 'OnGameRulesStateChange'), self)
    ListenToGameEvent('entity_hurt', Dynamic_Wrap(dotacraft, 'OnEntityHurt'), self)
    ListenToGameEvent('tree_cut', Dynamic_Wrap(dotacraft, 'OnTreeCut'), self)
    ListenToGameEvent('player_chat', Dynamic_Wrap(dotacraft, 'OnPlayerChat'), self)

    -- Filters
    GameMode:SetExecuteOrderFilter( Dynamic_Wrap( dotacraft, "FilterExecuteOrder" ), self )
    GameMode:SetDamageFilter( Dynamic_Wrap( dotacraft, "FilterDamage" ), self )
    GameMode:SetTrackingProjectileFilter( Dynamic_Wrap( dotacraft, "FilterProjectile" ), self )
    GameMode:SetModifyExperienceFilter( Dynamic_Wrap( dotacraft, "FilterExperience" ), self )
    GameMode:SetModifyGoldFilter( Dynamic_Wrap( dotacraft, "FilterGold" ), self )
    GameMode:SetModifierGainedFilter( Dynamic_Wrap(dotacraft, "FilterModifier"), self )
    GameMode:SetItemAddedToInventoryFilter( Dynamic_Wrap(dotacraft, "FilterItemAdded"), self )

    -- Panorama listeners
    CustomGameEventManager:RegisterListener( "selection_update", Dynamic_Wrap(dotacraft, 'OnPlayerSelectedEntities'))
    CustomGameEventManager:RegisterListener( "moonwell_order", Dynamic_Wrap(dotacraft, "MoonWellOrder")) --Right click through panorama
    CustomGameEventManager:RegisterListener( "burrow_order", Dynamic_Wrap(dotacraft, "BurrowOrder")) --Right click through panorama 
    CustomGameEventManager:RegisterListener( "shop_active_order", Dynamic_Wrap(dotacraft, "ShopActiveOrder")) --Right click through panorama 
    CustomGameEventManager:RegisterListener( "building_rally_order", Dynamic_Wrap(dotacraft, "OnBuildingRallyOrder")) --Right click through panorama
    
    -- Lua Modifiers
    LinkLuaModifier("modifier_hex_frog", "libraries/modifiers/modifier_hex", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_hex_sheep", "libraries/modifiers/modifier_hex", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_model_scale", "libraries/modifiers/modifier_model_scale", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_client_convars", "libraries/modifiers/modifier_client_convars", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_summoned", "libraries/modifiers/modifier_summoned", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_flying_control", "libraries/modifiers/modifier_flying_control", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_animation_freeze", "libraries/modifiers/modifier_animation_freeze", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_autoattack", "units/attack_modifiers", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_autoattack_passive", "units/attack_modifiers", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_druid_bear_model", "units/nightelf/modifier_druid_model", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_druid_crow_model", "units/nightelf/modifier_druid_model", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_crypt_fiend_burrow_model", "units/undead/modifier_crypt_fiend_burrow_model", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_bloodlust", "units/orc/modifier_bloodlust", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_healing_ward", "items/wards", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_sentry_ward", "items/wards", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_true_sight_aura", "libraries/modifiers/modifier_true_sight_aura", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_ethereal", "libraries/modifiers/modifier_ethereal", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_demon_form", "heroes/demon_hunter/demon_form", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_robot_form", "heroes/tinker/robo_goblin", LUA_MODIFIER_MOTION_NONE)

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

    -- Attack net table
    Attacks:Init()

    -- Panorama Developer setting
    CustomNetTables:SetTableValue("dotacraft_settings","developer",{value=IsInToolsMode()})

    print('[DOTACRAFT] Done loading dotacraft gamemode!')
end

function dotacraft:LoadKV()
    GameRules.Requirements = LoadKeyValues("scripts/kv/tech_tree.kv")
    GameRules.Wearables = LoadKeyValues("scripts/kv/wearables.kv")
    GameRules.UnitUpgrades = LoadKeyValues("scripts/kv/unit_upgrades.kv")
    GameRules.Abilities = LoadKeyValues("scripts/kv/abilities.kv")
    GameRules.Damage = LoadKeyValues("scripts/kv/damage_table.kv")
end

function dotacraft:OnScriptReload()
    SendToConsole("cl_script_reload")
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
    local position = Teams:GetPositionForPlayer(playerID)
    local city_center_name = Players:GetCityCenterName(playerID)
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
    race_setup_table.builder_name = Players:GetBuilderName(playerID)
    race_setup_table.num_builders = Players:GetNumInitialBuilders(playerID)
    race_setup_table.angle = 360 / race_setup_table.num_builders
    race_setup_table.closest_mine = Gatherer:GetClosestGoldMineToPosition(position)
    race_setup_table.closest_mine_pos = race_setup_table.closest_mine:GetAbsOrigin()
    race_setup_table.mid_point = race_setup_table.closest_mine_pos + (position-race_setup_table.closest_mine_pos)/2

    -- Find neutrals near the starting zone and remove them
    local neutrals = FindUnitsInRadius(hero:GetTeamNumber(), position, nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, true)
    for k,v in pairs(neutrals) do
        if v:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not v:GetUnitName():match("minimap_") then
            v:RemoveSelf()
        end
    end

    -- Special spawn rules
    local race = hero:GetRace()
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
    dotacraft:InitializeTownHall( hero , position, building )

    -- Test options
    if Convars:GetBool("developer") then
        dotacraft:DeveloperMode(player)
    end

    -- Show UI elements for this race
    CustomGameEventManager:Send_ServerToPlayer(player, "player_show_ui", {race = race, initial_builders = num_builders})

    -- Keep track of the Idle Builders and send them to the panorama UI every time the count updates
    dotacraft:TrackIdleWorkers( hero )

    -- Toggle Autocast as a group
    dotacraft:AutoCastTimer(hero)

    --------------------------------------------
    -- Test game logic on the model overview map
    if GetMapName() == "1_dotacraft" then
        
        local races = {['human']=0,['orc']=0,['nightelf']=0,['undead']=0}
        races[race] = 1 -- Skip the picked race
        local startID = playerID
        for k,v in pairs(races) do
            if v == 0 then
                startID = startID + 1
                local position = Teams:GetPositionForPlayer(startID)
                local hero_name = Units:GetBaseHeroNameForRace(k)
                local city_center_name = Units:GetCityCenterNameForRace(k)
                local building = BuildingHelper:PlaceBuilding(player, city_center_name, position)
                Players:AddStructure(playerID, building)
                CheckAbilityRequirements( building, playerID )

                -- Create Builders in between the gold mine and the city center
                local race_setup_table = {}
                race_setup_table.builder_name = Units:GetBuilderNameForRace(k)
                race_setup_table.num_builders = Units:GetNumInitialBuildersForRace(k)
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

function dotacraft:TrackIdleWorkers( hero )
    local player = hero:GetPlayerOwner()
    local playerID = hero:GetPlayerID()
    -- Keep track of the Idle Builders and send them to the panorama UI every time the count updates
    Timers:CreateTimer(1, function() 
        local idle_builders = {}
        local playerUnits = Players:GetUnits(playerID)
        for k,unit in pairs(playerUnits) do
            if IsValidAlive(unit) and IsBuilder(unit) and IsIdleBuilder(unit) then
                table.insert(idle_builders, unit:GetEntityIndex())
            end
        end
        if #idle_builders ~= #hero.idle_builders then
            --print("#Idle Builders changed: "..#idle_builders..", was "..#hero.idle_builders)
            hero.idle_builders = idle_builders
            CustomGameEventManager:Send_ServerToPlayer(player, "player_update_idle_builders", { idle_builder_entities = idle_builders })
        end
        return 0.3
    end)
end

function dotacraft:AutoCastTimer(hero)
    local playerID = hero:GetPlayerID()
    Timers:CreateTimer(0.1, function()
        local selectedEntities = PlayerResource:GetSelectedEntities(playerID)
        if selectedEntities["0"] then
            local unit = EntIndexToHScript(selectedEntities["0"])
            if IsValidAlive(unit) then

                -- Check autocast abilities and their last state to toggle as a group
                for i=0,15 do
                    local ability = unit:GetAbilityByIndex(i)
                    if ability and ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_AUTOCAST) then
                        local state = ability:GetAutoCastState()
                        if not ability.last_autocast_state then
                            ability.last_autocast_state = state
                            if state then
                                GroupToggleAutoCast(selectedEntities, unit, ability:GetAbilityName(), state)
                            end
                        elseif ability.last_autocast_state ~= state then
                            ability.last_autocast_state = state
                            GroupToggleAutoCast(selectedEntities, unit, ability:GetAbilityName(), state)
                        end
                    end
                end
            end
        end

        return 0.1
    end)
end

-- Goes through all units in the group, setting the same autocast state on the passed ability
function GroupToggleAutoCast(entityList, mainUnit, abilityName, state)
    local unitName = mainUnit:GetUnitName()
    for _,entIndex in pairs(entityList) do
        local unit = EntIndexToHScript(entIndex)
        if unit ~= mainUnit and IsValidAlive(unit) and unit:GetUnitName() == unitName then
            for i=0,15 do
                local ability = unit:GetAbilityByIndex(i)
                if ability and ability:GetAbilityName() == abilityName then
                    if ability:GetAutoCastState() ~= state then
                        ability:ToggleAutoCast()
                    end
                end
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
        Blight:Create(haunted_gold_mine, "small")
        Blight:Create(building, "large")
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
        PlayerResource:SetDefaultSelectionEntity(playerID, building)
    end)
end

function dotacraft:OnGameInProgress()
    print("[DOTACRAFT] The game has officially begun")

    -- Setup shops (Tavern, Mercenary, Goblin Merchant and Lab)
    local shops = Entities:FindAllByName("*shop*")
    for k,v in pairs(shops) do
        if v.AddAbility then
            local origin = v:GetAbsOrigin()
            local name = v:GetUnitName()
            local construction_size = BuildingHelper:GetConstructionSize(name)
            BuildingHelper:SnapToGrid(construction_size, origin)
            BuildingHelper:BlockGridSquares(construction_size, BuildingHelper:GetBlockPathingSize(name), origin)
            v:SetAbsOrigin(GetGroundPosition(origin,v))
            v:AddNewModifier(v,nil,"modifier_building",{})
            TeachAbility(v,"ability_shop")
            for _,teamID in pairs(Teams:GetValidTeams()) do
                AddFOWViewer(teamID,origin,10,3,false)
            end
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
    UI:GameStateManager(newState) -- ui game state manager
    if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
        if PlayerResource:HaveAllPlayersJoined() then
            dotacraft:OnAllPlayersLoaded()
        end
    elseif newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        Scores:Init() -- Start score tracking for all players
    elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
        dotacraft:OnPreGame()
    elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        dotacraft:OnGameInProgress()
    end
end

function dotacraft:OnPreGame()
    print("[DOTACRAFT] OnPreGame")
    Teams:DetermineStartingPositions()
    Minimap:PrepareCamps()
    
    local maxPlayers = dotacraft:GetMapMaxPlayers()
    for playerID = 0, maxPlayers do
        local playerTable = CustomNetTables:GetTableValue("dotacraft_pregame_table", tostring(playerID))
        if Players:IsValidNetTablePlayer(playerTable) then
            local color = playerTable.Color
            local team = Teams:GetNthTeamID(playerTable.Team)
            local race = GameRules.raceTable[playerTable.Race] or GameRules.raceTable[RandomInt(1, 4)]
            local PlayerColor = CustomNetTables:GetTableValue("dotacraft_color_table", tostring(color))

            PlayerResource:SetCustomPlayerColor(playerID, PlayerColor.r, PlayerColor.g, PlayerColor.b)
            PlayerResource:SetCustomTeamAssignment(playerID, team)
            
            if PlayerResource:IsValidPlayerID(playerID) then
                --Race Heroes are already precached
                local player = PlayerResource:GetPlayer(playerID)
                local hero = CreateHeroForPlayer(race, player)
                hero.color_id = color
                
                print("[DOTACRAFT] CreateHeroForPlayer: ",playerID,race,team)
            else
                Tutorial:AddBot(race,'','',false)

                Timers(2, function()
                    if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:IsFakeClient(playerID) then
                        if PlayerResource:GetSelectedHeroEntity(playerID) then
                            -- Init AI
                            print("[DOTACRAFT] Bot Created: ",playerID,race,team)
                        else
                            local player = PlayerResource:GetPlayer(playerID)
                            if player then
                                CreateHeroForPlayer(race, player)
                            end
                            return 0.1
                        end
                    end
                end)
            end
        end
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
        gold_mine:AddNewModifier(gold_mine,nil,"modifier_building",{})

        local gridNavBlockers = BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)
        BuildingHelper:AddGridType(construction_size, location, "GoldMine")
        gold_mine:SetAbsOrigin(location)
        gold_mine.blockers = gridNavBlockers

        -- Find and store the mine entrance
        local mine_entrance = Entities:FindAllByNameWithin("*mine_entrance", location, 300)
        for k,v in pairs(mine_entrance) do
            gold_mine.entrance = v:GetAbsOrigin()
        end

        -- Show gold mines (networks the entity to all clients)
        for _,teamID in pairs(Teams:GetValidTeams()) do
            AddFOWViewer(teamID,gold_mine:GetAbsOrigin(),10,3,false)
        end

        -- Find and store the mine light
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
    if unitName == "npc_dota_units_base" then return end
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

    Timers:CreateTimer(0.03, function()
        player:SetKillCamUnit(nil)
    end)   
    
    UI:HandlePlayerReconnect(player)
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
        end
    end
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

    if killed:IsRealHero() then
        local player = PlayerResource:GetPlayer(killed_playerID)
        if player then
            Timers:CreateTimer(0.03, function()
                player:SetKillCamUnit(nil)
            end)
        end
    end

    -- Don't leave corpses if the target was killed by an aoe splash
    if IsValidEntity(attacker) and attacker:HasArtilleryAttack() then
        killed:SetNoCorpse()
        killed:AddNoDraw()
        local particle = ParticleManager:CreateParticle("particles/custom/effects/corpse_blood_explosion.vpcf",PATTACH_CUSTOMORIGIN,nil)
        ParticleManager:SetParticleControl(particle,0,killed:GetAbsOrigin())
    end

    -- Check for neutral item drops
    if killed_teamNumber == DOTA_TEAM_NEUTRALS and killed:IsCreature() and not IsCustomBuilding(killed) then
        Drops:Roll(killed)

        if attacker_playerID then
            Scores:IncrementItemsObtained( attacker_playerID )
        end
    end

    -- Remove dead units from selection group
    PlayerResource:RemoveFromSelection(killed_playerID, killed)

    -- Hero Killed
    if killed:IsRealHero() and killed_playerID ~= -1 then
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

    -- Remove blight area
    if killed:HasModifier("modifier_grid_blight") then
        Blight:Remove(killed)
    end
    
    -- Building Killed
    if IsCustomBuilding(killed) and killed_teamNumber ~= DOTA_TEAM_NEUTRALS then

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
            if killed:IsRealHero() then
                Scores:IncrementHeroesKilled( attacker_playerID, killed )
            elseif killed:IsCreature() then
                Scores:IncrementUnitsKilled( attacker_playerID, killed )
            end
        end     

        -- Substract the Food Used
        local food_cost = GetFoodCost(killed)
        if killed_hero and food_cost > 0 then
            Players:ModifyFoodUsed(killed_playerID, - food_cost)
        end
    end

    -- Give Experience to heroes based on the level of the killed creature
    Heroes:DistributeXP(killed, attacker)   

    -- If the unit is supposed to leave a corpse, create a dummy_unit to use abilities on it.
    Corpses:CreateFromUnit(killed)
end

function dotacraft:OnPlayerSelectedEntities( event )
    local playerID = event.PlayerID
    dotacraft:UpdateRallyFlagDisplays(playerID)
end

-- Hides or shows the rally flag particles for the player (avoids visual clutter)
function dotacraft:UpdateRallyFlagDisplays( playerID )
    local player = PlayerResource:GetPlayer(playerID)
    local units = PlayerResource:GetSelectedEntities(playerID)

    Players:ClearPlayerFlags(playerID)

    for k,v in pairs(units) do
        local building = EntIndexToHScript(v)
        if IsValidAlive(building) and IsCustomBuilding(building) and HasRallyPoint(building) then
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

    --CustomNetTables:SetTableValue("dotacraft_player_table", tostring(player:GetPlayerID()), {Status = "defeated"})

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
    local teamCount = #Teams:GetValidTeams()
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

-- Returns a Vector with the color of the player
function dotacraft:ColorForPlayer( playerID )
    local Player_Table = CustomNetTables:GetTableValue(GameRules.UI_PLAYERTABLE, tostring(playerID))
    local color = CustomNetTables:GetTableValue(GameRules.UI_COLORTABLE, tostring(Player_Table.color_id))
    return Vector(color.r, color.g, color.b)
end

function dotacraft:ColorForTeam(teamID)
    local color = TEAM_COLORS[teamID]
    return Vector(color[1], color[2], color[3])
end

function dotacraft:GetMapName()
    local cutMap = string.find(GetMapName(), '_', 1, true)
    if not cutMap then
        print("ERROR: Map name should follow the naming format X_mapname, got '"..GetMapName().."' instead")
        return
    end
    return string.sub(GetMapName(), cutMap+1)
end

function dotacraft:GetMapMaxPlayers()
    return split(GetMapName(), '_')[1]
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

------------------------------------------------------------------
--                      Projectile Filter                       --
------------------------------------------------------------------
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

    if is_attack then
        if attacker:HasArtilleryAttack() then
            AttackGroundPos(attacker, victim:GetAbsOrigin(), move_speed)
            return false
        end
    elseif attacker_index ~= -1 then
        local ability = EntIndexToHScript(filterTable["entindex_ability_const"])
        local bBlock = victim:ShouldAbsorbSpell(attacker, ability)
        if bBlock then
            return false
        end
    end

    return true
end

------------------------------------------------------------------
--                       Experience Filter                      --
------------------------------------------------------------------
function dotacraft:FilterExperience( filterTable )
    local experience = filterTable["experience"]
    local playerID = filterTable["player_id_const"]
    local reason = filterTable["reason_const"]

    -- Disable all hero kill experience
    if reason == DOTA_ModifyXP_HeroKill then
        return false
    end

    return true
end

------------------------------------------------------------------
--                          Gold Filter                         --
------------------------------------------------------------------
function dotacraft:FilterGold( filterTable )
    local gold = filterTable["gold"]
    local playerID = filterTable["player_id_const"]
    local reason = filterTable["reason_const"]

    -- Disable all hero kill gold
    if reason == DOTA_ModifyGold_HeroKill then
        return false
    end

    return true
end

------------------------------------------------------------------
--                        Modifier Filter                       --
------------------------------------------------------------------
function dotacraft:FilterModifier( filterTable )
    local target_index = filterTable['entindex_parent_const']
    local caster_index = filterTable['entindex_caster_const']
    local ability_index = filterTable["entindex_ability_const"]
    
    if not target_index or not caster_index or not ability_index then
        return true
    end

    local ability = EntIndexToHScript(ability_index)
    local target = EntIndexToHScript(target_index)
    local caster = EntIndexToHScript(caster_index)
    local bBlock = target:ShouldAbsorbSpell(caster, ability)
    if bBlock then
        return false
    end

    local bIgnoreAir = target ~= caster and target:HasFlyMovementCapability() and not ability:AffectsAir()
    if bIgnoreAir then
        return false
    end

    local bIgnoreMechanical = target:IsMechanical() and not ability:AffectsMechanical()
    if bIgnoreMechanical then
        return false
    end

    -- Store ability name for spell steal
    Timers:CreateTimer(0.03, function()
        if IsValidEntity(target) and IsValidEntity(ability) then
            local modifier = target:FindModifierByName(filterTable["name_const"])
            if modifier then
                modifier.abilityName = ability:GetAbilityName() -- Store ability name for spell steal
            end
        end
    end)

    return true
end

------------------------------------------------------------------
--                       Item Added Filter                      --
------------------------------------------------------------------
function dotacraft:FilterItemAdded( filterTable )
    local ownerIndex = filterTable["inventory_parent_entindex_const"]
    local itemIndex = filterTable["item_entindex_const"]

    if not ownerIndex or not itemIndex then return true end

    local owner = EntIndexToHScript(filterTable["inventory_parent_entindex_const"])
    local item = EntIndexToHScript(filterTable["item_entindex_const"])
    if IsValidEntity(item) and not item:IsCastOnPickup() then
        item:SetPurchaser(owner)
    end
    return true
end