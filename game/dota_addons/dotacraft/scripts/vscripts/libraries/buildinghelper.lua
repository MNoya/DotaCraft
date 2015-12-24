BH_VERSION = "1.0"

--[[
    TODO: Explain stuff
    * Grid
    * Terrain
    * Entities
]]--

-- Building Particle Settings
GRID_ALPHA = 30 -- Defines the transparency of the ghost squares (Panorama)
MODEL_ALPHA = 100 -- Defines the transparency of both the ghost model (Panorama) and Building Placed (Lua)
RECOLOR_GHOST_MODEL = true -- Whether to recolor the ghost model green/red or not
RECOLOR_BUILDING_PLACED = true -- Whether to recolor the queue of buildings placed (Lua)

BH_PRINT = true --Turn this off on production

if not BuildingHelper then
    BuildingHelper = class({})
end

--[[
    BuildingHelper Init
    * Loads Key Values into the BuildingAbilities
]]--
function BuildingHelper:Init()
    BuildingHelper.AbilityKVs = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
    BuildingHelper.ItemKVs = LoadKeyValues("scripts/npc/npc_items_custom.txt")
    BuildingHelper.UnitKVs = LoadKeyValues("scripts/npc/npc_units_custom.txt")

    BuildingHelper:print("BuildingHelper Init")
    BuildingHelper.Players = {} -- Holds a table for each player ID

    BuildingHelper.Grid = {}    -- Construction grid
    BuildingHelper.Terrain = {} -- Terrain grid, this only changes when a tree is cut
    BuildingHelper.Encoded = "" -- String containing the base terrain, networked to clients
    BuildingHelper.squareX = 0  -- Number of X grid points
    BuildingHelper.squareY = 0  -- Number of Y grid points

    -- Grid States
    GRID_BLOCKED = 1
    GRID_FREE = 2

    CustomGameEventManager:RegisterListener("building_helper_build_command", Dynamic_Wrap(BuildingHelper, "BuildCommand"))
    CustomGameEventManager:RegisterListener("building_helper_cancel_command", Dynamic_Wrap(BuildingHelper, "CancelCommand"))
    CustomGameEventManager:RegisterListener("gnv_request", Dynamic_Wrap(BuildingHelper, "SendGNV"))

    LinkLuaModifier("modifier_out_of_world", "libraries/modifiers/modifier_out_of_world", LUA_MODIFIER_MOTION_NONE)

    ListenToGameEvent('game_rules_state_change', function()
        local newState = GameRules:State_Get()
        if newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
            -- The base terrain GridNav is obtained directly from the vmap
            BuildingHelper:InitGNV()
        end
    end, nil)

    ListenToGameEvent('tree_cut', function(keys)
        local treePos = Vector(keys.tree_x,keys.tree_y,0)

        -- Create a dummy for clients to be able to detect trees standing and block their grid
        CreateUnitByName("tree_chopped", treePos, false, nil, nil, 0)

        if not BuildingHelper:IsAreaBlocked(2, treePos) then
            BuildingHelper:FreeGridSquares(2, treePos)
        end
    end, nil)

    BuildingHelper.KV = {} -- Merge KVs into a single table
    BuildingHelper:ParseKV(BuildingHelper.AbilityKVs, BuildingHelper.KV)
    BuildingHelper:ParseKV(BuildingHelper.ItemKVs, BuildingHelper.KV)
    BuildingHelper:ParseKV(BuildingHelper.UnitKVs, BuildingHelper.KV)
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

                -- Build NetTable with the grid sizes
                if info['ConstructionSize'] then
                    CustomNetTables:SetTableValue("construction_size", name, {size = info['ConstructionSize']})
                end
            end
        end
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
            local terrainBlocked = not GridNav:IsTraversable(position) or GridNav:IsBlocked(position) and not treeBlocked

            if terrainBlocked then
                BuildingHelper.Terrain[x][y] = GRID_BLOCKED
                byte = byte + bit.lshift(2,shift)
                blockedCount = blockedCount+1
            else
                BuildingHelper.Terrain[x][y] = GRID_FREE
                byte = byte + bit.lshift(1,shift)
                unblockedCount = unblockedCount+1
            end

            --Trees aren't networked but detected as ent_dota_tree entities on clients
            if treeBlocked then
                BuildingHelper.Terrain[x][y] = GRID_BLOCKED
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
    local queue = tobool(args['Queue'])
    local builder = EntIndexToHScript(args['builder']) --activeBuilder

    BuildingHelper:print("Build Command - Queued: ",queue)

    -- Cancel current repair
    if builder:HasModifier("modifier_builder_repairing") and not queue then
        local race = GetUnitRace(builder)
        local repair_ability = builder:FindAbilityByName(race.."_gather")
        local event = {}
        event.caster = builder
        event.ability = repair_ability
        BuilderStopRepairing(event)
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

    if not playerTable.activeBuilder then
        return
    end
    BuildingHelper:ClearQueue(playerTable.activeBuilder)
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

--[[
    AddBuilding
    * Makes a building dummy and starts panorama ghosting
    * Builder calls this and sets the callbacks with the required values
]]--
function BuildingHelper:AddBuilding(keys)
    -- Callbacks
    callbacks = BuildingHelper:SetCallbacks(keys)

    local ability = keys.ability
    local abilName = ability:GetAbilityName()
    local buildingTable = BuildingHelper:SetupBuildingTable(abilName) 

    buildingTable:SetVal("AbilityHandle", ability)

    local size = buildingTable:GetVal("ConstructionSize", "number")
    local unitName = buildingTable:GetVal("UnitName", "string")

    BuildingHelper:print("AddBuilding "..unitName)

    -- Prepare the builder, if it hasn't already been done. Since this would need to be done for every builder in some games, might as well do it here.
    local builder = keys.caster

    if not builder.buildingQueue then  
        BuildingHelper:InitializeBuilder(builder)
    end

    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    if not fMaxScale then
        -- If no MaxScale is defined, check the "ModelScale" KeyValue. Otherwise just default to 1
        local fModelScale = BuildingHelper.UnitKVs[unitName].ModelScale
        if fModelScale then
          fMaxScale = fModelScale
        else
            fMaxScale = 1
        end
    end
    buildingTable:SetVal("MaxScale", fMaxScale)

    -- Set the active variables and callbacks
    local playerID = builder:GetMainControllingPlayer()
    local player = PlayerResource:GetPlayer(playerID)
    local playerTable = BuildingHelper:GetPlayerTable(playerID)
    playerTable.activeBuilder = builder
    playerTable.activeBuilding = unitName
    playerTable.activeBuildingTable = buildingTable
    playerTable.activeCallbacks = callbacks

    -- Remove old ghost model dummy
    UTIL_Remove(playerTable.activeBuildingTable.mgd)

    -- Make a model dummy to pass it to panorama
    local mgd = CreateUnitByName(unitName, builder:GetAbsOrigin(), false, nil, nil, builder:GetTeam())
    mgd:AddNoDraw()
    mgd:AddNewModifier(mgd, nil, "modifier_out_of_world", {})
    playerTable.activeBuildingTable.mgd = mgd

    -- Adjust the Model Orientation
    local yaw = buildingTable:GetVal("ModelRotation", "float")
    mgd:SetAngles(0, -yaw, 0)

    local color = Vector(255,255,255)
    if RECOLOR_GHOST_MODEL then
        color = Vector(0,255,0)
    end

    local paramsTable = { state = "active", size = size, scale = fMaxScale, 
                          grid_alpha = GRID_ALPHA, model_alpha = MODEL_ALPHA, recolor_ghost = RECOLOR_GHOST_MODEL,
                          entindex = mgd:GetEntityIndex(), builderIndex = builder:GetEntityIndex()
                        }
    CustomGameEventManager:Send_ServerToPlayer(player, "building_helper_enable", paramsTable)
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

    function keys:EnableFireEffect( sFireEffect )
        callbacks.fireEffect = sFireEffect
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
function BuildingHelper:SetupBuildingTable( abilityName )

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
            return tobool(sVal)
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

    -- Ensure that the unit actually exists
    local unitTable = BuildingHelper.UnitKVs[unitName]
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

    local pathing_size = unitTable["BlockPathingSize"]
    if not pathing_size then
        BuildingHelper:print('Warning: Unit ' .. unitName .. ' does not have a BlockPathingSize KeyValue. Defaulting to 0')
        pathing_size = 0
    end
    buildingTable:SetVal("BlockPathingSize", pathing_size)

    local castRange = buildingTable:GetVal("AbilityCastRange", "number")
    if not castRange then
        castRange = 200
    end
    buildingTable:SetVal("AbilityCastRange", castRange)

    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    if not fMaxScale then
        -- If no MaxScale is defined, check the Units "ModelScale" KeyValue. Otherwise just default to 1
        local fModelScale = BuildingHelper.UnitKVs[unitName].ModelScale
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
    
    local playerID = player:GetPlayerID()
    local playersHero = PlayerResource:GetSelectedHeroEntity(playerID)
    BuildingHelper:print("PlaceBuilding for playerID ".. playerID)

    -- Keep the origin of the buildings to put them back in position after spawning point_simple_obstruction entities
    local buildings = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, location, nil, construction_size*128, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
    for k,v in pairs(buildings) do
        if IsCustomBuilding(v) then
            v.Origin = v:GetAbsOrigin()
        end
    end

    -- Spawn point obstructions before placing the building
    local gridNavBlockers = BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)

    -- Stuck the buildings back in place
    for k,v in pairs(buildings) do
        if IsCustomBuilding(v) then
            v:SetAbsOrigin(v.Origin)
        end
    end

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
function BuildingHelper:StartBuilding( keys )
    local builder = keys.caster
    local playerID = builder:GetMainControllingPlayer()
    local work = builder.work
    local callbacks = work.callbacks
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

        -- Building canceled, refund resources
        work.refund = true
        callbacks.onConstructionCancelled(work)
        return
    end

    BuildingHelper:print("Initializing Building Entity: "..unitName.." at "..VectorString(location))

    -- Mark this work in progress, skip refund if cancelled as the building is already placed
    work.inProgress = true

    -- Keep the origin of the buildings to put them back in position after spawning point_simple_obstruction entities
    local buildings = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, location, nil, construction_size*128, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
    for k,v in pairs(buildings) do
        if IsCustomBuilding(v) then
            v.Origin = v:GetAbsOrigin()
        end
    end

    -- Spawn point obstructions before placing the building
    local gridNavBlockers = BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)

    -- Stuck the buildings back in place
    for k,v in pairs(buildings) do
        if IsCustomBuilding(v) then
            v:SetAbsOrigin(v.Origin)
        end
    end

    -- Spawn the building
    local building = CreateUnitByName(unitName, location, false, playersHero, player, builder:GetTeam())
    building:SetControllableByPlayer(playerID, true)
    building.blockers = gridNavBlockers
    building.construction_size = construction_size
    building.buildingTable = buildingTable
    building.state = "building"

    -- Adjust the Model Orientation
    local yaw = buildingTable:GetVal("ModelRotation", "float")
    building:SetAngles(0, -yaw, 0)

    -- Prevent regen messing with the building spawn hp gain
    local regen = building:GetBaseHealthRegen()
    building:SetBaseHealthRegen(0)

    local buildTime = buildingTable:GetVal("BuildTime", "float")
    if buildTime == nil then
        buildTime = .1
    end

     -- Cheat Code: Instant placement (skips construction process)
    if GameRules.WarpTen then
        buildTime = .1
    end

    -- the gametime when the building should be completed.
    local fTimeBuildingCompleted=GameRules:GetGameTime()+buildTime

    ------------------------------------------------------------------
    -- Build Behaviours
    --  RequiresRepair: If set to 1 it will place the building and not update its health nor send the OnConstructionCompleted callback until its fully healed
    --  BuilderInside: Puts the builder unselectable/invulnerable/nohealthbar inside the building in construction
    --  ConsumesBuilder: Kills the builder after the construction is done
    local bRequiresRepair = buildingTable:GetVal("RequiresRepair", "bool")
    local bBuilderInside = buildingTable:GetVal("BuilderInside", "bool")
    local bConsumesBuilder = buildingTable:GetVal("ConsumesBuilder", "bool")
    -------------------------------------------------------------------

    -- whether we should scale the building.
    local bScale = buildingTable:GetVal("Scale", "bool")

    -- whether the building is controllable or not
    local bPlayerCanControl = buildingTable:GetVal("PlayerCanControl", "bool")
    if bPlayerCanControl then
        building:SetControllableByPlayer(playerID, true)
        building:SetOwner(playersHero)
    end

    -- the amount to scale to.
    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    if fMaxScale == nil then
        fMaxScale = 1
    end

    -- Dota server updates at 30 frames per second
    local fserverFrameRate = 1/30

    -- Max and Initial Health factor
    local masonry_rank = Players:GetCurrentResearchRank(player:GetPlayerID(), "human_research_masonry1")
    local fMaxHealth = building:GetMaxHealth() * (1 + 0.2 * masonry_rank) 
    local nInitialHealth = 0.10 * ( fMaxHealth )
    local fUpdateHealthInterval = buildTime / math.floor(fMaxHealth-nInitialHealth) -- health to add every tick until build time is completed.
    ---------------------------------------------------------------------

    -- Update model size, starting with an initial size
    local fInitialModelScale = 0.2

    -- scale to add every frame, distributed by build time
    local fScaleInterval = (fMaxScale-fInitialModelScale) / (buildTime / fserverFrameRate)

    -- start the building at the initial model scale
    local fCurrentScale = fInitialModelScale
    local bScaling = false -- Keep tracking if we're currently model scaling.
    
    building:SetHealth(nInitialHealth)
    building.bUpdatingHealth = true

    -- Set initial scale
    if bScale then
        building:SetModelScale(fCurrentScale)
        bScaling=true
    end

    -- Put the builder invulnerable inside the building in construction
    if bBuilderInside then
        ApplyModifier(builder, "modifier_builder_hidden")
        builder.entrance_to_build = builder:GetAbsOrigin()
        
        local location_builder = Vector(location.x, location.y, location.z - 200)
        building.builder_inside = builder
        builder:AddNoDraw()

        Timers:CreateTimer(function()
            builder:SetAbsOrigin(location_builder)
        end)
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
                    
                    BuildingHelper:print("HP was off by:", fMaxHealth - fAddedHealth)

                    -- Eject Builder
                    if bBuilderInside then
                    
                        -- Consume Builder
                        if bConsumesBuilder then
                            builder:ForceKill(true)
                        else
                        
                            builder:RemoveModifierByName("modifier_builder_hidden")
                            builder:SetAbsOrigin(builder.entrance_to_build)
                            builder:RemoveNoDraw()
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
                        
                            builder:RemoveModifierByName("modifier_builder_hidden")
                            builder:SetAbsOrigin(builder.entrance_to_build)
                            builder:RemoveNoDraw()
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
        local race = GetUnitRace(builder)
        local repair_ability_name = race.."_gather"
        local repair_ability = builder:FindAbilityByName(repair_ability_name)
        if not repair_ability then
            BuildingHelper:print("Error, can't find "..repair_ability_name.." on the builder ", builder:GetUnitName(), builder:GetEntityIndex())
            return
        end

        --[[ExecuteOrderFromTable({ UnitIndex = builder:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_TARGET, 
                        TargetIndex = building:GetEntityIndex(), AbilityIndex = repair_ability:GetEntityIndex(), Queue = false }) ]]
        builder:CastAbilityOnTarget(building, repair_ability, playerID)

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
                    
                    BuildingHelper:print("Scale was off by:", fMaxScale - fCurrentScale)
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
        if IsValidEntity(building) then
            if building:GetHealth() < fMaxHealth/2.0 and not building.onBelowHalfHealthProc and not building.bUpdatingHealth then
                if callbacks.fireEffect then
                    building:AddNewModifier(building, nil, callbacks.fireEffect, nil)
                end
            
                callbacks.onBelowHalfHealth(building)
                building.onBelowHalfHealthProc = true
            elseif building:GetHealth() >= fMaxHealth/2.0 and building.onBelowHalfHealthProc and not building.bUpdatingHealth then
                if callbacks.fireEffect then
                    building:RemoveModifierByName(callbacks.fireEffect)
                end
                callbacks.onAboveHalfHealth(building)
                building.onBelowHalfHealthProc = false
            end
        else
            return nil
        end

        return .2
    end)

    if callbacks.onConstructionStarted then
        callbacks.onConstructionStarted(building)
    end

    -- Remove the model particle
    ParticleManager:DestroyParticle(work.particleIndex, true)
end

--[[
      CancelBuilding
      * Cancels the building
      * Refunds the cost by a factor
]]
function BuildingHelper:CancelBuilding(keys)
    local building = keys.unit
    local hero = building:GetOwner()
    local playerID = hero:GetPlayerID()

    BuildingHelper:print("CancelBuilding "..building:GetUnitName().." "..building:GetEntityIndex())

    -- Refund
    local refund_factor = 0.75
    local gold_cost = math.floor(GetGoldCost(building) * refund_factor)
    local lumber_cost = math.floor(GetLumberCost(building) * refund_factor)

    Players:ModifyGold(playerID, gold_cost)
    Players:ModifyLumber(playerID, lumber_cost)
    PopupGoldGain(building, gold_cost)
    PopupLumber(building, lumber_cost)

    -- Eject builder
    local builder = building.builder_inside
    if builder then   
        builder:SetAbsOrigin(building:GetAbsOrigin())
    end

    -- Cancel builders repairing
    local builders = building.units_repairing
    if builders then
        -- Remove the modifiers on the building and the builders
        building:RemoveModifierByName("modifier_repairing_building")
        for _,v in pairs(builders) do
            local builder = EntIndexToHScript(v)
            if builder and IsValidEntity(builder) then
                builder:RemoveModifierByName("modifier_builder_repairing")

                builder.state = "idle"
                BuildingHelper:AdvanceQueue(builder)

                local ability = builder:FindAbilityByName("human_gather")
                if ability then 
                    ToggleOff(ability)
                end
            end
        end
    end

    -- Refund items (In the item-queue system, units can be queued before the building is finished)
    for i=0,5 do
        local item = building:GetItemInSlot(i)
        if item then
            if item:GetAbilityName() == "item_building_cancel" then
                item:RemoveSelf()
            else
                Timers:CreateTimer(i*1/30, function() 
                    building:CastAbilityImmediately(item, playerID)
                end)
            end
        end
    end

    -- Special for RequiresRepair
    local units_repairing = building.units_repairing
    if units_repairing then
        for k,v in pairs(units_repairing) do
            local builder = EntIndexToHScript(v)
            if builder and IsValidEntity(builder) then
                builder:RemoveModifierByName("modifier_on_order_cancel_repair")
                builder:RemoveModifierByName("modifier_peasant_repairing")
                local race = GetUnitRace(builder)
                local repair_ability = builder:FindAbilityByName(race.."_gather")
                ToggleOff(repair_ability)
            end
        end
    end

    building.state = "canceled"
    Timers:CreateTimer(1/5, function() 
        BuildingHelper:RemoveBuilding(building, true)
    end)
end

--[[
      BlockGridSquares
      * Blocks a square of certain construction and pathing size at a location on the server grid
      * construction_size: square of grid points to block from construction
      * pathing_size: square of pathing obstructions that will be spawned 
]]--
function BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)
    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)

    local boundX1 = originX + math.floor(construction_size/2)
    local boundX2 = originX - math.floor(construction_size/2)
    local boundY1 = originY + math.floor(construction_size/2)
    local boundY2 = originY - math.floor(construction_size/2)

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- Adjust even size
    if (construction_size % 2) == 0 then
        upperBoundX = upperBoundX-1
        upperBoundY = upperBoundY-1
    end

    for x = lowerBoundX, upperBoundX do
        for y = lowerBoundY, upperBoundY do
            BuildingHelper.Grid[x][y] = GRID_BLOCKED
        end
    end

    return BuildingHelper:BlockPSO(pathing_size, location)
end

--[[
      BlockPSO
      * Spawns a square of point_simple_obstruction entities at a location
]]--
function BuildingHelper:BlockPSO(size, location)
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

    return gridNavBlockers
end

--[[
      FreeGridSquares
      * Clears out an area for construction
]]--
function BuildingHelper:FreeGridSquares(construction_size, location)
    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)

    local boundX1 = originX + math.floor(construction_size/2)
    local boundX2 = originX - math.floor(construction_size/2)
    local boundY1 = originY + math.floor(construction_size/2)
    local boundY2 = originY - math.floor(construction_size/2)

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- Adjust even size
    if (construction_size % 2) == 0 then
        upperBoundX = upperBoundX-1
        upperBoundY = upperBoundY-1
    end

    for x = lowerBoundX, upperBoundX do
        for y = lowerBoundY, upperBoundY do
            BuildingHelper.Grid[x][y] = GRID_FREE
        end
    end
end

--[[
      ValidPosition
      * Checks GridNav square of certain size at a location
      * Sends onConstructionFailed if invalid
]]--
function BuildingHelper:ValidPosition(size, location, unit, callbacks)
    local bBlocked = BuildingHelper:IsAreaBlocked(size, location)
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

function BuildingHelper:IsAreaBlocked( size, location )
    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)

    local boundX1 = originX + math.floor(size/2)
    local boundX2 = originX - math.floor(size/2)
    local boundY1 = originY + math.floor(size/2)
    local boundY2 = originY - math.floor(size/2)

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    -- Adjust even size
    if (size % 2) == 0 then
        upperBoundX = upperBoundX-1
        upperBoundY = upperBoundY-1
    end

    for x = lowerBoundX, upperBoundX do
        for y = lowerBoundY, upperBoundY do
            if BuildingHelper.Grid[x][y] == GRID_BLOCKED then
                return true
            end
        end
    end
    return false
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
    local building = playerTable.activeBuilding
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

    -- Create model ghost dummy out of the map, then make pretty particles
    local mgd = CreateUnitByName(building, location, false, nil, nil, builder:GetTeam())
    mgd:AddNoDraw()
    mgd:AddNewModifier(mgd, nil, "modifier_out_of_world", {})

    local modelParticle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/ghost_model.vpcf", PATTACH_ABSORIGIN, mgd, player)
    ParticleManager:SetParticleControl(modelParticle, 0, location)
    ParticleManager:SetParticleControlEnt(modelParticle, 1, mgd, 1, "follow_origin", mgd:GetAbsOrigin(), true) -- Model attach          
    ParticleManager:SetParticleControl(modelParticle, 3, Vector(MODEL_ALPHA,0,0)) -- Alpha
    ParticleManager:SetParticleControl(modelParticle, 4, Vector(fMaxScale,0,0)) -- Scale

    -- Adjust the Model Orientation
    local yaw = buildingTable:GetVal("ModelRotation", "float")
    mgd:SetAngles(0, -yaw, 0)
    
    local color = Vector(255,255,255)
    if RECOLOR_BUILDING_PLACED then
        color = Vector(0,255,0)
    end
    ParticleManager:SetParticleControl(modelParticle, 2, color) -- Color

    -- If the ability wasn't queued, override the building queue
    if not bQueued then
        BuildingHelper:ClearQueue(builder)
    end

    -- Add this to the builder queue
    table.insert(builder.buildingQueue, {["location"] = location, ["name"] = building, ["buildingTable"] = buildingTable, ["particleIndex"] = modelParticle, ["entity"] = mgd, ["callbacks"] = callbacks})

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

--[[
      AdvanceQueue
      * Processes an item of the builders work queue
]]--
function BuildingHelper:AdvanceQueue(builder)
    if builder.buildingQueue and #builder.buildingQueue > 0 then
        BuildingHelper:PrintQueue(builder)

        local work = builder.buildingQueue[1]
        table.remove(builder.buildingQueue, 1) --Pop

        local buildingTable = work.buildingTable
        local castRange = buildingTable:GetVal("AbilityCastRange", "number")
        local callbacks = work.callbacks
        local location = work.location
        builder.work = work

        -- Make the caster move towards the point
        local abilName = "move_to_point_" .. tostring(castRange)
        if BuildingHelper.AbilityKVs[abilName] == nil then
            BuildingHelper:print('Error: ' .. abilName .. ' was not found in npc_abilities_custom.txt. Using the ability move_to_point_100')
            abilName = "move_to_point_100"
        end

        -- If unit has other move_to_point abils, we should clean them up here
        for i=0,15 do
            local abil = builder:GetAbilityByIndex(i)
            if abil then
                local name = abil:GetAbilityName()
                if name ~= abilName and StringStartsWith(name, "move_to_point_") then
                    builder:RemoveAbility(name)
                end
            end
        end

        if not builder:HasAbility(abilName) then
            builder:AddAbility(abilName)
        end
        local abil = builder:FindAbilityByName(abilName)
        abil:SetLevel(1)

        Timers:CreateTimer(function()
            builder:CastAbilityOnPosition(location, abil, 0)

            -- Change builder state
            builder.state = "moving_to_build"

            BuildingHelper:print("AdvanceQueue - "..builder:GetUnitName().." "..builder:GetEntityIndex().." moving to build "..work.name.." at "..VectorString(location))
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

    -- Skip if there's nothing to clear
    if not builder.buildingQueue or (not work and #builder.buildingQueue == 0) then
        return
    end

    BuildingHelper:print("ClearQueue "..builder:GetUnitName().." "..builder:GetEntityIndex())

    -- Main work  
    if work then
        ParticleManager:DestroyParticle(work.particleIndex, true)
        UTIL_Remove(work.entity)

        -- Only refund work that hasn't been placed yet
        if not work.inProgress then
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

    local playerTable = BuildingHelper:GetPlayerTable(builder:GetPlayerOwnerID())
    if playerTable.activeBuildingTable and IsValidEntity(playerTable.activeBuildingTable.mgd) then
        UTIL_Remove(playerTable.activeBuildingTable.mgd)
    end

    if IsCurrentlySelected(builder) then
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
    if BH_PRINT then
        print('[BH] '.. ...)
    end
end

function BuildingHelper:GetPlayerTable( playerID )
    if not BuildingHelper.Players[playerID] then
        BuildingHelper.Players[playerID] = {}
    end

    return BuildingHelper.Players[playerID]
end

function PrintGridCoords( pos )
    print('('..string.format("%.1f", pos.x)..','..string.format("%.1f", pos.y)..') = ['.. GridNav:WorldToGridPosX(pos.x)..','..GridNav:WorldToGridPosY(pos.y)..']')
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