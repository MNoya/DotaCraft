--[[
    A library to help make RTS-style and Tower Defense custom games in Dota 2
    Developers: Myll, Noya, snipplets
    Version: 1.0.0
]]--

-- Building Particle Settings
GRID_ALPHA = 30 -- Defines the transparency of the ghost squares (Panorama)
MODEL_ALPHA = 100 -- Defines the transparency of both the ghost model (Panorama) and Building Placed (Lua)
RECOLOR_GHOST_MODEL = true -- Whether to recolor the ghost model green/red or not
RECOLOR_BUILDING_PLACED = true -- Whether to recolor the queue of buildings placed (Lua)

if not BuildingHelper then
    BuildingHelper = class({})
    BuildingAbilities = class({})
end

if not OutOfWorldVector then
    OutOfWorldVector = Vector(11000,11000,0)
end

--[[
    BuildingHelper Init
    * Loads Key Values into the BuildingAbilities
]]--
function BuildingHelper:Init()
    AbilityKVs = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
    ItemKVs = LoadKeyValues("scripts/npc/npc_items_custom.txt")
    UnitKVs = LoadKeyValues("scripts/npc/npc_units_custom.txt")

    DebugPrint("[BH] BuildingHelper Init")

    -- Merge Building abilities coming from both the Ability and Unit KVs
    for i=1,2 do
        local t = AbilityKVs
        if i == 2 then
            t = ItemKVs
        end
        for abil_name,abil_info in pairs(t) do
            if type(abil_info) == "table" then
                local isBuilding = abil_info["Building"]
                if isBuilding ~= nil and tostring(isBuilding) == "1" then
                    BuildingAbilities[tostring(abil_name)] = abil_info
                end
            end
        end
    end
end

--[[
    BuildCommand
    * Detects a Left Click with a builder through Panorama
]]--
function BuildingHelper:BuildCommand( args )
    local x = args['X']
    local y = args['Y']
    local z = args['Z']
    local location = Vector(x, y, z)

    local player = PlayerResource:GetPlayer(args['PlayerID'])
    local queue = tobool(args['Queue'])
    local builder = player.activeBuilder

    DebugPrint("[BH] Build Command - Queued: ",queue)

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
    * Detects a Right Click with a builder through Panorama
]]--
function BuildingHelper:CancelCommand( args )
    local player = PlayerResource:GetPlayer(args['PlayerID'])
    player.activeBuilding = nil

    if not player.activeBuilder then
        return
    end
    BuildingHelper:ClearQueue(player.activeBuilder)
end

--[[
      InitializeBuilder
      * Manages each workers build queue. Will run once per builder
]]--
function BuildingHelper:InitializeBuilder(builder)
    DebugPrint("[BH] InitializeBuilder "..builder:GetUnitName().." "..builder:GetEntityIndex())

    if builder.buildingQueue == nil then
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

    local size = buildingTable:GetVal("BuildingSize", "number")
    local unitName = buildingTable:GetVal("UnitName", "string")

    DebugPrint("[BH] AddBuilding "..unitName)

    -- Prepare the builder, if it hasn't already been done. Since this would need to be done for every builder in some games, might as well do it here.
    local builder = keys.caster

    if not builder.buildingQueue then  
        BuildingHelper:InitializeBuilder(builder)
    end

    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    if fMaxScale == nil then
        -- If no MaxScale is defined, check the "ModelScale" KeyValue. Otherwise just default to 1
        local fModelScale = GameMode.UnitKVs[unitName].ModelScale
        if fModelScale then
          fMaxScale = fModelScale
        else
            fMaxScale = 1
        end
    end
    buildingTable:SetVal("MaxScale", fMaxScale)

    -- Get the local player, this assumes the player is only placing one building at a time
    local player = PlayerResource:GetPlayer(builder:GetMainControllingPlayer())
  
    player.buildingPosChosen = false
    player.activeBuilder = builder
    player.activeBuilding = unitName
    player.activeBuildingTable = buildingTable
    player.activeCallbacks = callbacks

    -- Remove old ghost model dummy
    UTIL_Remove(player.activeBuildingTable.mgd)

    -- Make a model dummy to pass it to panorama
    player.activeBuildingTable.mgd = CreateUnitByName(unitName, OutOfWorldVector, false, nil, nil, builder:GetTeam())

    -- Adjust the Model Orientation
    local yaw = buildingTable:GetVal("ModelRotation", "float")
    player.activeBuildingTable.mgd:SetAngles(0, -yaw, 0)

    -- Position is CP0, model attach is CP1, color is CP2, alpha is CP3.x, scale is CP4.x
    player.activeBuildingTable.modelParticle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/ghost_model.vpcf", PATTACH_ABSORIGIN, player.activeBuildingTable.mgd, player)
    ParticleManager:SetParticleControlEnt(player.activeBuildingTable.modelParticle, 1, player.activeBuildingTable.mgd, 1, "follow_origin", player.activeBuildingTable.mgd:GetAbsOrigin(), true)            
    ParticleManager:SetParticleControl(player.activeBuildingTable.modelParticle, 3, Vector(MODEL_ALPHA,0,0))
    ParticleManager:SetParticleControl(player.activeBuildingTable.modelParticle, 4, Vector(fMaxScale,0,0))

    local color = Vector(255,255,255)
    if RECOLOR_GHOST_MODEL then
        color = Vector(0,255,0)
    end
    ParticleManager:SetParticleControl(player.activeBuildingTable.modelParticle, 2, color)

    local paramsTable = { state = "active", size = size, scale = fMaxScale, 
                          grid_alpha = GRID_ALPHA, model_alpha = MODEL_ALPHA, recolor_ghost = RECOLOR_GHOST_MODEL,
                          entindex = player.activeBuildingTable.mgd:GetEntityIndex(), builderIndex = builder:GetEntityIndex()
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

    local buildingTable = BuildingAbilities[abilityName]

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
    local size = buildingTable:GetVal("BuildingSize", "number")
    if size == nil then
        DebugPrint('[BH] Error: ' .. abilName .. ' does not have a BuildingSize KeyValue')
        return
    end
    if size == 1 then
        DebugPrint('[BH] Warning: ' .. abilName .. ' has a size of 1. Using a gridnav size of 1 is currently not supported, it was increased to 2')
        buildingTable:SetVal("size", 2)
        return
    end

    local unitName = buildingTable:GetVal("UnitName", "string")
    if unitName == nil then
        DebugPrint('[BH] Error: ' .. abilName .. ' does not have a UnitName KeyValue')
        return
    end

    local castRange = buildingTable:GetVal("AbilityCastRange", "number")
    if castRange == nil then
        castRange = 200
    end
    buildingTable:SetVal("AbilityCastRange", castRange)

    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    if fMaxScale == nil then
        -- If no MaxScale is defined, check the "ModelScale" KeyValue. Otherwise just default to 1
        local fModelScale = UnitKVs[unitName].ModelScale
        if fModelScale then
            fMaxScale = fModelScale
        else
            fMaxScale = 1
        end
    end
    buildingTable:SetVal("MaxScale", fMaxScale)

    local fModelRotation = buildingTable:GetVal("ModelRotation", "float")
    if fModelRotation == nil then
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
function BuildingHelper:PlaceBuilding(player, name, location, blockGridNav, size, angle)
  
    local pID = player:GetPlayerID()
    local playersHero = player:GetAssignedHero()
    DebugPrint("[BH] PlaceBuilding for playerID ".. pID)
  
    local gridNavBlockers
    if blockGridNav then
        gridNavBlockers = BuildingHelper:BlockGridNavSquare(size, location)
    end

    -- Spawn the building
    local building = CreateUnitByName(name, location, false, playersHero, player, playersHero:GetTeamNumber())
    building:SetControllableByPlayer(pID, true)
    building:SetOwner(playersHero)
    if blockGridNav then
        building.blockers = gridNavBlockers
    end

    if angle then
        building:SetAngles(0,-angle,0)
    end

    building.state = "complete"

    -- Return the created building
    return building
end

--[[
    RemoveBuilding
    * Removes a building, removing its gridnav blockers, with an optional parameter to kill it
]]--
function BuildingHelper:RemoveBuilding( building, bForcedKill )
    if not building.blockers then 
        return 
    end

    for k, v in pairs(building.blockers) do
        DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
        DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
    end

    if bForcedKill then
        building:ForceKill(bForcedKill)
    end
end

--[[
      StartBuilding
      * Creates the building and starts the construction process
]]--
function BuildingHelper:StartBuilding( keys )
    local builder = keys.caster
    local pID = builder:GetMainControllingPlayer()
    local work = builder.work
    local callbacks = work.callbacks
    local unitName = work.name
    local location = work.location
    local player = PlayerResource:GetPlayer(builder:GetMainControllingPlayer())
    local playersHero = player:GetAssignedHero()
    local buildingTable = work.buildingTable
    local size = buildingTable:GetVal("BuildingSize", "number")

    -- Check gridnav and cancel if invalid
    if not BuildingHelper:ValidPosition(size, location, callbacks) then
        
        -- Remove the model particle and Advance Queue
        BuildingHelper:AdvanceQueue(builder)
        ParticleManager:DestroyParticle(work.particleIndex, true)

        -- Building canceled, refund resources
        work.refund = true
        callbacks.onConstructionCancelled(work)
        return
    end

    DebugPrint("[BH] Initializing Building Entity: "..unitName.." at "..VectorString(location))

    -- Mark this work in progress, skip refund if cancelled as the building is already placed
    work.inProgress = true

    -- Keep the origin of the buildings to put them back in position after spawning point_simple_obstruction entities
    local buildings = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, location, nil, 1000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
    for k,v in pairs(buildings) do
        if IsCustomBuilding(v) then
            v.Origin = v:GetAbsOrigin()
        end
    end

    -- Spawn point obstructions before placing the building
    local gridNavBlockers = BuildingHelper:BlockGridNavSquare(size, location)

    -- Stuck the buildings back in place
    for k,v in pairs(buildings) do
        if IsCustomBuilding(v) then
            v:SetAbsOrigin(v.Origin)
        end
    end

    -- Spawn the building
    local building = CreateUnitByName(unitName, OutOfWorldVector, false, playersHero, player, builder:GetTeam())
    building:SetControllableByPlayer(pID, true)
    building.blockers = gridNavBlockers
    building.buildingTable = buildingTable
    building.state = "building"

    Timers:CreateTimer(function() 
        building:SetAbsOrigin(location)

        -- Remove ghost model
        UTIL_Remove(buildingTable.mgd)
    end)

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
        building:SetControllableByPlayer(playersHero:GetPlayerID(), true)
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
    local masonry_rank = GetCurrentResearchRank(player, "human_research_masonry1")
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

        DebugPrint("[BH] Building needs float adjust")
        if bRequiresRepair then
            DebugPrint("[BH] Error: Don't use Repair with fast-ticking buildings!")
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
                    
                    DebugPrint("[BH] HP was off by:", fMaxHealth - fAddedHealth)

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
            DebugPrint("[BH] Error, can't find "..repair_ability_name.." on the builder ", builder:GetUnitName(), builder:GetEntityIndex())
            return
        end

        --[[ExecuteOrderFromTable({ UnitIndex = builder:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_TARGET, 
                        TargetIndex = building:GetEntityIndex(), AbilityIndex = repair_ability:GetEntityIndex(), Queue = false }) ]]
        builder:CastAbilityOnTarget(building, repair_ability, pID)

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
                    
                    DebugPrint("[BH] Scale was off by:", fMaxScale - fCurrentScale)
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

    DebugPrint("[BH] CancelBuilding "..building:GetUnitName().." "..building:GetEntityIndex())

    -- Refund
    local refund_factor = 0.75
    local gold_cost = math.floor(GetGoldCost(building) * refund_factor)
    local lumber_cost = math.floor(GetLumberCost(building) * refund_factor)

    hero:ModifyGold(gold_cost, true, 0)
    ModifyLumber( hero:GetPlayerOwner(), lumber_cost)
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
        for _,builder in pairs(builders) do
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
                    building:CastAbilityImmediately(item, building:GetPlayerOwnerID())
                end)
            end
        end
    end

    -- Special for RequiresRepair
    local units_repairing = building.units_repairing
    if units_repairing then
        for k,builder in pairs(units_repairing) do
            builder:RemoveModifierByName("modifier_on_order_cancel_repair")
            builder:RemoveModifierByName("modifier_peasant_repairing")
            local race = GetUnitRace(builder)
            local repair_ability = builder:FindAbilityByName(race.."_gather")
            ToggleOff(repair_ability)
        end
    end

    building.state = "canceled"
    Timers:CreateTimer(1/5, function() 
        BuildingHelper:RemoveBuilding(building, true)
    end)
end

--[[
      BlockGridNavSquare
      * Blocks GridNav square of certain size at a location
]]--
function BuildingHelper:BlockGridNavSquare(size, location)

    SnapToGrid(size, location)

    local gridNavBlockers = {}
    if size == 5 then
        for x = location.x - (size-2) * 32, location.x + (size-2) * 32, 64 do
            for y = location.y - (size-2) * 32, location.y + (size-2) * 32, 64 do
                local blockerLocation = Vector(x, y, location.z)
                local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
                table.insert(gridNavBlockers, ent)
            end
        end
    elseif size == 3 then
        for x = location.x - (size / 2) * 32 , location.x + (size / 2) * 32 , 64 do
            for y = location.y - (size / 2) * 32 , location.y + (size / 2) * 32 , 64 do
                local blockerLocation = Vector(x, y, location.z)
                local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
                table.insert(gridNavBlockers, ent)
            end
        end
    else
        for x = location.x - (size / 2) * 32 + 16, location.x + (size / 2) * 32 - 16, 96 do
            for y = location.y - (size / 2) * 32 + 16, location.y + (size / 2) * 32 - 16, 96 do
                local blockerLocation = Vector(x, y, location.z)
                local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
                table.insert(gridNavBlockers, ent)
            end
        end
    end
    return gridNavBlockers
end

--[[
      ValidPosition
      * Checks GridNav square of certain size at a location
      * Sends onConstructionFailed if invalid
]]--
function BuildingHelper:ValidPosition(size, location, callbacks)

    local halfSide = (size/2)*64
    local boundingRect = {  leftBorderX = location.x-halfSide, 
                            rightBorderX = location.x+halfSide, 
                            topBorderY = location.y+halfSide,
                            bottomBorderY = location.y-halfSide }

    for x=boundingRect.leftBorderX+32,boundingRect.rightBorderX-32,64 do
        for y=boundingRect.topBorderY-32,boundingRect.bottomBorderY+32,-64 do
            local testLocation = Vector(x, y, location.z)
            if GridNav:IsBlocked(testLocation) or GridNav:IsTraversable(testLocation) == false then
                if callbacks.onConstructionFailed then
                    callbacks.onConstructionFailed()
                    return false
                end
            end
        end
    end
    return true
end

--[[
    AddToQueue
    * Adds a location to the builders work queue
    * bQueued will be true if the command was done with shift pressed
    * If bQueued is false, the queue is cleared and this building is put on top
]]--
function BuildingHelper:AddToQueue( builder, location, bQueued )
    local player = PlayerResource:GetPlayer(builder:GetMainControllingPlayer())
    local building = player.activeBuilding
    local buildingTable = player.activeBuildingTable
    local fMaxScale = buildingTable:GetVal("MaxScale", "float")
    local size = buildingTable:GetVal("BuildingSize", "number")
    local callbacks = player.activeCallbacks

    SnapToGrid(size, location)

    -- Check gridnav
    if not BuildingHelper:ValidPosition(size, location, callbacks) then
        return
    end

    -- External pre construction checks
    if callbacks.onPreConstruction then
        local result = callbacks.onPreConstruction(location)
        if result == false then
            return
        end
    end

    DebugPrint("[BH] AddToQueue "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> location "..VectorString(location))

    -- Position chosen is initially valid, send callback to spend gold
    callbacks.onBuildingPosChosen(location)

    -- Create model ghost dummy out of the map, then make pretty particles
    local mgd = CreateUnitByName(building, OutOfWorldVector, false, nil, nil, builder:GetTeam())

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
    table.insert(builder.buildingQueue, {["location"] = location, ["name"] = building, ["buildingTable"] = buildingTable, ["particleIndex"] = modelParticle, ["callbacks"] = callbacks})

    -- If the builder doesn't have a current work, start the queue
    -- Extra check for builder-inside behaviour, those abilities are always queued
    if builder.work == nil and not builder:HasModifier("modifier_builder_hidden") and not (builder.state == "repairing" or builder.state == "moving_to_repair") then
        builder.work = builder.buildingQueue[1]
        BuildingHelper:AdvanceQueue(builder)
        DebugPrint("[BH] Builder doesn't have work to do, start right away")
    else
        DebugPrint("[BH] Work was queued, builder already has work to do")
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
        if AbilityKVs[abilName] == nil then
            DebugPrint('[BH] Error: ' .. abilName .. ' was not found in npc_abilities_custom.txt. Using the ability move_to_point_100')
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

            DebugPrint("[BH] AdvanceQueue - "..builder:GetUnitName().." "..builder:GetEntityIndex().." moving to build "..work.name.." at "..VectorString(location))
        end)
    
    else
        -- Set the builder work to nil to accept next work directly
        DebugPrint("[BH] Builder "..builder:GetUnitName().." "..builder:GetEntityIndex().." finished its building Queue")
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

     -- Stop panorama ghost
    local player = builder:GetPlayerOwner()
    CustomGameEventManager:Send_ServerToPlayer(player, "building_helper_end", {})

    -- Skip if there's nothing to clear
    if not builder.buildingQueue or (not work and #builder.buildingQueue == 0) then
        return
    end

    DebugPrint("[BH] ClearQueue "..builder:GetUnitName().." "..builder:GetEntityIndex())

    -- Main work  
    if work then
        ParticleManager:DestroyParticle(work.particleIndex, true)

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
        table.remove(builder.buildingQueue, 1)

        if work.callbacks.onConstructionCancelled ~= nil then
            work.callbacks.onConstructionCancelled(work)
        end
    end
end

--[[
    PrintQueue
    * Shows the current queued work for this builder
]]--
function BuildingHelper:PrintQueue(builder)
    DebugPrint("[BH] Builder Queue of "..builder:GetUnitName().. " "..builder:GetEntityIndex())
    local buildingQueue = builder.buildingQueue
    for k,v in pairs(buildingQueue) do
        DebugPrint(" #"..k..": "..buildingQueue[k]["name"].." at "..VectorString(buildingQueue[k]["location"]))
    end
    print("------------------------------------")
end

function SnapToGrid( size, location )
    if size % 2 ~= 0 then
        location.x = SnapToGrid32(location.x)
        location.y = SnapToGrid32(location.y)
    else
        location.x = SnapToGrid64(location.x)
        location.y = SnapToGrid64(location.y)
    end
end

function SnapToGrid64(coord)
    return 64*math.floor(0.5+coord/64)
end

function SnapToGrid32(coord)
    return 32+64*math.floor(coord/64)
end

BuildingHelper:Init()