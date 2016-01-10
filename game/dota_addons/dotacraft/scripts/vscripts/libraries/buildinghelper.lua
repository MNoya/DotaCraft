BH_VERSION = "1.0"

if not BuildingHelper then
    BuildingHelper = class({})
end

--[[
    BuildingHelper Init
    * Loads Key Values into the BuildingAbilities
]]--
function BuildingHelper:Init()
    BuildingHelper.AbilityKV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
    BuildingHelper.ItemKV = LoadKeyValues("scripts/npc/npc_items_custom.txt")
    BuildingHelper.UnitKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")

    -- building_settings nettable from buildings.kv
    BuildingHelper:LoadSettings()

    BuildingHelper:print("BuildingHelper Init")
    BuildingHelper.Players = {} -- Holds a table for each player ID
    BuildingHelper.Dummies = {} -- Holds up to one entity for each building name
    BuildingHelper.Grid = {}    -- Construction grid
    BuildingHelper.Terrain = {} -- Terrain grid, this only changes when a tree is cut
    BuildingHelper.Encoded = "" -- String containing the base terrain, networked to clients
    BuildingHelper.squareX = 0  -- Number of X grid points
    BuildingHelper.squareY = 0  -- Number of Y grid points

    -- Grid States
    BuildingHelper.GridTypes = {}
    BuildingHelper.NextGridValue = 1
    BuildingHelper:NewGridType("BLOCKED")
    BuildingHelper:NewGridType("BUILDABLE")

    -- Panorama Event Listeners
    CustomGameEventManager:RegisterListener("building_helper_build_command", Dynamic_Wrap(BuildingHelper, "BuildCommand"))
    CustomGameEventManager:RegisterListener("building_helper_cancel_command", Dynamic_Wrap(BuildingHelper, "CancelCommand"))
    CustomGameEventManager:RegisterListener("update_selected_entities", Dynamic_Wrap(BuildingHelper, 'OnPlayerSelectedEntities'))
    CustomGameEventManager:RegisterListener("gnv_request", Dynamic_Wrap(BuildingHelper, "SendGNV"))

     -- Game Event Listeners
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(BuildingHelper, 'OnGameRulesStateChange'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(BuildingHelper, 'OnNPCSpawned'), self)
    ListenToGameEvent('entity_killed', Dynamic_Wrap(BuildingHelper, 'OnEntityKilled'), self)
    if BuildingHelper.Settings["UPDATE_TREES"] then
        ListenToGameEvent('tree_cut', Dynamic_Wrap(BuildingHelper, 'OnTreeCut'), self)
    end

    -- Lua modifiers
    LinkLuaModifier("modifier_out_of_world", "libraries/modifiers/modifier_out_of_world", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_builder_hidden", "libraries/modifiers/modifier_builder_hidden", LUA_MODIFIER_MOTION_NONE)
    
    BuildingHelper.KV = {} -- Merge KVs into a single table
    BuildingHelper:ParseKV(BuildingHelper.AbilityKV, BuildingHelper.KV)
    BuildingHelper:ParseKV(BuildingHelper.ItemKV, BuildingHelper.KV)
    BuildingHelper:ParseKV(BuildingHelper.UnitKV, BuildingHelper.KV)

    -- Hook to override the order filter
    debug.sethook(function(...)
        local info = debug.getinfo(2)
        local src = tostring(info.short_src)
        local name = tostring(info.name)
        if name ~= "__index" then
            if string.find(src, "addon_game_mode") then
                if GameRules:GetGameModeEntity() then
                    local mode = GameRules:GetGameModeEntity()
                    mode:SetExecuteOrderFilter(Dynamic_Wrap(BuildingHelper, 'OrderFilter'), BuildingHelper)
                    self.oldFilter = mode.SetExecuteOrderFilter
                    mode.SetExecuteOrderFilter = function(mode, fun, context)
                        BuildingHelper.nextFilter = fun
                        BuildingHelper.nextContext = context
                    end
                    debug.sethook(nil, "c")
                end
            end
        end
    end, "c")
end

function BuildingHelper:LoadSettings()
    BuildingHelper.Settings = LoadKeyValues("scripts/kv/building_settings.kv")
    
    BuildingHelper.Settings["TESTING"] = tobool(BuildingHelper.Settings["TESTING"])
    BuildingHelper.Settings["RECOLOR_BUILDING_PLACED"] = tobool(BuildingHelper.Settings["RECOLOR_BUILDING_PLACED"])
    BuildingHelper.Settings["UPDATE_TREES"] = tobool(BuildingHelper.Settings["UPDATE_TREES"])

    CustomNetTables:SetTableValue("building_settings", "grid_alpha", { value = BuildingHelper.Settings["GRID_ALPHA"] })
    CustomNetTables:SetTableValue("building_settings", "alt_grid_alpha", { value = BuildingHelper.Settings["ALT_GRID_ALPHA"] })
    CustomNetTables:SetTableValue("building_settings", "alt_grid_squares", { value = BuildingHelper.Settings["ALT_GRID_SQUARES"] })
    CustomNetTables:SetTableValue("building_settings", "range_overlay_alpha", { value = BuildingHelper.Settings["RANGE_OVERLAY_ALPHA"] })
    CustomNetTables:SetTableValue("building_settings", "model_alpha", { value = BuildingHelper.Settings["MODEL_ALPHA"] })
    CustomNetTables:SetTableValue("building_settings", "recolor_ghost", { value = tobool(BuildingHelper.Settings["RECOLOR_GHOST_MODEL"]) })
    CustomNetTables:SetTableValue("building_settings", "turn_red", { value = tobool(BuildingHelper.Settings["RED_MODEL_WHEN_INVALID"]) })
    CustomNetTables:SetTableValue("building_settings", "permanent_alt_grid", { value = tobool(BuildingHelper.Settings["PERMANENT_ALT_GRID"]) })
    CustomNetTables:SetTableValue("building_settings", "update_trees", { value = BuildingHelper.Settings["UPDATE_TREES"] })

    if BuildingHelper.Settings["HEIGHT_RESTRICTION"] ~= "" then
        CustomNetTables:SetTableValue("building_settings", "height_restriction", { value = BuildingHelper.Settings["HEIGHT_RESTRICTION"] })
    end
end

function BuildingHelper:ParseKV( t, result )
    for name,info in pairs(t) do
        if type(info) == "table" then
            local isBuilding = info["Building"] or info["ConstructionSize"]
            if isBuilding then
                if result[name] then
                    BuildingHelper:print("Error: There's more than 2 entries for "..name)
                else
                    result[name] = info
                end

                -- Build NetTable with the building properties
                local values = {}
                if info['ConstructionSize'] then
                    values.size = info['ConstructionSize']

                    -- Add proximity restriction
                    if info['RestrictGoldMineDistance'] then
                        values.distance_to_gold_mine = info['RestrictGoldMineDistance']
                    end

                    -- Add special grid types generated by this building
                    if info['Grid'] then
                        values.grid = info['Grid']
                    end

                    -- Add required grid types
                    if info['Requires'] then
                        values.requires = string.upper(info['Requires'])
                    end

                    -- Add denied grid types
                    if info['Prevents'] then
                        values.requires = string.upper(info['Prevents'])
                    end

                    CustomNetTables:SetTableValue("construction_size", name, values)                   
                end
            end
        end
    end
end

function BuildingHelper:OnGameRulesStateChange(keys)
    local newState = GameRules:State_Get()
    if newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        -- The base terrain GridNav is obtained directly from the vmap
        BuildingHelper:InitGNV()
    end
end

function BuildingHelper:OnNPCSpawned(keys)
    local npc = EntIndexToHScript(keys.entindex)
    if IsBuilder(npc) then
        BuildingHelper:InitializeBuilder(npc)
    end
end

function BuildingHelper:OnEntityKilled(keys)
    local killed = EntIndexToHScript(keys.entindex_killed)

    if IsBuilder(killed) then
        BuildingHelper:ClearQueue(killed)
    elseif IsCustomBuilding(killed) then
        -- Building Helper grid cleanup
        BuildingHelper:RemoveBuilding(killed, true)
    end
end

function BuildingHelper:OnTreeCut(keys)
    local treePos = Vector(keys.tree_x,keys.tree_y,0)

    -- Create a dummy for clients to be able to detect trees standing and block their grid
    local tree_chopped = CreateUnitByName("npc_dota_thinker", treePos, false, nil, nil, 0)
    tree_chopped:AddAbility("dummy_tree")
    local tree_ability = tree_chopped:FindAbilityByName("dummy_tree")
    if not tree_ability then
        BuildingHelper:print("ERROR: dummy_tree ability is missing!")
    else
        tree_ability:SetLevel(1)
    end

    -- Allow construction
    if not GridNav:IsBlocked(treePos) then
        BuildingHelper:FreeGridSquares(2, treePos)
    end
end

function BuildingHelper:InitGNV()
    local worldMin = Vector(GetWorldMinX(), GetWorldMinY(), 0)
    local worldMax = Vector(GetWorldMaxX(), GetWorldMaxY(), 0)

    local boundX1 = GridNav:WorldToGridPosX(worldMin.x)
    local boundX2 = GridNav:WorldToGridPosX(worldMax.x)
    local boundY1 = GridNav:WorldToGridPosY(worldMin.y)
    local boundY2 = GridNav:WorldToGridPosY(worldMax.y)
   
    BuildingHelper:print("Max World Bounds: ")
    BuildingHelper:print(GetWorldMaxX()..' '..GetWorldMaxY()..' '..GetWorldMaxX()..' '..GetWorldMaxY())

    local blockedCount = 0
    local unblockedCount = 0

    local gnv = {}
    for x=boundX1,boundX2 do
        local shift = 6
        local byte = 0
        BuildingHelper.Terrain[x] = {}
        for y=boundY1,boundY2 do
            local gridX = GridNav:GridPosToWorldCenterX(x)
            local gridY = GridNav:GridPosToWorldCenterY(y)
            local position = Vector(gridX, gridY, 0)
            local treeBlocked = GridNav:IsNearbyTree(position, 30, true)

            -- If tree updating is enabled, trees aren't networked but detected as ent_dota_tree entities on clients
            local terrainBlocked = not GridNav:IsTraversable(position) or GridNav:IsBlocked(position)
            if BuildingHelper.Settings["UPDATE_TREES"] then
                terrainBlocked = terrainBlocked and not treeBlocked
            end

            if terrainBlocked then
                BuildingHelper.Terrain[x][y] = BuildingHelper.GridTypes["BLOCKED"]
                byte = byte + bit.lshift(2,shift)
                blockedCount = blockedCount+1
            else
                BuildingHelper.Terrain[x][y] = BuildingHelper.GridTypes["BUILDABLE"]
                byte = byte + bit.lshift(1,shift)
                unblockedCount = unblockedCount+1
            end

            if treeBlocked then
                BuildingHelper.Terrain[x][y] = BuildingHelper.GridTypes["BLOCKED"]
            end

            shift = shift - 2

            if shift == -2 then
                gnv[#gnv+1] = string.char(byte-53)
                shift = 6
                byte = 0
            end
        end

        if shift ~= 6 then
            gnv[#gnv+1] = string.char(byte-53)
        end
    end

    local gnv_string = table.concat(gnv,'')

    BuildingHelper:print(boundX1..' '..boundX2..' '..boundY1..' '..boundY2)
    local squareX = math.abs(boundX1) + math.abs(boundX2)+1
    local squareY = math.abs(boundY1) + math.abs(boundY2)+1
    print("Free: "..unblockedCount.." Blocked: "..blockedCount)

    -- Initially, the construction grid equals the terrain grid
    -- Clients will have full knowledge of the terrain grid
    -- The construction grid is only known by the server
    BuildingHelper.Grid = BuildingHelper.Terrain

    BuildingHelper.Encoded = gnv_string
    BuildingHelper.squareX = squareX
    BuildingHelper.squareY = squareY
end

function BuildingHelper:SendGNV( args )
    local playerID = args.PlayerID
    local player = PlayerResource:GetPlayer(playerID)
    BuildingHelper:print("Sending GNV to player "..playerID)
    CustomGameEventManager:Send_ServerToPlayer(player, "gnv_register", {gnv=BuildingHelper.Encoded, squareX = BuildingHelper.squareX, squareY = BuildingHelper.squareY})
end

--[[
    BuildCommand
    * Detects a Left Click with a builder through Panorama
]]--
function BuildingHelper:BuildCommand( args )
    local playerID = args['PlayerID']
    local x = args['X']
    local y = args['Y']
    local z = args['Z']
    local location = Vector(x, y, z)
    local queue = args['Queue'] == 1
    local builder = EntIndexToHScript(args['builder']) --activeBuilder

    -- Cancel current action
    if not queue then
        ExecuteOrderFromTable({ UnitIndex = args['builder'], OrderType = DOTA_UNIT_ORDER_STOP, Queue = false}) 
    end

    BuildingHelper:AddToQueue(builder, location, queue)
end

--[[
    CancelCommand
    * Detects a Right Click/Tab with a builder through Panorama
]]--
function BuildingHelper:CancelCommand( args )
    local playerID = args['PlayerID']
    local playerTable = BuildingHelper:GetPlayerTable(playerID)
    playerTable.activeBuilding = nil

    if not playerTable.activeBuilder or not IsValidEntity(playerTable.activeBuilder) then
        return
    end
    BuildingHelper:ClearQueue(playerTable.activeBuilder)
end

function BuildingHelper:OnPlayerSelectedEntities(event)
    local playerID = event.PlayerID
    local playerTable = BuildingHelper:GetPlayerTable(playerID)

    playerTable.SelectedEntities = event.selected_entities

    -- This is for Building Helper to know which is the currently active builder
    local mainSelected = EntIndexToHScript(playerTable.SelectedEntities["0"])
    local player = BuildingHelper:GetPlayerTable(playerID)

    if IsValidEntity(mainSelected) then
        if IsBuilder(mainSelected) then
            player.activeBuilder = mainSelected
        else
            if IsValidEntity(player.activeBuilder) then
                -- Clear ghost particles when swapping to a non-builder
                BuildingHelper:StopGhost(player.activeBuilder)
            end
        end
    end
end

function BuildingHelper:OrderFilter(order)
    local ret = true    

    if BuildingHelper.nextFilter then
        ret = BuildingHelper.nextFilter(BuildingHelper.nextContext, order)
    end

    if not ret then
        return false
    end

    local issuerID = order.issuer_player_id_const

    if issuerID == -1 then return true end

    local queue = order.queue == 1
    local order_type = order.order_type
    local units = order.units
    local abilityIndex = order.entindex_ability
    local unit = EntIndexToHScript(units["0"])

    -- Item is dropped
    if order_type == DOTA_UNIT_ORDER_DROP_ITEM and IsBuilder(unit) then
        BuildingHelper:ClearQueue(unit)
        return true

    -- Stop and Hold
    elseif order_type == DOTA_UNIT_ORDER_STOP or order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
        for n, unit_index in pairs(units) do 
            local unit = EntIndexToHScript(unit_index)
            if IsBuilder(unit) then
                BuildingHelper:ClearQueue(unit)
            end
        end
        return true

    -- Casting non building abilities
    elseif (abilityIndex and abilityIndex ~= 0) and unit and IsBuilder(unit) then
        local ability = EntIndexToHScript(abilityIndex)
        if not IsBuildingAbility(ability) then
            BuildingHelper:ClearQueue(unit)
        end
    end

    return ret
end    

--[[
      InitializeBuilder
      * Manages each workers build queue. Will run once per builder
]]--
function BuildingHelper:InitializeBuilder(builder)
    BuildingHelper:print("InitializeBuilder "..builder:GetUnitName().." "..builder:GetEntityIndex())

    if not builder.buildingQueue then
        builder.buildingQueue = {}
    end

    -- Store the builder entity indexes on a net table
    CustomNetTables:SetTableValue("builders", tostring(builder:GetEntityIndex()), { IsBuilder = true })
end

function BuildingHelper:RemoveBuilder( builder )
    -- Store the builder entity indexes on a net table
    CustomNetTables:SetTableValue("builders", tostring(builder:GetEntityIndex()), { IsBuilder = false })
end

--[[
    AddBuilding
    * Makes a building dummy and starts panorama ghosting
    * Builder calls this and sets the callbacks with the required values
]]--
function BuildingHelper:AddBuilding(keys)
    -- Callbacks
    callbacks = BuildingHelper:SetCallbacks(keys)
    local builder = keys.caster
    local ability = keys.ability
    local abilName = ability:GetAbilityName()
    local buildingTable = BuildingHelper:SetupBuildingTable(abilName, builder)

    buildingTable:SetVal("AbilityHandle", ability)

    -- Prepare the builder, if it hasn't already been done
    if not builder.buildingQueue then  
        BuildingHelper:InitializeBuilder(builder)
    end

    local size = buildingTable:GetVal("ConstructionSize", "number")
    local unitName = buildingTable:GetVal("UnitName", "string")

    -- Handle self-ghosting
    if unitName == "self" then
        unitName = builder:GetUnitName()
    end

    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    if not fMaxScale then
        -- If no MaxScale is defined, check the "ModelScale" KeyValue. Otherwise just default to 1
        local fModelScale = BuildingHelper.UnitKV[unitName].ModelScale
        if fModelScale then
          fMaxScale = fModelScale
        else
            fMaxScale = 1
        end
    end
    buildingTable:SetVal("MaxScale", fMaxScale)

    local color = Vector(255,255,255)
    if RECOLOR_GHOST_MODEL then
        color = Vector(0,255,0)
    end

    -- Basic event table to send
    local event = { state = "active", size = size, scale = fMaxScale, builderIndex = builder:GetEntityIndex() }

    -- Set the active variables and callbacks
    local playerID = builder:GetMainControllingPlayer()
    local player = PlayerResource:GetPlayer(playerID)
    local playerTable = BuildingHelper:GetPlayerTable(playerID)
    playerTable.activeBuilder = builder
    playerTable.activeBuilding = unitName
    playerTable.activeBuildingTable = buildingTable
    playerTable.activeCallbacks = callbacks

    -- npc_dota_creature doesn't render cosmetics on the particle ghost, use hero names instead
    local overrideGhost = buildingTable:GetVal("OverrideBuildingGhost", "string")
    if overrideGhost then
        unitName = overrideGhost
    end

    -- Get a model dummy to pass it to panorama
    local mgd = BuildingHelper:GetOrCreateDummy(unitName)
    event.entindex = mgd:GetEntityIndex()

    -- Range overlay
    if mgd:HasAttackCapability() then
        event.range = buildingTable:GetVal("AttackRange", "number") + mgd:GetHullRadius()
    end

    -- Make a pedestal dummy if required
    local pedestal = buildingTable:GetVal("PedestalModel")
    if pedestal then
        local prop = BuildingHelper:GetOrCreateProp(pedestal)
        mgd.prop = prop

        -- Add values to the event table
        event.propIndex = prop:GetEntityIndex()
        event.propScale = buildingTable:GetVal("PedestalModelScale", "float") or mgd:GetModelScale()
        event.offsetZ = buildingTable:GetVal("PedestalOffset", "float") or 0
    end

    -- Adjust the Model Orientation
    local yaw = buildingTable:GetVal("ModelRotation", "float")
    mgd:SetAngles(0, -yaw, 0)
                        
    CustomGameEventManager:Send_ServerToPlayer(player, "building_helper_enable", event)
end

--[[
    SetCallbacks
    * Defines a series of callbacks to be returned in the builder module
]]--
function BuildingHelper:SetCallbacks(keys)
    local callbacks = {}

    function keys:OnPreConstruction( callback )
        callbacks.onPreConstruction = callback -- Return false to abort the build
    end

     function keys:OnBuildingPosChosen( callback )
        callbacks.onBuildingPosChosen = callback -- Spend resources here
    end

    function keys:OnConstructionFailed( callback ) -- Called if there is a mechanical issue with the building (cant be placed)
        callbacks.onConstructionFailed = callback
    end

    function keys:OnConstructionCancelled( callback ) -- Called when player right clicks to cancel a queue
        callbacks.onConstructionCancelled = callback
    end

    function keys:OnConstructionStarted( callback )
        callbacks.onConstructionStarted = callback
    end

    function keys:OnConstructionCompleted( callback )
        callbacks.onConstructionCompleted = callback
    end

    function keys:OnBelowHalfHealth( callback )
        callbacks.onBelowHalfHealth = callback
    end

    function keys:OnAboveHalfHealth( callback )
        callbacks.onAboveHalfHealth = callback
    end

    return callbacks
end

--[[
    SetupBuildingTable
    * Setup building table, returns a constructed table.
]]--
function BuildingHelper:SetupBuildingTable( abilityName, builderHandle )

    local buildingTable = BuildingHelper.KV[abilityName]

    function buildingTable:GetVal( key, expectedType )
        local val = buildingTable[key]

        -- Handle missing values.
        if val == nil then
            if expectedType == "bool" then
                return false
            else
                return nil
            end
        end
        
        -- Handle empty values
        local sVal = tostring(val)
        if sVal == "" then
            return nil
        end

        if expectedType == "bool" then
            return sVal == "1"
        elseif expectedType == "number" or expectedType == "float" then
            return tonumber(val)
        end
        return sVal
    end

    function buildingTable:SetVal( key, value )
        buildingTable[key] = value
    end

    -- Extract data from the KV files, set is called to guarantee these have values later on in execution
    local unitName = buildingTable:GetVal("UnitName", "string")
    if not unitName then
        BuildingHelper:print('Error: ' .. abilName .. ' does not have a UnitName KeyValue')
        return
    end
    buildingTable:SetVal("UnitName", unitName)

    -- Self ghosting
    if unitName == "self" then
        unitName = builderHandle:GetUnitName()
    end

    -- Ensure that the unit actually exists
    local unitTable = BuildingHelper.UnitKV[unitName]
    if not unitTable then
        BuildingHelper:print('Error: Definition for Unit ' .. unitName .. ' could not be found in the KeyValue files.')
        return
    end

    local construction_size = unitTable["ConstructionSize"]
    if not construction_size then
        BuildingHelper:print('Error: Unit ' .. unitName .. ' does not have a ConstructionSize KeyValue.')
        return
    end
    buildingTable:SetVal("ConstructionSize", construction_size)

    -- OverrideBuildingGhost
    local override_ghost = BuildingHelper.UnitKV[unitName]["OverrideBuildingGhost"]
    if override_ghost then
        buildingTable:SetVal("OverrideBuildingGhost", override_ghost)
    end

    local build_time = buildingTable["BuildTime"] or unitTable["BuildTime"]
    if not build_time then
        BuildingHelper:print('Error: No BuildTime for ' .. unitName .. '. Default to 0.1')
        build_time = 0.1
    end
    buildingTable:SetVal("BuildTime", build_time)

    local attack_range = unitTable["AttackRange"] or 0
    buildingTable:SetVal("AttackRange", attack_range)

    local pathing_size = unitTable["BlockPathingSize"]
    if not pathing_size then
        BuildingHelper:print('Warning: Unit ' .. unitName .. ' does not have a BlockPathingSize KeyValue. Defaulting to 0')
        pathing_size = 0
    end
    buildingTable:SetVal("BlockPathingSize", pathing_size)

    -- Pedestal Model
    local pedestal_model = BuildingHelper.UnitKV[unitName]["PedestalModel"]
    if pedestal_model then
        buildingTable:SetVal("PedestalModel", pedestal_model)
    end

    -- Pedestal Scale
    local pedestal_scale = BuildingHelper.UnitKV[unitName]["PedestalModelScale"]
    if pedestal_scale then
        buildingTable:SetVal("PedestalModelScale", pedestal_scale)
    end

    -- Pedestal Offset
    local pedestal_offset = BuildingHelper.UnitKV[unitName]["PedestalOffset"]
    if pedestal_offset then
        buildingTable:SetVal("PedestalOffset", pedestal_offset)
    end

    -- If the construction requires certain grid type, store it
    local requires = unitTable["Requires"]
    if not requires then
        requires = "Buildable"
    end
    buildingTable:SetVal("Requires", string.upper(requires))

    local prevents = unitTable["Prevents"]
    if prevents then
        buildingTable:SetVal("Prevents", string.upper(prevents))
    end

    local castRange = buildingTable:GetVal("AbilityCastRange", "number")
    if not castRange then
        castRange = 200
    end
    buildingTable:SetVal("AbilityCastRange", castRange)

    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    if not fMaxScale then
        -- If no MaxScale is defined, check the Units "ModelScale" KeyValue. Otherwise just default to 1
        local fModelScale = BuildingHelper.UnitKV[unitName].ModelScale
        if fModelScale then
            fMaxScale = fModelScale
        else
            fMaxScale = 1
        end
    end
    buildingTable:SetVal("MaxScale", fMaxScale)

    local fModelRotation = buildingTable:GetVal("ModelRotation", "float")
    if not fModelRotation then
        fModelRotation = 0
    end
    buildingTable:SetVal("ModelRotation", fModelRotation)

    return buildingTable
end

--[[
    PlaceBuilding
    * Places a new building on full health and returns the handle. 
    * Places grid nav blockers
    * Skips the construction phase and doesn't require a builder, this is most important to place the "base" buildings for the players when the game starts.
    * Make sure the position is valid before calling this in code.
]]--
function BuildingHelper:PlaceBuilding(player, name, location, construction_size, pathing_size, angle)
    BuildingHelper:SnapToGrid(construction_size, location)
    local playerID = player:GetPlayerID()
    local playersHero = PlayerResource:GetSelectedHeroEntity(playerID)
    BuildingHelper:print("PlaceBuilding for playerID ".. playerID)

    -- Spawn point obstructions before placing the building
    local gridNavBlockers = BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)

    -- Spawn the building
    local building = CreateUnitByName(name, location, false, playersHero, player, playersHero:GetTeamNumber())
    building:SetControllableByPlayer(playerID, true)
    building:SetOwner(playersHero)
    building.construction_size = construction_size
    building.blockers = gridNavBlockers

    if angle then
        building:SetAngles(0,-angle,0)
    end

    building.state = "complete"

    -- Return the created building
    return building
end

--[[
    RemoveBuilding
    * Removes a building, removing it from the gridnav, with an optional parameter to kill it
]]--
function BuildingHelper:RemoveBuilding( building, bForcedKill )
     if bForcedKill then
        building:ForceKill(bForcedKill)
    end

    local particleName = BuildingHelper.UnitKV[building:GetUnitName()]["DestructionEffect"]
    if particleName then
        local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, building)
        ParticleManager:SetParticleControl(particle, 0, building:GetAbsOrigin())
    end

    if building.fireEffectParticle then
        ParticleManager:DestroyParticle(building.fireEffectParticle, false)
    end

    if building.prop then
        UTIL_Remove(building.prop)
    end

    BuildingHelper:FreeGridSquares(building.construction_size, building:GetAbsOrigin())

    if not building.blockers then 
        return 
    end

    for k, v in pairs(building.blockers) do
        DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
        DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
    end
end

--[[
      StartBuilding
      * Creates the building and starts the construction process
]]--
function BuildingHelper:StartBuilding( builder )
    local playerID = builder:GetMainControllingPlayer()
    local work = builder.work
    local callbacks = work.callbacks
    local building = work.entity -- The building entity
    local unitName = work.name
    local location = work.location
    local player = PlayerResource:GetPlayer(playerID)
    local playersHero = PlayerResource:GetSelectedHeroEntity(playerID)
    local buildingTable = work.buildingTable
    local construction_size = buildingTable:GetVal("ConstructionSize", "number")
    local pathing_size = buildingTable:GetVal("BlockPathingSize", "number")

    -- Check gridnav and cancel if invalid
    if not BuildingHelper:ValidPosition(construction_size, location, builder, callbacks) then
        
        -- Remove the model particle and Advance Queue
        BuildingHelper:AdvanceQueue(builder)
        ParticleManager:DestroyParticle(work.particleIndex, true)

        -- Remove pedestal
        if work.entity and work.entity.prop then UTIL_Remove(work.entity.prop) end

        -- Building canceled, refund resources
        work.refund = true
        callbacks.onConstructionCancelled(work)
        return
    end

    BuildingHelper:print("Initializing Building Entity: "..unitName.." at "..VectorString(location))

    -- Mark this work in progress, skip refund if cancelled as the building is already placed
    work.inProgress = true

    -- Spawn point obstructions before placing the building
    local gridNavBlockers = BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)

    -- For overriden ghosts we need to create another unit and remove the fake hero ghost
    if building:GetUnitName() ~= unitName then
        building = CreateUnitByName(unitName, location, false, playersHero, player, builder:GetTeam())
    else
        building:RemoveModifierByName("modifier_out_of_world")
        building:RemoveEffects(EF_NODRAW)
    end

    -- Initialize the building
    building:SetAbsOrigin(location)
    building:SetControllableByPlayer(playerID, true)
    building.blockers = gridNavBlockers
    building.construction_size = construction_size
    building.buildingTable = buildingTable
    building.state = "building"

    -- Remove the attached prop particle and reveal the entity
    if work.entity and work.entity.prop and work.entity.prop.pedestalParticle then
        work.entity.prop:RemoveEffects(EF_NODRAW)
        ParticleManager:DestroyParticle(work.entity.prop.pedestalParticle, true)

        -- Store the prop on the building itself
        building.prop = work.entity.prop
    end

    -- Adjust the Model Orientation
    local yaw = buildingTable:GetVal("ModelRotation", "float")
    building:SetAngles(0, -yaw, 0)

    -- Prevent regen messing with the building spawn hp gain
    local regen = building:GetBaseHealthRegen()
    building:SetBaseHealthRegen(0)

    ------------------------------------------------------------------
    -- Build Behaviours
    --  RequiresRepair: If set to 1 it will place the building and not update its health nor send the OnConstructionCompleted callback until its fully healed
    --  BuilderInside: Puts the builder unselectable/invulnerable/nohealthbar inside the building in construction
    --  ConsumesBuilder: Kills the builder after the construction is done
    local bRequiresRepair = buildingTable:GetVal("RequiresRepair", "bool")
    local bBuilderInside = buildingTable:GetVal("BuilderInside", "bool")
    local bConsumesBuilder = buildingTable:GetVal("ConsumesBuilder", "bool")
    -------------------------------------------------------------------

    -- whether the building is controllable or not
    local bPlayerCanControl = buildingTable:GetVal("PlayerCanControl", "bool")
    if bPlayerCanControl then
        building:SetControllableByPlayer(playerID, true)
        building:SetOwner(playersHero)
    end

    -- Start construction
    if callbacks.onConstructionStarted then
        callbacks.onConstructionStarted(building)
    end

    -- buildTime can be overriden in the construction start callback
    local buildTime = building.overrideBuildTime or buildingTable:GetVal("BuildTime", "float")
    local fTimeBuildingCompleted = GameRules:GetGameTime()+buildTime -- the gametime when the building should be completed

    -- Dota server updates at 30 frames per second
    local fserverFrameRate = 1/30

    -- Max and Initial Health factor
    local fMaxHealth = building:GetMaxHealth()
    local fInitialHealthFactor = BuildingHelper.Settings["INITIAL_HEALTH_FACTOR"]
    local nInitialHealth = math.floor(fInitialHealthFactor * ( fMaxHealth ))
    local fUpdateHealthInterval = buildTime / math.floor(fMaxHealth-nInitialHealth) -- health to add every tick until build time is completed.
    building:SetHealth(nInitialHealth)
    building.bUpdatingHealth = true

    local bScale = buildingTable:GetVal("Scale", "bool") -- whether we should scale the building.
    local fInitialModelScale = 0.2 -- initial size
    local fMaxScale = buildingTable:GetVal("MaxScale", "float") or 1 -- the amount to scale to
    local fScaleInterval = (fMaxScale-fInitialModelScale) / (buildTime / fserverFrameRate) -- scale to add every frame, distributed by build time
    local fCurrentScale = fInitialModelScale -- start the building at the initial model scale
    local bScaling = false -- Keep tracking if we're currently model scaling.
    
    -- Set initial scale
    if bScale then
        building:SetModelScale(fCurrentScale)
        bScaling = true
    end

    -- Put the builder invulnerable inside the building in construction
    if bBuilderInside then
        BuildingHelper:HideBuilder(builder, location, building)
    end

     -- Health Update Timer and Behaviors
    -- If BuildTime*30 > Health, the tick would be faster than 1 frame, adjust the HP gained per frame (This doesn't work well with repair)
    -- Otherwise just add 1 health each frame.
    if fUpdateHealthInterval <= fserverFrameRate then

        BuildingHelper:print("Building needs float adjust")
        if bRequiresRepair then
            BuildingHelper:print("Error: Don't use Repair with fast-ticking buildings!")
        end

        if not bBuilderInside then
            -- Advance Queue
            BuildingHelper:AdvanceQueue(builder)
        end

        local fAddedHealth = 0
        local nHealthInterval = fMaxHealth / (buildTime / fserverFrameRate)
        local fSmallHealthInterval = nHealthInterval - math.floor(nHealthInterval) -- just the floating point component
        nHealthInterval = math.floor(nHealthInterval)
        local fHPAdjustment = 0

        building.updateHealthTimer = Timers:CreateTimer(function()
            if IsValidEntity(building) and building:IsAlive() then
                local timesUp = GameRules:GetGameTime() >= fTimeBuildingCompleted
                if not timesUp then
                    if building.bUpdatingHealth then
                        fHPAdjustment = fHPAdjustment + fSmallHealthInterval
                        if fHPAdjustment > 1 then
                            building:SetHealth(building:GetHealth() + nHealthInterval + 1)
                            fHPAdjustment = fHPAdjustment - 1
                            fAddedHealth = fAddedHealth + nHealthInterval + 1
                        else
                            building:SetHealth(building:GetHealth() + nHealthInterval)
                            fAddedHealth = fAddedHealth + nHealthInterval
                        end
                    end
                else
                    building:SetHealth(building:GetHealth() + fMaxHealth - fAddedHealth) -- round up the last little bit

                     -- completion: timesUp is true
                    if callbacks.onConstructionCompleted then
                        building.constructionCompleted = true
                        building.state = "complete"
                        building.builder = builder
                        callbacks.onConstructionCompleted(building)
                    end
                    
                    BuildingHelper:print("HP was off by: ".. fMaxHealth - fAddedHealth)

                    -- Eject Builder
                    if bBuilderInside then
                    
                        -- Consume Builder
                        if bConsumesBuilder then
                            builder:ForceKill(true)
                        else
                            BuildingHelper:ShowBuilder(builder)
                        end

                        -- Advance Queue
                        BuildingHelper:AdvanceQueue(builder)           
                    end
                
                    return
                end
            else
                -- Building destroyed

                -- Eject Builder
                if bBuilderInside then
                    builder:RemoveModifierByName("modifier_builder_hidden")
                    builder:RemoveNoDraw()
                end

                -- Advance Queue
                BuildingHelper:AdvanceQueue(builder)

                return nil
            end
            return fserverFrameRate
        end)
    
    elseif not bRequiresRepair then

        if not bBuilderInside then
            -- Advance Queue
            BuildingHelper:AdvanceQueue(builder)
        end

        building.updateHealthTimer = Timers:CreateTimer(function()
            if IsValidEntity(building) and building:IsAlive() then
                local timesUp = GameRules:GetGameTime() >= fTimeBuildingCompleted
                if not timesUp then
                    if building.bUpdatingHealth then
                        if building:GetHealth() < fMaxHealth then
                            building:SetHealth(building:GetHealth() + 1)
                        else
                            building.bUpdatingHealth = false
                        end
                    end
                else
                    -- completion: timesUp is true
                    if callbacks.onConstructionCompleted then
                        building.constructionCompleted = true
                        building.state = "complete"
                        building.builder = builder
                        callbacks.onConstructionCompleted(building)
                    end

                    -- Eject Builder
                    if bBuilderInside then
                    
                        -- Consume Builder
                        if bConsumesBuilder then
                            builder:ForceKill(true)
                        else
                            BuildingHelper:ShowBuilder(builder)
                        end

                        -- Advance Queue
                        BuildingHelper:AdvanceQueue(builder)           
                    end
                    
                    return
                end
            else
                -- Building destroyed

                -- Eject Builder
                if bBuilderInside then
                    builder:RemoveModifierByName("modifier_builder_hidden")
                    builder:RemoveNoDraw()
                end

                -- Advance Queue
                BuildingHelper:AdvanceQueue(builder)

                return nil
            end

            -- Update health every frame
            return fUpdateHealthInterval
        end)
    
    else

        -- The building will have to be assisted through a repair ability
        local repair_ability = BuildingHelper:GetRepairAbility( builder )
        if repair_ability then
            builder:CastAbilityOnTarget(building, repair_ability, playerID)
        end

        building.updateHealthTimer = Timers:CreateTimer(function()
            if IsValidEntity(building) then
                if building.constructionCompleted then --This is set on the repair ability when the builders have restored the necessary health
                    if callbacks.onConstructionCompleted and building:IsAlive() then
                        callbacks.onConstructionCompleted(building)
                    end

                     -- Finished repair-construction
                    BuildingHelper:AdvanceQueue(builder)

                    building.state = "complete"
                    return
                else
                    return 0.1
                end
            end
        end)
    end

    -- Scale Update Timer
    if bScale then
        building.updateScaleTimer = Timers:CreateTimer(function()
            if IsValidEntity(building) and building:IsAlive() then
                local timesUp = GameRules:GetGameTime() >= fTimeBuildingCompleted
                if not timesUp then
                    if bScaling then
                        if fCurrentScale < fMaxScale then
                            fCurrentScale = fCurrentScale+fScaleInterval
                            building:SetModelScale(fCurrentScale)
                        else
                            building:SetModelScale(fMaxScale)
                            bScaling = false
                        end
                    end
                else
                    
                    BuildingHelper:print("Scale was off by: "..(fMaxScale - fCurrentScale))
                    building:SetModelScale(fMaxScale)
                    return
                end
            else
                -- not valid ent
                return
            end
            
            return fserverFrameRate
        end)
    end

    -- OnBelowHalfHealth timer
    building.onBelowHalfHealthProc = false
    building.healthChecker = Timers:CreateTimer(.2, function()
        local fireEffect = BuildingHelper.KV[unitName]["FireEffect"]

        if IsValidEntity(building) and building:IsAlive() then
            local health_percentage = building:GetHealthPercent() * 0.01
            local belowThreshold = health_percentage < BuildingHelper.Settings["FIRE_EFFECT_FACTOR"]
            if belowThreshold and not building.onBelowHalfHealthProc and building.state == "complete" then
                if fireEffect then
                    -- Fire particle
                    if BuildingHelper.KV[unitName]["AttachPoint"] then
                        building.fireEffectParticle = ParticleManager:CreateParticle(fireEffect, PATTACH_CUSTOMORIGIN_FOLLOW, building)
                        ParticleManager:SetParticleControlEnt(building.fireEffectParticle, 0, building, PATTACH_POINT_FOLLOW, BuildingHelper.KV[unitName]["AttachPoint"], building:GetAbsOrigin(), true)
                    else
                        building.fireEffectParticle = ParticleManager:CreateParticle(fireEffect, PATTACH_ABSORIGIN_FOLLOW, building)
                    end
                end
            
                callbacks.onBelowHalfHealth(building)
                building.onBelowHalfHealthProc = true
            elseif not belowThreshold and building.onBelowHalfHealthProc and building.state == "complete" then
                if fireEffect then
                    ParticleManager:DestroyParticle(building.fireEffectParticle, false)
                end

                callbacks.onAboveHalfHealth(building)
                building.onBelowHalfHealthProc = false
            end
        else
            return nil
        end
        return .2
    end)

    -- Remove the model particle
    ParticleManager:DestroyParticle(work.particleIndex, true)
end

--[[
      BlockGridSquares
      * Blocks a square of certain construction and pathing size at a location on the server grid
      * construction_size: square of grid points to block from construction
      * pathing_size: square of pathing obstructions that will be spawned 
]]--
function BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)
    BuildingHelper:RemoveGridType(construction_size, location, "BUILDABLE")
    BuildingHelper:AddGridType(construction_size, location, "BLOCKED")

    return BuildingHelper:BlockPSO(pathing_size, location)
end

-- Spawns a square of point_simple_obstruction entities at a location
function BuildingHelper:BlockPSO(size, location)
    if size == 0 then return end

    -- Keep the origin of the buildings to put them back in position after spawning point_simple_obstruction entities
    local buildings = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, location, nil, size*128, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
    for k,v in pairs(buildings) do
        if IsCustomBuilding(v) then
            v.Origin = v:GetAbsOrigin()
        end
    end

    local pos = Vector(location.x, location.y, location.z)
    BuildingHelper:SnapToGrid(size, pos)

    local gridNavBlockers = {}
    if size == 5 then
        for x = pos.x - (size-2) * 32, pos.x + (size-2) * 32, 64 do
            for y = pos.y - (size-2) * 32, pos.y + (size-2) * 32, 64 do
                local blockerLocation = Vector(x, y, pos.z)
                local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
                table.insert(gridNavBlockers, ent)
            end
        end
    elseif size == 3 then
        for x = pos.x - (size / 2) * 32 , pos.x + (size / 2) * 32 , 64 do
            for y = pos.y - (size / 2) * 32 , pos.y + (size / 2) * 32 , 64 do
                local blockerLocation = Vector(x, y, pos.z)
                local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
                table.insert(gridNavBlockers, ent)
            end
        end
    else
        local len = size * 32 - 64
        if len == 0 then
            local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = pos})
            table.insert(gridNavBlockers, ent)
        else
            for x = pos.x - len, pos.x + len, len do
                for y = pos.y - len, pos.y + len, len do
                    local blockerLocation = Vector(x, y, pos.z)
                    local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
                    table.insert(gridNavBlockers, ent)
                end
            end
        end
    end

    -- Stuck the stuff back in place
    for k,v in pairs(buildings) do
        if IsCustomBuilding(v) then
            v:SetAbsOrigin(v.Origin)
        end
    end

    return gridNavBlockers
end

-- Clears out an area for construction
function BuildingHelper:FreeGridSquares(construction_size, location)
    BuildingHelper:RemoveGridType(construction_size, location, "BLOCKED")
    BuildingHelper:AddGridType(construction_size, location, "BUILDABLE")
end

function BuildingHelper:NewGridType( grid_type )
    grid_type = string.upper(grid_type)
    BuildingHelper:print("Adding new Grid Type: ".. grid_type.." ["..BuildingHelper.NextGridValue.."]")
    BuildingHelper.GridTypes[grid_type] = BuildingHelper.NextGridValue
    BuildingHelper.NextGridValue = BuildingHelper.NextGridValue * 2
    CustomNetTables:SetTableValue("building_settings", "grid_types", BuildingHelper.GridTypes)
end

-- Adds a grid_type to a square of size at centered at a location
function BuildingHelper:AddGridType(size, location, grid_type)
    -- If it doesn't exist, add it
    grid_type = string.upper(grid_type)
    if not BuildingHelper.GridTypes[grid_type] then
        BuildingHelper:NewGridType( grid_type )
    end

    BuildingHelper:SetGridType(size, location, grid_type, "add")  
end

-- Removes grid_type from every cell of a square around the location
function BuildingHelper:RemoveGridType(size, location, grid_type)
    BuildingHelper:SetGridType(size, location, grid_type, "remove")
end

-- Central function used to add, remove or override multiple grid squares at once
function BuildingHelper:SetGridType(size, location, grid_type, option)
    if not size or size == 0 then return end

    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)
    local halfSize = math.floor(size/2)
    local boundX1 = originX + halfSize
    local boundX2 = originX - halfSize
    local boundY1 = originY + halfSize
    local boundY2 = originY - halfSize

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- Adjust even size
    if (size % 2) == 0 then
        upperBoundX = upperBoundX-1
        upperBoundY = upperBoundY-1
    end

    -- Adjust to upper case
    grid_type = string.upper(grid_type)

    -- Default by omission is to override the old value
    if not option then
        for x = lowerBoundX, upperBoundX do
            for y = lowerBoundY, upperBoundY do
                BuildingHelper.Grid[x][y] = BuildingHelper.GridTypes[grid_type]
            end
        end

    elseif option == "add" then
        for x = lowerBoundX, upperBoundX do
            for y = lowerBoundY, upperBoundY do
                -- Only add if it doesn't have it yet
                local hasGridType = BuildingHelper:CellHasGridType(x,y,grid_type)
                if not hasGridType then
                    BuildingHelper.Grid[x][y] = BuildingHelper.Grid[x][y] + BuildingHelper.GridTypes[grid_type]
                end
            end
        end

    elseif option == "remove" then
         for x = lowerBoundX, upperBoundX do
            for y = lowerBoundY, upperBoundY do
                -- Only remove if it has it
                local hasGridType = BuildingHelper:CellHasGridType(x,y,grid_type)
                if hasGridType then
                    BuildingHelper.Grid[x][y] = BuildingHelper.Grid[x][y] - BuildingHelper.GridTypes[grid_type]
                end
            end
        end
    end     
end

-- Returns a string with each of the grid types of the cell, mostly to debug
function BuildingHelper:GetCellGridTypes(x,y)
    local s = ""
    for grid_string,value in pairs(BuildingHelper.GridTypes) do
        local hasGridType = BuildingHelper:CellHasGridType(x,y,grid_string)
        if hasGridType then
            s = s..grid_string.." "
        end
    end
    return s
end

-- Checks if the cell has a certain grid type by name
function BuildingHelper:CellHasGridType(x,y,grid_type)
    if BuildingHelper.GridTypes[grid_type] then
        return bit.band(BuildingHelper.Grid[x][y], BuildingHelper.GridTypes[grid_type]) ~= 0
    end
end

--[[
      ValidPosition
      * Checks GridNav square of certain size at a location
      * Sends onConstructionFailed if invalid
]]--
function BuildingHelper:ValidPosition(size, location, unit, callbacks)
    local bBlocked

    -- Check for special requirement
    local playerTable = BuildingHelper:GetPlayerTable(unit:GetPlayerOwnerID())
    local buildingName = playerTable.activeBuilding
    local buildingTable = buildingName and BuildingHelper.UnitKV[buildingName]
    local requires = buildingTable and buildingTable["Requires"]
    local prevents = buildingTable and buildingTable["Prevents"]

    if requires then
        bBlocked = not BuildingHelper:AreaMeetsCriteria(size, location, requires, "all")
    else
        bBlocked = BuildingHelper:IsAreaBlocked(size, location)
    end

    if prevents then
        bBlocked = bBlocked or BuildingHelper:AreaMeetsCriteria(size, location, prevents, "one")
    end

    if bBlocked then
        if callbacks.onConstructionFailed then
            callbacks.onConstructionFailed()
            return false
        end
    end

    -- Check enemy units blocking the area
    local construction_radius = size * 64 - 32
    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
    local enemies = FindUnitsInRadius(unit:GetTeamNumber(), location, nil, construction_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_ANY_ORDER, false)
    if #enemies > 0 then
        if callbacks.onConstructionFailed then
            callbacks.onConstructionFailed()
            return false
        end
    end

    return true
end

-- If not all squares are buildable, the area is blocked
function BuildingHelper:IsAreaBlocked( size, location )
    return BuildingHelper:AreaMeetsCriteria( size, location, "BLOCKED", "one" )
end

-- Checks that all squares meet each of the passed grid_type criteria (can be multiple, split by spaces)
function BuildingHelper:AreaMeetsCriteria( size, location, grid_type, option )
    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)
    local halfSize = math.floor(size/2)
    local boundX1 = originX + halfSize
    local boundX2 = originX - halfSize
    local boundY1 = originY + halfSize
    local boundY2 = originY - halfSize

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- Adjust even size
    if (size % 2) == 0 then
        upperBoundX = upperBoundX-1
        upperBoundY = upperBoundY-1
    end

    -- Default by omission is to check if all the cells meet the criteria
    if not option or option == "all" then
        for x = lowerBoundX, upperBoundX do
            for y = lowerBoundY, upperBoundY do
                local grid_types = split(grid_type, " ")
                for k,v in pairs(grid_types) do
                    local t = string.upper(v)
                    local hasGridType = BuildingHelper:CellHasGridType(x,y,t)
                    if not hasGridType then
                        return false
                    end
                end
            end
        end
        return true -- all cells have the grid types

    -- When searching for one block, stop at the first grid point found with every type
    elseif option == "one" then
        for x = lowerBoundX, upperBoundX do
            for y = lowerBoundY, upperBoundY do
                local grid_types = split(grid_type, " ")
                local hasGridType = true
                for k,v in pairs(grid_types) do
                    local t = string.upper(v)
                    hasGridType = hasGridType and BuildingHelper:CellHasGridType(x,y,t)
                end

                if hasGridType then
                    return true
                end
            end
        end
        return false -- no cells meet the criteria
    end
end


--[[
    AddToQueue
    * Adds a location to the builders work queue
    * bQueued will be true if the command was done with shift pressed
    * If bQueued is false, the queue is cleared and this building is put on top
]]--
function BuildingHelper:AddToQueue( builder, location, bQueued )
    local playerID = builder:GetMainControllingPlayer()
    local player = PlayerResource:GetPlayer(playerID)
    local playerTable = BuildingHelper:GetPlayerTable(playerID)
    local buildingName = playerTable.activeBuilding
    local buildingTable = playerTable.activeBuildingTable
    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    local size = buildingTable:GetVal("ConstructionSize", "number")
    local pathing_size = buildingTable:GetVal("BlockGridNavSize", "number")
    local callbacks = playerTable.activeCallbacks

    BuildingHelper:SnapToGrid(size, location)

    -- Check gridnav
    if not BuildingHelper:ValidPosition(size, location, builder, callbacks) then
        return
    end

    -- External pre construction checks
    if callbacks.onPreConstruction then
        local result = callbacks.onPreConstruction(location)
        if result == false then
            return
        end
    end

    BuildingHelper:print("AddToQueue "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> location "..VectorString(location))

    -- Position chosen is initially valid, send callback to spend gold
    callbacks.onBuildingPosChosen(location)

    -- Self placement doesn't make ghost particles on the placement area
    if builder:GetUnitName() == buildingName then
        -- Never queued
        BuildingHelper:ClearQueue(builder)
        table.insert(builder.buildingQueue, {["location"] = location, ["name"] = buildingName, ["buildingTable"] = buildingTable, ["callbacks"] = callbacks})

        BuildingHelper:AdvanceQueue(builder)
        BuildingHelper:print("Starting self placement of "..buildingName)

    else
        -- npc_dota_creature doesn't render cosmetics on the particle ghost, use hero names instead
        local overrideGhost = buildingTable:GetVal("OverrideBuildingGhost", "string")
        local unitName = buildingName
        if overrideGhost then
            unitName = overrideGhost
        end

        -- Create the building entity that will be used to start construction and project the queue particles
        local entity = CreateUnitByName(unitName, location, false, nil, nil, builder:GetTeam())
        entity:AddEffects(EF_NODRAW)
        entity:AddNewModifier(entity, nil, "modifier_out_of_world", {})

        local modelParticle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/ghost_model.vpcf", PATTACH_ABSORIGIN, entity, player)
        ParticleManager:SetParticleControl(modelParticle, 0, location)
        ParticleManager:SetParticleControlEnt(modelParticle, 1, entity, 1, "attach_hitloc", entity:GetAbsOrigin(), true) -- Model attach          
        ParticleManager:SetParticleControl(modelParticle, 3, Vector(BuildingHelper.Settings["MODEL_ALPHA"],0,0)) -- Alpha
        ParticleManager:SetParticleControl(modelParticle, 4, Vector(fMaxScale,0,0)) -- Scale

        local color = BuildingHelper.Settings["RECOLOR_BUILDING_PLACED"] and Vector(0,255,0) or Vector(255,255,255)
        ParticleManager:SetParticleControl(modelParticle, 2, color) -- Color

        -- Create pedestal
        local pedestal = buildingTable:GetVal("PedestalModel")
        local offset = buildingTable:GetVal("PedestalOffset", "float") or 0
        if pedestal then
            local prop = SpawnEntityFromTableSynchronous("prop_dynamic", {model = pedestal})
            local scale = buildingTable:GetVal("PedestalModelScale", "float") or entity:GetModelScale()
            local offset_location = Vector(location.x, location.y, location.z + offset)
            prop:SetModelScale(scale)
            prop:SetAbsOrigin(offset_location)
            entity.prop = prop -- Store the pedestal prop

            prop:AddEffects(EF_NODRAW)
            prop.pedestalParticle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/ghost_model.vpcf", PATTACH_ABSORIGIN, prop, player)
            ParticleManager:SetParticleControl(prop.pedestalParticle, 0, offset_location)
            ParticleManager:SetParticleControlEnt(prop.pedestalParticle, 1, prop, 1, "attach_hitloc", prop:GetAbsOrigin(), true) -- Model attach
            ParticleManager:SetParticleControl(prop.pedestalParticle, 2, color) -- Color
            ParticleManager:SetParticleControl(prop.pedestalParticle, 3, Vector(BuildingHelper.Settings["MODEL_ALPHA"],0,0)) -- Alpha
            ParticleManager:SetParticleControl(prop.pedestalParticle, 4, Vector(scale,0,0)) -- Scale
        end

        -- Adjust the Model Orientation
        local yaw = buildingTable:GetVal("ModelRotation", "float")
        entity:SetAngles(0, -yaw, 0)

        -- If the ability wasn't queued, override the building queue
        if not bQueued then
            BuildingHelper:ClearQueue(builder)
        end

        -- Add this to the builder queue
        table.insert(builder.buildingQueue, {["location"] = location, ["name"] = buildingName, ["buildingTable"] = buildingTable, ["particleIndex"] = modelParticle, ["entity"] = entity, ["callbacks"] = callbacks})

        -- If the builder doesn't have a current work, start the queue
        -- Extra check for builder-inside behaviour, those abilities are always queued
        if builder.work == nil and not builder:HasModifier("modifier_builder_hidden") and not (builder.state == "repairing" or builder.state == "moving_to_repair") then
            builder.work = builder.buildingQueue[1]
            BuildingHelper:AdvanceQueue(builder)
            BuildingHelper:print("Builder doesn't have work to do, start right away")
        else
            BuildingHelper:print("Work was queued, builder already has work to do")
            BuildingHelper:PrintQueue(builder)
        end
    end
end

--[[
      AdvanceQueue
      * Processes an item of the builders work queue
]]--
function BuildingHelper:AdvanceQueue(builder)
    if (builder.move_to_build_timer) then Timers:RemoveTimer(builder.move_to_build_timer) end

    if builder.buildingQueue and #builder.buildingQueue > 0 then
        BuildingHelper:PrintQueue(builder)

        local work = builder.buildingQueue[1]
        table.remove(builder.buildingQueue, 1) --Pop

        local buildingTable = work.buildingTable
        local castRange = buildingTable:GetVal("AbilityCastRange", "number")
        local callbacks = work.callbacks
        local location = work.location
        builder.work = work

        -- Move towards the point at cast range
        builder:MoveToPosition(location)
        builder.move_to_build_timer = Timers:CreateTimer(0.03, function()
            if not IsValidEntity(builder) or not builder:IsAlive() then return end
            builder.state = "moving_to_build"

            local distance = (location - builder:GetAbsOrigin()):Length2D()
            if distance > castRange then
                return 0.03
            else
                builder:Stop()
                
                -- Self placement goes directly to the OnConstructionStarted callback
                if work.name == builder:GetUnitName() then
                    local callbacks = work.callbacks
                    if callbacks.onConstructionStarted then
                        callbacks.onConstructionStarted(builder)
                    end

                else
                    BuildingHelper:StartBuilding(builder)
                end
                return
            end
        end)    
    else
        -- Set the builder work to nil to accept next work directly
        BuildingHelper:print("Builder "..builder:GetUnitName().." "..builder:GetEntityIndex().." finished its building Queue")
        builder.state = "idle"
        builder.work = nil
    end
end

--[[
    ClearQueue
    * Clear the build queue, the player right clicked
]]--
function BuildingHelper:ClearQueue(builder)

    local work = builder.work
    builder.work = nil
    builder.state = "idle"

    BuildingHelper:StopGhost(builder)

    -- Clear movement
    if builder.move_to_build_timer then
        Timers:RemoveTimer(builder.move_to_build_timer)
    end

    -- Skip if there's nothing to clear
    if not builder.buildingQueue or (not work and #builder.buildingQueue == 0) then
        return
    end

    BuildingHelper:print("ClearQueue "..builder:GetUnitName().." "..builder:GetEntityIndex())

    -- Main work  
    if work then
        ParticleManager:DestroyParticle(work.particleIndex, true)
        if work.entity.prop then UTIL_Remove(work.entity.prop) end

        -- Only refund work that hasn't been placed yet
        if not work.inProgress then
            UTIL_Remove(work.entity)
            work.refund = true
        end

        if work.callbacks.onConstructionCancelled ~= nil then
            work.callbacks.onConstructionCancelled(work)
        end
    end

    -- Queued work
    while #builder.buildingQueue > 0 do
        work = builder.buildingQueue[1]
        work.refund = true --Refund this
        ParticleManager:DestroyParticle(work.particleIndex, true)
        if work.entity.prop then UTIL_Remove(work.entity.prop) end
        UTIL_Remove(work.entity)
        table.remove(builder.buildingQueue, 1)

        if work.callbacks.onConstructionCancelled ~= nil then
            work.callbacks.onConstructionCancelled(work)
        end
    end
end

--[[
    StopGhost
    * Stop panorama ghost
]]--
function BuildingHelper:StopGhost( builder )
    local player = builder:GetPlayerOwner()
    local playerID = builder:GetPlayerOwnerID()
    local entIndex = builder:GetEntityIndex()

    local bCurrentlySelected = false
    local selectedEntities = BuildingHelper:GetPlayerTable(playerID).SelectedEntities
    if selectedEntities then
        for _,v in pairs(selectedEntities) do
            if v==entIndex then
                bCurrentlySelected = true
            end
        end
    end

    if bCurrentlySelected then
        CustomGameEventManager:Send_ServerToPlayer(player, "building_helper_end", {})
    end
end


--[[
    PrintQueue
    * Shows the current queued work for this builder
]]--
function BuildingHelper:PrintQueue(builder)
    BuildingHelper:print("Builder Queue of "..builder:GetUnitName().. " "..builder:GetEntityIndex())
    local buildingQueue = builder.buildingQueue
    for k,v in pairs(buildingQueue) do
        BuildingHelper:print(" #"..k..": "..buildingQueue[k]["name"].." at "..VectorString(buildingQueue[k]["location"]))
    end
    BuildingHelper:print("------------------------------------")
end

function BuildingHelper:SnapToGrid( size, location )
    if size % 2 ~= 0 then
        location.x = BuildingHelper:SnapToGrid32(location.x)
        location.y = BuildingHelper:SnapToGrid32(location.y)
    else
        location.x = BuildingHelper:SnapToGrid64(location.x)
        location.y = BuildingHelper:SnapToGrid64(location.y)
    end
end

function BuildingHelper:SnapToGrid64(coord)
    return 64*math.floor(0.5+coord/64)
end

function BuildingHelper:SnapToGrid32(coord)
    return 32+64*math.floor(coord/64)
end

function BuildingHelper:print( ... )
    if BuildingHelper.Settings["TESTING"] then
        print('[BH] '.. ...)
    end
end

function BuildingHelper:GetPlayerTable( playerID )
    if not BuildingHelper.Players[playerID] then
        BuildingHelper.Players[playerID] = {}
        BuildingHelper.Players[playerID].SelectedEntities = {}
    end

    return BuildingHelper.Players[playerID]
end

-- Creates an out of world dummy at map origin and stores it, reducing load from creating units
function BuildingHelper:GetOrCreateDummy( unitName )
    if BuildingHelper.Dummies[unitName] then
        return BuildingHelper.Dummies[unitName]
    else
        BuildingHelper:print("AddBuilding "..unitName)
        local mgd = CreateUnitByName(unitName, Vector(0,0,0), false, nil, nil, 0)
        mgd:AddEffects(EF_NODRAW)
        mgd:AddNewModifier(mgd, nil, "modifier_out_of_world", {})
        BuildingHelper.Dummies[unitName] = mgd
        return mgd
    end
end

function BuildingHelper:GetOrCreateProp( propName )
    if BuildingHelper.Dummies[propName] then
        return BuildingHelper.Dummies[propName]
    else
        local prop = SpawnEntityFromTableSynchronous("prop_dynamic", {model = propName})
        prop:AddEffects(EF_NODRAW)
        BuildingHelper.Dummies[propName] = prop
        return prop
    end
end

-- Retrieves the handle of the ability marked as "RepairAbility" on the unit key values
function BuildingHelper:GetRepairAbility( unit )
    local unitName = unit:GetUnitName()
    local abilityName = BuildingHelper.UnitKV[unitName]["RepairAbility"]
    if not abilityName then
        BuildingHelper:print("Error, no \"RepairAbility\" KV defined for "..unitName)
        return
    end

    local ability = unit:FindAbilityByName(abilityName)
    if not ability then
        BuildingHelper:print("Error, can't find "..abilityName.." on the builder "..unitName)
        return
    else
        return ability
    end
end

function BuildingHelper:GetConstructionSize(unit)
    local unitTable = (type(unit) == "table") and BuildingHelper.UnitKV[unit:GetUnitName()] or BuildingHelper.UnitKV[unit]
    return unitTable["ConstructionSize"]
end

function BuildingHelper:GetBlockPathingSize(unit)
    local unitTable = (type(unit) == "table") and BuildingHelper.UnitKV[unit:GetUnitName()] or BuildingHelper.UnitKV[unit]
    return unitTable["BlockPathingSize"]
end

function BuildingHelper:HideBuilder(unit, location, building)
    unit:AddNewModifier(unit, nil, "modifier_builder_hidden", {})
    unit.entrance_to_build = unit:GetAbsOrigin()

    local location_builder = Vector(location.x, location.y, location.z - 200)
    building.builder_inside = unit
    unit:AddNoDraw()

    Timers:CreateTimer(function()
        unit:SetAbsOrigin(location_builder)
    end)
end

function BuildingHelper:ShowBuilder(unit)
    unit:RemoveModifierByName("modifier_builder_hidden")
    unit:SetAbsOrigin(unit.entrance_to_build)
    unit:RemoveNoDraw()
end

-- Find the closest position of construction_size, within maxDistance
function BuildingHelper:FindClosestEmptyPositionNearby( location, construction_size, maxDistance )
    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)

    local boundX1 = originX + math.floor(maxDistance/64)
    local boundX2 = originX - math.floor(maxDistance/64)
    local boundY1 = originY + math.floor(maxDistance/64)
    local boundY2 = originY - math.floor(maxDistance/64)

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- Restrict to the map edges
    lowerBoundX = math.max(lowerBoundX, -BuildingHelper.squareX/2+1)
    upperBoundX = math.min(upperBoundX, BuildingHelper.squareX/2-1)
    lowerBoundY = math.max(lowerBoundY, -BuildingHelper.squareY/2+1)
    upperBoundY = math.min(upperBoundY, BuildingHelper.squareY/2-1)

    -- Adjust even size
    if (construction_size % 2) == 0 then
        upperBoundX = upperBoundX-1
        upperBoundY = upperBoundY-1
    end

    local towerPos = nil
    local closestDistance = maxDistance

    for x = lowerBoundX, upperBoundX do
        for y = lowerBoundY, upperBoundY do
            if BuildingHelper.Grid[x][y] == GRID_FREE then
                local pos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0)
                BuildingHelper:SnapToGrid(construction_size, pos)
                if not BuildingHelper:IsAreaBlocked(construction_size, pos) then
                    local distance = (pos - location):Length2D()
                    if distance < closestDistance then
                        towerPos = pos
                        closestDistance = distance
                    end
                end
            end
        end
    end
    BuildingHelper:SnapToGrid(construction_size, towerPos)
    return towerPos
end

-- A BuildingHelper ability is identified by the "Building" key.
function IsBuildingAbility( ability )
    if not IsValidEntity(ability) then
        return
    end

    local ability_name = ability:GetAbilityName()
    local ability_table = BuildingHelper.KV[ability_name]
    if ability_table and ability_table["Building"] then
        return true
    end

    return false
end

-- Builders are stored in a nettable in addition to the builder label
function IsBuilder( unit )
    local table = CustomNetTables:GetTableValue("builders", tostring(unit:GetEntityIndex()))
    return unit:GetUnitLabel() == "builder" or (table and (table["IsBuilder"] == "1")) or false
end

function IsCustomBuilding( unit )
    return unit:HasAbility("ability_building") or unit:HasAbility("ability_tower")
end

function PrintGridCoords( pos )
    print('('..string.format("%.1f", pos.x)..','..string.format("%.1f", pos.y)..') = ['.. GridNav:WorldToGridPosX(pos.x)..','..GridNav:WorldToGridPosY(pos.y)..']')
end

function VectorString(v)
    return '[' .. math.floor(v.x) .. ', ' .. math.floor(v.y) .. ', ' .. math.floor(v.z) .. ']'
end

function StringStartsWith( fullstring, substring )
    local strlen = string.len(substring)
    local first_characters = string.sub(fullstring, 1 , strlen)
    return (first_characters == substring)
end

function tobool(s)
    if s=="true" or s=="1" or s==1 then
        return true
    else --nil "false" "0"
        return false
    end
end

local function split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end

function DrawGridSquare( x, y, color )
    local pos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 500)
    BuildingHelper:SnapToGrid(1, pos)
        
    local particle = ParticleManager:CreateParticle("particles/buildinghelper/square_overlay.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, pos)
    ParticleManager:SetParticleControl(particle, 1, Vector(32,0,0))
    ParticleManager:SetParticleControl(particle, 2, color)
    ParticleManager:SetParticleControl(particle, 3, Vector(90,0,0))

    Timers:CreateTimer(10, function() 
        ParticleManager:DestroyParticle(particle, true)
    end)
end

if not BuildingHelper.KV then BuildingHelper:Init() end