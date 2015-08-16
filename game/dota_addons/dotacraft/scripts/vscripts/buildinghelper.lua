--[[
  A library to help make RTS-style and Tower Defense custom games in Dota 2
  Developer: Myll
  Version: 2.0
  Credits to:
    Ash47 and BMD for timers.lua.
    BMD for helping figure out how to get mouse clicks in Flash.
    Perry for writing FlashUtil, which contains functions for cursor tracking.
]]
-- Rewritten with multiplayer + shift queue in mind

if not BuildingHelper then
  BuildingHelper = class({})
  BuildingAbilities = class({})
end

if not OutOfWorldVector then
  OutOfWorldVector = Vector(11000,11000,0)
end

MODEL_ALPHA = 100 -- Defines the transparency of the ghost model.



function BuildingHelper:Init(...)
  AbilityKVs = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
  ItemKVs = LoadKeyValues("scripts/npc/npc_items_custom.txt")
  UnitKVs = LoadKeyValues("scripts/npc/npc_units_custom.txt")
  -- abils and items can't have the same name or the item will override the ability.

  for i=1,2 do
    local t = AbilityKVs
    if i == 2 then
      t = ItemKVs
    end
    for abil_name,abil_info in pairs(t) do
      if type(abil_info) == "table" then
        local isBuilding = abil_info["Building"]
        local cancelsBuildingGhost = abil_info["CancelsBuildingGhost"]
        if isBuilding ~= nil and tostring(isBuilding) == "1" then
          BuildingAbilities[tostring(abil_name)] = abil_info
        end
      end
    end
  end
end

function BuildingHelper:RegisterLeftClick( args )
  local x = args['X']
  local y = args['Y']
  local z = args['Z']
  local location = Vector(x, y, z)

  local player = PlayerResource:GetPlayer(args['PlayerID'])
  local builder = player.activeBuilder

  if not builder:HasAbility("has_build_queue") then
    builder:AddAbility("has_build_queue")
    builder:FindAbilityByName("has_build_queue"):SetLevel(1)
  end

  

  -- Cancel current repair
  if builder:HasModifier("modifier_builder_repairing") then
    local race = GetUnitRace(builder)
    local repair_ability = builder:FindAbilityByName(race.."_gather")
    local event = {}
    event.caster = builder
    event.ability = repair_ability
    BuilderStopRepairing(event)
  end

  BuildingHelper:AddToQueue(builder, location)
end

function BuildingHelper:RegisterRightClick( args )
  local player = PlayerResource:GetPlayer(args['PlayerID'])
  BuildingHelper:ClearQueue(player.activeBuilder)
  player.activeBuilding = nil
  player.activeBuilder.ProcessingBuilding = false
end

function BuildingHelper:AddBuilding(keys)

  -- Callbacks
  callbacks = BuildingHelper:SetCallbacks(keys)

  local ability = keys.ability
  local abilName = ability:GetAbilityName()
  local buildingTable = BuildingHelper:SetupBuildingTable(abilName) 

  buildingTable:SetVal("AbilityHandle", ability)

  local size = buildingTable:GetVal("BuildingSize", "number")
  local unitName = buildingTable:GetVal("UnitName", "string")

  -- Prepare the builder, if it hasn't already been done. Since this would need to be done for every builder in some games, might as well do it here.
  local builder = keys.caster

  if builder.buildingQueue == nil or Timers.timers[builder.workTimer] == nil then    
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

  -- Make a model dummy to pass it to panorama
  player.activeBuildingTable.mgd = CreateUnitByName(unitName, OutOfWorldVector, false, nil, nil, builder:GetTeam())

  --<BMD> position is 0, model attach is 1, color is CP2, alpha is CP3.x, scale is CP4.x
  player.activeBuildingTable.modelParticle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/ghost_model.vpcf", PATTACH_ABSORIGIN, player.activeBuildingTable.mgd, player)
  ParticleManager:SetParticleControlEnt(player.activeBuildingTable.modelParticle, 1, player.activeBuildingTable.mgd, 1, "follow_origin", player.activeBuildingTable.mgd:GetAbsOrigin(), true)            
  ParticleManager:SetParticleControl(player.activeBuildingTable.modelParticle, 3, Vector(MODEL_ALPHA,0,0))
  ParticleManager:SetParticleControl(player.activeBuildingTable.modelParticle, 4, Vector(fMaxScale,0,0))

  ParticleManager:SetParticleControl(player.activeBuildingTable.modelParticle, 2, Vector(0,255,0))

  CustomGameEventManager:Send_ServerToPlayer(player, "building_helper_enable", {["state"] = "active", ["size"] = size, ["scale"] = fMaxScale, ["entindex"] = player.activeBuildingTable.mgd:entindex()})
end

function BuildingHelper:SetCallbacks(keys)
  local callbacks = {}

  function keys:OnPreConstruction( callback )
    callbacks.onPreConstruction = callback -- Return false to abort the build
  end

  function keys:OnConstructionStarted( callback )
    callbacks.onConstructionStarted = callback
  end

  function keys:OnConstructionCompleted( callback )
    callbacks.onConstructionCompleted = callback
  end

  function keys:OnConstructionFailed( callback ) -- Called if there is a mechanical issue with the building (cant be placed)
    callbacks.onConstructionFailed = callback
  end

  function keys:OnConstructionCancelled( callback ) -- Called when player right clicks to cancel a queue
    callbacks.onConstructionCancelled = callback
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

  function keys:OnBuildingPosChosen( callback )
    callbacks.onBuildingPosChosen = callback
  end

  return callbacks
end

-- Setup building table, returns a constructed table.
function BuildingHelper:SetupBuildingTable( abilityName )

  local buildingTable = BuildingAbilities[abilityName]

  function buildingTable:GetVal( key, expectedType )
    local val = buildingTable[key]

    --print('val: ' .. tostring(val))
    if val == nil and expectedType == "bool" then
      return false
    end
    if val == nil and expectedType ~= "bool" then
      return nil
    end

    if tostring(val) == "" then
      return nil
    end

    if expectedType == "handle" then
      return val
    end

    local sVal = tostring(val)
    if sVal == "1" and expectedType == "bool" then
      return true
    elseif sVal == "0" and expectedType == "bool" then
      return false
    elseif sVal == "" then
      return nil
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
    print('[BuildingHelper] Error: ' .. abilName .. ' does not have a BuildingSize KeyValue')
    return
  end
  if size == 1 then
    print('[BuildingHelper] Warning: ' .. abilName .. ' has a size of 1. Using a gridnav size of 1 is currently not supported, it was increased to 2')
    buildingTable:SetVal("size", 2)
    return
  end

  local unitName = buildingTable:GetVal("UnitName", "string")
  if unitName == nil then
    print('[BuildingHelper] Error: ' .. abilName .. ' does not have a UnitName KeyValue')
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

  return buildingTable
end

--Places a new building on full health and returns the handle. Places grid nav blockers
--Skips the construction phase and doesn't require a builder, this is most important to place the "base" buildings for the players when the game starts.
--Make sure the position is valid before calling this in code.
function BuildingHelper:PlaceBuilding(player, name, location, blockGridNav, size)
  
  local pID = player:GetPlayerID()
  local playersHero = player:GetAssignedHero()
  print("Place Building, ",pID, playersHero)
  
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
  building.state = "complete"

  -- Adjust the Hull Radius according to the gridnav size
  building:SetHullRadius( size * 32 - 32 )

  function building:RemoveBuilding( bForcedKill )
    for k, v in pairs(building.blockers) do
      DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
      DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
    end

    if bForcedKill then
      building:ForceKill(bForcedKill)
    end
  end

  -- Return the created building
  return building

end

function BuildingHelper:BlockGridNavSquare(size, location)

  if size % 2 ~= 0 then
    location.x = SnapToGrid32(location.x)
    location.y = SnapToGrid32(location.y)
  else
    location.x = SnapToGrid64(location.x)
    location.y = SnapToGrid64(location.y)
  end

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
      InitializeBuildingEntity
      * Creates the building

]]--
function BuildingHelper:InitializeBuildingEntity( keys )
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

  -- Check gridnav.
  if size % 2 == 1 then
    for x = location.x - (size / 2) * 32 , location.x + (size / 2) * 32 , 32 do
      for y = location.y - (size / 2) * 32 , location.y + (size / 2) * 32 , 32 do
        local testLocation = Vector(x, y, location.z)
        if GridNav:IsBlocked(testLocation) or GridNav:IsTraversable(testLocation) == false then
          ParticleManager:DestroyParticle(work.particles, true)
          if callbacks.onConstructionFailed ~= nil then
            callbacks.onConstructionFailed(work)
          end
          return
        end
      end
    end
  else
    for x = location.x - (size / 2) * 32 - 16, location.x + (size / 2) * 32 + 16, 32 do
      for y = location.y - (size / 2) * 32 - 16, location.y + (size / 2) * 32 + 16, 32 do
        local testLocation = Vector(x, y, location.z)
         if GridNav:IsBlocked(testLocation) or GridNav:IsTraversable(testLocation) == false then
          ParticleManager:DestroyParticle(work.particles, true)
          if callbacks.onConstructionFailed ~= nil then
            callbacks.onConstructionFailed(work)
          end
          return
        end
      end
    end
  end

  if GameRules.WarpTen then
    local building = BuildingHelper:PlaceBuilding(player, unitName, location, true, size)
    ParticleManager:DestroyParticle(work.particles, true)
    callbacks.onConstructionCompleted(building)
    return
  end

  local gridNavBlockers = BuildingHelper:BlockGridNavSquare(size, location)

  -- Spawn the building
  local building = CreateUnitByName(unitName, location, false, playersHero, player, builder:GetTeam())
  building:SetControllableByPlayer(pID, true)
  building.blockers = gridNavBlockers
  building.buildingTable = buildingTable
  building.state = "building"

  -- Adjust the Hull Radius according to the gridnav size
  building:SetHullRadius( size * 32 - 32)

  -- Prevent regen messing with the building spawn hp gain
  local regen = building:GetBaseHealthRegen()
  building:SetBaseHealthRegen(0)

  local buildTime = buildingTable:GetVal("BuildTime", "float")
  if buildTime == nil then
    buildTime = .1
  end

  -- the gametime when the building should be completed.
  local fTimeBuildingCompleted=GameRules:GetGameTime()+buildTime

  ------------------------------------------------------------------
  -- New Build Behaviours
  --  RequiresRepair: If set to 1 it will place the building and not update its health nor send the OnConstructionCompleted callback until its fully healed
  --  BuilderInside: Puts the builder unselectable/invulnerable/nohealthbar inside the building in construction
  --  ConsumesBuilder: Kills the builder after the construction is done
  local bRequiresRepair = buildingTable:GetVal("RequiresRepair", "bool")
  local bBuilderInside = buildingTable:GetVal("BuilderInside", "bool")
  local bConsumesBuilder = buildingTable:GetVal("ConsumesBuilder", "bool")
  -------------------------------------------------------------------

  -- whether we should update the building's health over the build time.
  local bUpdateHealth = buildingTable:GetVal("UpdateHealth", "bool")
  local fMaxHealth = building:GetMaxHealth()

  --[[
        Code to update unit health and scale over the build time, maths is a bit spooky but here's whats happening
        Logic follows:
          Calculate HP to increase every frame
          Divide into INT and FLOAT components (SetHealth takes an int)
          Create a timer, tick every frame
            Increase the HP by the INT component
            Each tick increment the FLOAT carry by the FLOAT component
            IF the FLOAT carry > 1, reduce by one and increase the HP by one extra

        Can be optimized later if updating every frame proves to be a problem
  ]]--
  local fAddedHealth = 0

  local fserverFrameRate = 1/30 

  local nHealthInterval = fMaxHealth / (buildTime / fserverFrameRate)
  local fSmallHealthInterval = nHealthInterval - math.floor(nHealthInterval) -- just the floating point component
  nHealthInterval = math.floor(nHealthInterval)
  local fHPAdjustment = 0

  -- whether we should scale the building.
  local bScale = buildingTable:GetVal("Scale", "bool")
  
  ----------------- CUSTOM Warcraft 3 Initial Health ------------------
  local masonry_rank = GetCurrentResearchRank(player, "human_research_masonry1")
  local fMaxHealth = fMaxHealth * (1 + 0.2 * masonry_rank) 
  local nInitialHealth = 0.10 * ( fMaxHealth )
  local fUpdateHealthInterval = buildTime / math.floor(fMaxHealth-nInitialHealth) -- health to add every tick until build time is completed.
  ---------------------------------------------------------------------

  -- the amount to scale to.
  local fMaxScale = buildingTable:GetVal("MaxScale", "float")
  if fMaxScale == nil then
    fMaxScale = 1
  end

  -- Update model size, starting with an initial size
  local fInitialModelScale = 0.2

  -- scale to add every frame, distributed by build time
  local fScaleInterval = (fMaxScale-fInitialModelScale) / (buildTime / fserverFrameRate)

  -- start the building at 20% of max scale.
  local fCurrentScale = fInitialModelScale
  local bScaling = false -- Keep tracking if we're currently model scaling.

  local bPlayerCanControl = buildingTable:GetVal("PlayerCanControl", "bool")
  if bPlayerCanControl then
    building:SetControllableByPlayer(playersHero:GetPlayerID(), true)
    building:SetOwner(playersHero)
  end
    
  building.bUpdatingHealth = false --Keep tracking if we're currently updating health.

  if bUpdateHealth then
    building:SetHealth(nInitialHealth)
    building.bUpdatingHealth = true
  end

  if bScale then
    building:SetModelScale(fCurrentScale)
    bScaling=true
  end

  -- Put the builder invulnerable inside the building in construction
  if bBuilderInside then
    local item = CreateItem("item_apply_modifiers", nil, nil)
    item:ApplyDataDrivenModifier(builder, builder, "modifier_builder_hidden", {})
    item = nil
    builder.entrance_to_build = builder:GetAbsOrigin()
    local location_builder = Vector(location.x, location.y, location.z - 200)
    AddUnitToSelection(building)
    building.builder_inside = builder
    builder:AddNoDraw()
    Timers:CreateTimer(function() 
      builder:SetAbsOrigin(location_builder)
    end)
  end

  if fUpdateHealthInterval <= fserverFrameRate then
    -- If the tick would be faster than 1 frame, adjust the HP gained per frame
      print("Building needs float adjust")
  else
    if not bRequiresRepair then

      -- Worker is done with this building
      builder.ProcessingBuilding = false

      building.updateHealthTimer = DoUniqueString('health') 
      Timers:CreateTimer(building.updateHealthTimer, {
        callback = function()
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
            if callbacks.onConstructionCompleted ~= nil then
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
            end

            -- clean up the timer if we don't need it.
            return nil
          end
        else
          -- Building destroyed

          -- Eject Builder
          if bBuilderInside then
            builder:RemoveModifierByName("modifier_builder_hidden")
            builder:RemoveNoDraw()
          end

          -- Worker is done with this building
          builder.ProcessingBuilding = false

          return nil
        end
        return fUpdateHealthInterval
      end})
    else

      -- The building will have to be assisted through a repair ability
      local repair_ability_name = "human_gather"
      local repair_ability = builder:FindAbilityByName(repair_ability_name)
      if not repair_ability then
        print("[BH] Error, can't find "..repair_ability_name.." on the builder ",builder, builder:GetUnitName())
        return
      end

      --[[ExecuteOrderFromTable({ UnitIndex = builder:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_TARGET, 
                            TargetIndex = building:GetEntityIndex(), AbilityIndex = repair_ability:GetEntityIndex(), Queue = false }) ]]
      builder:CastAbilityOnTarget(building, repair_ability, pID)

      building.updateHealthTimer = DoUniqueString('assisted_construction') 
      Timers:CreateTimer(building.updateHealthTimer, {
        callback = function()
        if IsValidEntity(building) then
          if building.constructionCompleted then --This is set on the repair ability when the builders have restored the necessary health
            if callbacks.onConstructionCompleted ~= nil and building:IsAlive() then
              callbacks.onConstructionCompleted(building)

              -- Worker is done with this building (finished repairing)
              builder.ProcessingBuilding = false
            end
            building.state = "complete"
            return nil
          else
            return 0.1
          end
        end
      end})
    end
  end


  -- scale timer
  if bScale then
    building.updateScaleTimer = DoUniqueString('scale')
    Timers:CreateTimer(building.updateScaleTimer, {
      callback = function()
        if IsValidEntity(building) then
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
          -- clean up the timer if we don't need it.
          print("[BH] Scale was off by:", fMaxScale - fCurrentScale)
          building:SetModelScale(fMaxScale)
          return nil
        end
      else
        -- not valid ent
        return nil
      end
        return fserverFrameRate
    end})
  end

  -- OnBelowHalfHealth timer
  building.onBelowHalfHealthProc = false
  building.healthChecker = Timers:CreateTimer(.2, function()
    if IsValidEntity(building) then
      if building:GetHealth() < fMaxHealth/2.0 and not building.onBelowHalfHealthProc and not building.bUpdatingHealth then
        if callbacks.fireEffect ~= nil then
          building:AddNewModifier(building, nil, callbacks.fireEffect, nil)
        end
        callbacks.onBelowHalfHealth(unit)
        building.onBelowHalfHealthProc = true
      elseif building:GetHealth() >= fMaxHealth/2.0 and building.onBelowHalfHealthProc and not building.bUpdatingHealth then
        if callbacks.fireEffect then
          building:RemoveModifierByName(callbacks.fireEffect)
        end
        callbacks.onAboveHalfHealth(unit)
        building.onBelowHalfHealthProc = false
      end
    else
      return nil
    end

    return .2
  end)

  function building:RemoveBuilding( bForcedKill )
    -- Thanks based T__
    for k, v in pairs(building.blockers) do
      DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
      DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
    end

    if bForcedKill then
      building:ForceKill(bForcedKill)
    end
  end

  if callbacks.onConstructionStarted ~= nil then
    callbacks.onConstructionStarted(building)
  end

  -- Remove the model particl
  ParticleManager:DestroyParticle(work.particles, true)

end

--[[
      CancelBuilding
      * Cancels the building
      * Refunds the cost by a factor
]]
function BuildingHelper:CancelBuilding(keys)
    print("CancelBuilding")
    local building = keys.unit
    local hero = building:GetOwner()

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

          -- Worker is done with this building
          builder.ProcessingBuilding = false

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
                building:CastAbilityImmediately(item, building:GetPlayerOwnerID())
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
    building:RemoveBuilding(true)

end

--[[
      Builder Functions
      * Sets up all the functions required of a builder. Will run once per builder
      * Manages each workers build queue
]]--

function BuildingHelper:InitializeBuilder(builder)

  builder.ProcessingBuilding = false

  if builder.buildingQueue == nil then
    builder.buildingQueue = {}
  end

  -- Repeating timer to move to the next queued building
  builder.workTimer = Timers:CreateTimer(0.1, function ()
    if #builder.buildingQueue > 0 and builder.ProcessingBuilding == false then    
      builder.ProcessingBuilding = true
      BuildingHelper:AddToGrid(builder, builder.buildingQueue[1])
      table.remove(builder.buildingQueue, 1)
    end
    return 0.1
  end)

end

-- Adds a location to the builders work queue
function BuildingHelper:AddToQueue( builder, location )

  local player = PlayerResource:GetPlayer(builder:GetMainControllingPlayer())
  local building = player.activeBuilding
  local buildingTable = player.activeBuildingTable
  local fMaxScale = buildingTable:GetVal("MaxScale", "float")
  local size = buildingTable:GetVal("BuildingSize", "number")
  local callbacks = player.activeCallbacks

  if size % 2 ~= 0 then
    location.x = SnapToGrid32(location.x)
    location.y = SnapToGrid32(location.y)
  else
    location.x = SnapToGrid64(location.x)
    location.y = SnapToGrid64(location.y)
  end

  if size % 2 == 1 then
    for x = location.x - (size / 2) * 32 , location.x + (size / 2) * 32 , 32 do
      for y = location.y - (size / 2) * 32 , location.y + (size / 2) * 32 , 32 do
        local testLocation = Vector(x, y, location.z)
        if GridNav:IsBlocked(testLocation) or GridNav:IsTraversable(testLocation) == false then
          if callbacks.onConstructionFailed ~= nil then
            callbacks.onConstructionFailed(work)
          end
          return
        end
      end
    end
  else
    for x = location.x - (size / 2) * 32 - 16, location.x + (size / 2) * 32 + 16, 32 do
      for y = location.y - (size / 2) * 32 - 16, location.y + (size / 2) * 32 + 16, 32 do
        local testLocation = Vector(x, y, location.z)
         if GridNav:IsBlocked(testLocation) or GridNav:IsTraversable(testLocation) == false then
          if callbacks.onConstructionFailed ~= nil then
            callbacks.onConstructionFailed(work)
          end
          return
        end
      end
    end
  end

  if callbacks.onPreConstruction ~= nil then
    local result = callbacks.onPreConstruction(location)
    if result ~= nil then
      if result == false then
        return
      end
    end
  end

  -- Create model ghost dummy out of the map, then make pretty particles
  local mgd = CreateUnitByName(building, OutOfWorldVector, false, nil, nil, builder:GetTeam())

  --<BMD> position is 0, model attach is 1, color is CP2, alpha is CP3.x, scale is CP4.x
  local modelParticle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/ghost_model.vpcf", PATTACH_ABSORIGIN, mgd, player)
  ParticleManager:SetParticleControlEnt(modelParticle, 1, mgd, 1, "follow_origin", mgd:GetAbsOrigin(), true)            
  ParticleManager:SetParticleControl(modelParticle, 3, Vector(MODEL_ALPHA,0,0))
  ParticleManager:SetParticleControl(modelParticle, 4, Vector(fMaxScale,0,0))

  ParticleManager:SetParticleControl(modelParticle, 0, location)
  ParticleManager:SetParticleControl(modelParticle, 2, Vector(0,255,0))

  table.insert(builder.buildingQueue, {["location"] = location, ["name"] = building, ["buildingTable"] = buildingTable, ["particles"] = modelParticle, ["callbacks"] = callbacks})

end

-- Processes an item of the builders work queue
function BuildingHelper:AddToGrid( builder, work )
    local buildingTable = work.buildingTable
    local castRange = buildingTable:GetVal("AbilityCastRange", "number")
    local callbacks = work.callbacks
    local location = work.location
    builder.work = work

    -- Make the caster move towards the point
    local abilName = "move_to_point_" .. tostring(castRange)
    if AbilityKVs[abilName] == nil then
      print('[BuildingHelper] Error: ' .. abilName .. ' was not found in npc_abilities_custom.txt. Using the ability move_to_point_100')
      abilName = "move_to_point_100"
    end

    -- If unit has other move_to_point abils, we should clean them up here
    AbilityIterator(builder, function(abil)
      local name = abil:GetAbilityName()
      if name ~= abilName and string.starts(name, "move_to_point_") then
        builder:RemoveAbility(name)
        --print("removed " .. name)
      end
    end)

    if not builder:HasAbility(abilName) then
      builder:AddAbility(abilName)
    end
    local abil = builder:FindAbilityByName(abilName)
    abil:SetLevel(1)

    Timers:CreateTimer(.03, function()
      builder:CastAbilityOnPosition(location, abil, 0)
        
      -- Change builder state
      builder.state = "moving_to_build"

      if callbacks.onBuildingPosChosen ~= nil then
        callbacks.onBuildingPosChosen(location)
        callbacks.onBuildingPosChosen = nil
      end
    end)
end

-- Clear the build queue, the player right clicked
function BuildingHelper:ClearQueue(builder)
  if builder.work ~= nil then
    ParticleManager:DestroyParticle(builder.work.particles, true)
    if builder.work.callbacks.onConstructionCancelled ~= nil then
      builder.work.callbacks.onConstructionCancelled(work)
    end
  end

  while #builder.buildingQueue > 0 do
    local work = builder.buildingQueue[1]
    print(work.particles)
    ParticleManager:DestroyParticle(work.particles, true)
    table.remove(builder.buildingQueue, 1)
    if work.callbacks.onConstructionCancelled ~= nil then
      work.callbacks.onConstructionCancelled(work)
    end
  end
end

BuildingHelper:Init()

--[[
      Utility functions
]]--
function SnapToGrid64(coord)
  return 64*math.floor(0.5+coord/64)
end

function SnapToGrid32(coord)
  return 32+64*math.floor(coord/64)
end

function AbilityIterator(unit, callback)
    for i=0, unit:GetAbilityCount()-1 do
        local abil = unit:GetAbilityByIndex(i)
        if abil ~= nil then
            callback(abil)
        end
    end
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end