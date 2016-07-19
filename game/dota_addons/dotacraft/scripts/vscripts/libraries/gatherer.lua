require("libraries/timers")
require("libraries/keyvalues")

if not Gatherer then
    Gatherer = class({})
end

--[[ TODO:
Fix whatever happens that makes them get stuck and never able to gather again. Gather sometimes not continuing, stuck modifier/can't return 0.
Repro
    1. Target a tree
    2. Target the same with another builder
    3. Wait for tree cut
    If the tree was cut on the way back, on resume gather, the other builders wont acquire a new one

Fix attempting bad tree getting "stuck" with a timer while moving to gather
Shouldnt hardcode gold_mine on-top building names in the filter
Make a Built-In ExtractionBuilding system
Wait for building on top construction then go inside right after
Make it possible to work without a GatherAbility
Even though builders have no collision while gathering, find an empty point near the tree to path to
Wisps got order stuck going to gold mine
Skip the extra attack animation while the builder is going back to return
]]

function Gatherer:start()
    if IsInToolsMode() then
        local src = debug.getinfo(1).source
        self.gameDir = ""
        self.addonName = ""
        if src:sub(2):find("(.*dota 2 beta[\\/]game[\\/]dota_addons[\\/])([^\\/]+)[\\/]") then
            self.gameDir, self.addonName = string.match(src:sub(2), "(.*dota 2 beta[\\/]game[\\/]dota_addons[\\/])([^\\/]+)[\\/]")
        else
            SendToServerConsole("script_reload_code " .. src:sub(2))
            return
        end
    end

    -- Lua modifiers
    LinkLuaModifier("modifier_attack_trees", "libraries/modifiers/modifier_attack_trees", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_no_collision", "libraries/modifiers/modifier_no_collision", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_carrying_lumber", "libraries/modifiers/gatherer_modifiers", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_carrying_gold", "libraries/modifiers/gatherer_modifiers", LUA_MODIFIER_MOTION_NONE)
    LinkLuaModifier("modifier_gatherer_hidden", "libraries/modifiers/gatherer_modifiers", LUA_MODIFIER_MOTION_NONE)

    -- Game Event Listeners
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(Gatherer, 'OnGameRulesStateChange'), self)
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(Gatherer, 'OnNPCSpawned'), self)
    ListenToGameEvent('tree_cut', Dynamic_Wrap(Gatherer, 'OnTreeCut'), self)

    -- Panorama Event Listeners
    CustomGameEventManager:RegisterListener("right_click_order", Dynamic_Wrap(Gatherer, "OnRightClick"))
    CustomGameEventManager:RegisterListener("gold_gather_order", Dynamic_Wrap(Gatherer, "OnGoldMineClick"))

    self.bShouldLoadTreeMap = not IsInToolsMode() -- Always re-determine pathable trees in tools, to account for map changes.
    self.GathererUnits = {}

    self:LoadSettings()
    self:HookBoilerplate()
end

function Gatherer:HookBoilerplate()
    if not __ACTIVATE_HOOK then
        __ACTIVATE_HOOK = {funcs={}}
        setmetatable(__ACTIVATE_HOOK, {
          __call = function(t, func)
            table.insert(t.funcs, func)
          end
        })

        debug.sethook(function(...)
          local info = debug.getinfo(2)
          local src = tostring(info.short_src)
          local name = tostring(info.name)
          if name ~= "__index" then
            if string.find(src, "addon_game_mode") then
              if GameRules:GetGameModeEntity() then
                for _, func in ipairs(__ACTIVATE_HOOK.funcs) do
                  local status, err = pcall(func)
                  if not status then
                    print("__ACTIVATE_HOOK callback error: " .. err)
                  end
                end

                debug.sethook(nil, "c")
              end
            end
          end
        end, "c")
    end

    -- Hook the order filter
    __ACTIVATE_HOOK(function()
        local mode = GameRules:GetGameModeEntity()
        mode:SetExecuteOrderFilter(Dynamic_Wrap(Gatherer, 'OrderFilter'), Gatherer)
        self.oldFilter = mode.SetExecuteOrderFilter
        mode.SetExecuteOrderFilter = function(mode, fun, context)
            Gatherer.nextFilter = fun
            Gatherer.nextContext = context
        end
    end)
end

function Gatherer:LoadSettings()
    self.Settings = LoadKeyValues("scripts/kv/gatherer_settings.kv") or {}
    self.Deposits = self.Settings["deposits"]
    self.TreeRadius = self.Settings["TreeRadius"] or 50
    self.TreeHealth = self.Settings["TreeHealth"] or 50
    self.MinDistanceToTree = self.Settings["MinDistanceToTree"] or 150
    self.MinDistanceToMine = self.Settings["MinDistanceToMine"] or 300
    self.ThinkInterval = 0.5
    self.DebugPrint = true
    self.DebugDraw = false
    self.DebugDrawDuration = 10
end

function Gatherer:OnScriptReload()
    self:LoadSettings()
    for index,ent in pairs(self.GathererUnits) do
        if IsValidEntity(ent) and ent:IsAlive() then
            Gatherer:Init(ent)
        end
    end
    for _,t in pairs(self.AllTrees) do
        t.health = self.TreeHealth
        t.builder = nil
    end
    LoadGameKeyValues()
end

function Gatherer:OnGameRulesStateChange(event)
    local newState = GameRules:State_Get()
    if newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        self:InitTrees()
    elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
        self:InitGoldMines()
    end
end

function Gatherer:OnNPCSpawned(event)
    local npc = EntIndexToHScript(event.entindex)
    if npc:IsGatherer() then
        Gatherer:Init(npc)
    end
end

function Gatherer:OnTreeCut(event)
    local treeX = event.tree_x
    local treeY = event.tree_y
    local treePos = Vector(treeX,treeY,0)

    -- Update the pathable trees nearby
    local vecs = {
        Vector(0,64,0),-- N
        Vector(64,64,0), -- NE
        Vector(64,0,0), -- E
        Vector(64,-64,0), -- SE
        Vector(0,-64,0), -- S
        Vector(-64,-64,0), -- SW
        Vector(-64,0,0), -- W
        Vector(-64,64,0) -- NW
    }

    for k=1,#vecs do
        local vec = vecs[k]
        local xoff = vec.x
        local yoff = vec.y
        local pos = Vector(treeX + xoff, treeY + yoff, 0)

        local nearbyTree = GridNav:IsNearbyTree(pos, 64, true)
        if nearbyTree then
            local trees = GridNav:GetAllTreesAroundPoint(pos, 32, true)
            for _,t in pairs(trees) do
                self:DrawCircle(t:GetAbsOrigin(), Vector(0,255,0), 32)
                t.pathable = true
            end
        end
    end
end
------------------------------------------------
--            Filter for Tree Clicks          --
------------------------------------------------
function Gatherer:OnRightClick(event)
    local playerID = event.PlayerID
    local point = event.position
    if not point then return end
    local position = GetGroundPosition(Vector(point["0"], point["1"], 0), nil)

    if Gatherer:ClickedOnTrees(position) then
        Gatherer:OnTreeClick(PlayerResource:GetSelectedEntities(playerID), position)
    end
end

------------------------------------------------
--           Tree Gather Right-Click          --
------------------------------------------------
function Gatherer:OnTreeClick(units, position)
    local entityIndex = units["0"]
    local unit = EntIndexToHScript(entityIndex)
    if not unit:CanAttackTrees() then return end -- first unit must be able to attack trees

    self:print("OnTreeClick around "..VectorString(position))

    if unit:CanGatherLumber() then
        unit:GatherFromNearestTree(position, self.MinDistanceToTree, true)

    else -- Not a gatherer but can attack trees via raw attacks
        local trees = GridNav:GetAllTreesAroundPoint(position, self.TreeRadius, true)
        for _,tree in pairs(trees) do
            if tree:IsPathable() then
                Gatherer:AttackTree(unit, tree)
                break
            end
        end
    end
end

function Gatherer:AttackTree(unit, tree)
    local tree_pos = tree:GetAbsOrigin()
    self:print("Now attacking tree "..tree:GetTreeID())
    self:CreateSelectionParticle(unit, tree)
    ExecuteOrderFromTable({UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = location, Queue = false}) 

    -- Move towards the tree until close range    
    unit.gatherer_timer = Timers:CreateTimer(0.03, function() 
        if not IsValidEntity(unit) or not unit:IsAlive() then return end -- End if killed

        local distance = (tree_pos - unit:GetAbsOrigin()):Length()
        unit:MoveToPosition(tree_pos)
        
        if distance > self.MinDistanceToTree then
            return self.ThinkInterval
        else
            unit:StartGesture(ACT_DOTA_ATTACK)
            unit.gatherer_timer = Timers:CreateTimer(0.5, function() 
                tree:CutDown(unit:GetTeamNumber())
            end)
            return
        end
    end)
end

------------------------------------------------
--          Gold Gather Right-Click           --
------------------------------------------------
function Gatherer:OnGoldMineClick(event)
    local playerID = event.PlayerID
    local player = PlayerResource:GetPlayer(playerID)
    local entityIndex = event.mainSelected
    local targetIndex = event.targetIndex
    local gold_mine = EntIndexToHScript(targetIndex)
    local queue = event.queue == 1
    local unit = EntIndexToHScript(entityIndex)

    Gatherer:print("OnGoldMineClick!")

    unit:GatherFromNearestGoldMine(gold_mine)
end

------------------------------------------------
--            Gatherer Order Filter           --
------------------------------------------------
function Gatherer:OrderFilter(order)
    local ret = true    

    if Gatherer.nextFilter then
        ret = Gatherer.nextFilter(Gatherer.nextContext, order)
    end
    if not ret then return false end

    local issuerID = order.issuer_player_id_const
    local units = order.units
    local order_type = order.order_type
    local issuer = order.issuer_player_id_const
    local abilityIndex = order.entindex_ability
    local targetIndex = order.entindex_target
    local x = tonumber(order.position_x)
    local y = tonumber(order.position_y)
    local z = tonumber(order.position_z)
    local point = Vector(x,y,z)
    local queue = order["queue"] == 1
    local entityIndex = units["0"]
    local unit = EntIndexToHScript(entityIndex)

    -- Skip Prevents order loops
    if unit then
        if unit.gatherer_skip then
            unit.gatherer_skip = false
            return true
        end
    else
        return true
    end

    -- Get the currently selected units to send new orders on all units
    local entityList = PlayerResource:GetSelectedEntities(unit:GetPlayerOwnerID())
    if not entityList then return true end

    ------------------------------------------------
    --              No Target Return              --
    ------------------------------------------------
    if order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET and abilityIndex and abilityIndex ~= 0 then
        
        local ability = EntIndexToHScript(abilityIndex)
        if not ability then
            self:print("Error: CAST_NO_TARGET with an incorrect index")
            return true
        end

        -- If the return ability was cast, spread to other gatherers on the selected group
        if ability == unit:GetReturnAbility() then
            for k,entIndex in pairs(entityList) do
                local ent = EntIndexToHScript(entIndex)
                local return_ability = ent:GetReturnAbility()

                if return_ability and not return_ability:IsHidden() then
                    ent:ReturnResources(queue)
                end
            end
        end
        return true

    ------------------------------------------------
    --          Tree Gather Multi Orders          --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET_TREE then
        local abilityIndex = abilityIndex
        local ability = EntIndexToHScript(abilityIndex) 

        -- Only continue in case the ability cast is the gather ability
        if ability ~= unit:GetGatherAbility() then return true end

        local treeID = targetIndex
        local tree_index = GetEntityIndexForTreeId(treeID)
        local tree_handle = EntIndexToHScript(tree_index)
        local position = tree_handle:GetAbsOrigin()

        Gatherer:DrawCircle(position, Vector(255,0,0), 32)
        Gatherer:DrawLine(unit:GetAbsOrigin(), position)

        local gatherer_units = filter(function(index) return EntIndexToHScript(index):CanGatherLumber() end, entityList)
        local numGatherers = TableCount(gatherer_units)
        if numGatherers <= 1 then return true end

        for k,entityIndex in pairs(entityList) do
            self:print("GatherTreeOrder for unit index "..entityIndex.." "..VectorString(position))

            --Execute the order to a navigable tree
            local ent = EntIndexToHScript(entityIndex)
            local empty_tree = FindEmptyNavigableTreeNearby(ent, position, 150 + 20 * numGatherers) --TODO: ability:GetKeyValue("RequiresEmptyTree")
            if empty_tree then 
                empty_tree.builder = ent
                ent.gatherer_skip = true
                local gather_ability = ent:GetGatherAbility()
                local return_ability = ent:GetReturnAbility()
                if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                    local tree_index = empty_tree:GetTreeID()
                    self:print("Cast Target Tree: "..tree_index.." at forest "..empty_tree:GetForestID())
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                    Gatherer:DrawCircle(empty_tree:GetAbsOrigin(), Vector(255,255,255), 16)
                    Gatherer:DrawLine(ent:GetAbsOrigin(), empty_tree:GetAbsOrigin())
                elseif return_ability and not return_ability:IsHidden() then
                    ent:ReturnResources(queue, false) -- Let it propagate to all selected units
                end
            else
                print("No Empty Tree?")
            end
        end

        -- Drop the original order
        return false

    ------------------------------------------------
    --        Gold Mine Gather Multi Orders       --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET and targetIndex ~= 0 then
        local target_handle = EntIndexToHScript(targetIndex)
        local target_name = target_handle:GetUnitName()

        -- TODO: Correct building on top mine names
        if target_name == "gold_mine" or
          ((target_name == "nightelf_entangled_gold_mine" or target_name == "undead_haunted_gold_mine") and target_handle:GetTeamNumber() == unit:GetTeamNumber()) then

            self:print("Gold Mine Gather Multi Orders")

            local gold_mine = target_handle
            for k,entityIndex in pairs(entityList) do
                local unit = EntIndexToHScript(entityIndex)
                local race = GetUnitRace(unit)
                local gather_ability = unit:GetGatherAbility()
                local return_ability = unit:GetReturnAbility()

                -- Gold gather
                if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                    unit.gatherer_skip = true
                    unit.skip = true
                    self:print("MultiOrder: Cast on "..gold_mine:GetUnitName())
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
                    -- Can the unit still gather more resources?
                    if (unit.lumber_gathered and unit.lumber_gathered < unit:GetLumberCapacity()) then

                        -- Swap to a gather ability and keep extracting
                        unit.gatherer_skip = true
                        unit:SwapAbilities(gather_ability:GetAbilityName(), return_ability:GetAbilityName(), true, false)
                        self:print("Order: Cast on "..gold_mine:GetUnitName())
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                    else
                        -- Return
                        unit.target_mine = gold_mine
                        unit:ReturnResources(queue, false) -- Let it propagate to all selected units
                    end
                end
            end
        end
    end

    Gatherer:CheckGatherCancel(order)

    return ret
end

------------------------------------------------
--            Core Pathing/Mapping            --
------------------------------------------------

 -- Start tree tracking and obtain tree map
function Gatherer:InitTrees()
    if not self.AllTrees then
        self.AllTrees = Entities:FindAllByClassname("ent_dota_tree")
        self.TreeCount = #self.AllTrees
    end
    
    for _,t in pairs(self.AllTrees) do
        t.health = self.TreeHealth
    end

    -- Load an existing tree map?
    if true then--self.bShouldLoadTreeMap then
        local treeMapFile
        local status,ret = pcall(function()
            treeMapFile = require("tree_maps/"..GetMapName())
            if treeMapFile then
                self:LoadTreeMap(treeMapFile)
                return -- Skip heavy tree algorithms
            else
                self:print("No Tree Map file found for "..GetMapName())
            end
        end)
    end
    
    self:DeterminePathableTrees() -- Obtain tree map
    self:DetermineForests()       -- Obtain tree forests
    if IsInToolsMode() then
        self:GenerateTreeMap()    -- Write to file
    end
end

function Gatherer:DeterminePathableTrees()
    -- DFS Flood Fill
    self:print("Determining Pathable Trees...")
    local seen = {}
    local Q = {} -- empty queue

    -- Add node to the end of Q.
    table.insert(Q, Vector(0,0,0))

    local vecs = {
        Vector(0,64,0),-- N
        Vector(64,64,0), -- NE
        Vector(64,0,0), -- E
        Vector(64,-64,0), -- SE
        Vector(0,-64,0), -- S
        Vector(-64,-64,0), -- SW
        Vector(-64,0,0), -- W
        Vector(-64,64,0) -- NW
    }
    while #Q > 0 do
        -- Set n equal to the first element of Q and Remove first element from Q.
        local position = table.remove(Q)

        -- If the node is valid, add to the queue
        local blocked = GridNav:IsBlocked(position) or not GridNav:IsTraversable(position)
        if not blocked then

            -- Mark position processed.
            seen[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosX(position.y)] = 1
            for k=1,#vecs do
                local vec = vecs[k]
                local pos = Vector(position.x + vec.x, position.y + vec.y, position.z)

                -- Add unprocessed nodes
                if not seen[GridNav:WorldToGridPosX(pos.x)..","..GridNav:WorldToGridPosX(pos.y)] then
                    table.insert(Q, pos)
                end
            end
        else
            -- When a node is blocked, it can have a tree or just be blocked terrain
            local nearbyTree = GridNav:IsNearbyTree(position, 64, true)
            if nearbyTree then
                local trees = GridNav:GetAllTreesAroundPoint(position, 1, true)
                if #trees > 0 then
                    local t = trees[1]
                    t.pathable = true
                end
            end
        end
    end

    self:print("Pathable Trees set!")
    self:DebugTrees()
end

function Gatherer:DetermineForests()
    self.treeForests = {}

    local num = 0
    for _,tree in pairs(self.AllTrees) do
        if not tree.forestID then
            num = num + 1
        end
        Gatherer:MapTreeForest(tree, num)
    end

    -- Set
    for _,tree in pairs(self.AllTrees) do
        local id = tree.forestID
        self.treeForests[id] = self.treeForests[id] or {}
        table.insert(self.treeForests[id], tree)
    end

    for k,v in pairs(self.treeForests) do
        --self:print("Forest "..k.." has "..#v.." trees")
    end
end

-- Draw random color for each forest
function Gatherer:DebugForests()
    local colors = {}
    for i=1,#self.treeForests do
        colors[i] = Vector(RandomInt(0,255),RandomInt(0,255),RandomInt(0,255))
    end

    for _,tree in pairs(self.AllTrees) do
        local id = tree.forestID
        self:DrawCircle(tree:GetAbsOrigin(), colors[id], 64)
        self:DrawText(tree:GetAbsOrigin(), tostring(id))
    end
end

-- Recurse on the trees nearby
function Gatherer:MapTreeForest(tree, ID)
    if not tree.forestID then
        tree.forestID = ID
    end

    local treesNearby = GridNav:GetAllTreesAroundPoint(tree:GetAbsOrigin(), 200, true)
    for k,v in pairs(treesNearby) do
        if not v.forestID then
            Gatherer:MapTreeForest(v, ID)
        end
    end
end

-- Puts the saved tree map info on each tree handle
function Gatherer:LoadTreeMap(treeMapTable)
    local pathable_count = 0
    for treeID,values in pairs(treeMapTable) do
        local tree = GetTreeHandleFromId(treeID)
        if tree then
            local bPathable = values.pathable == 1
            if bPathable then pathable_count = pathable_count + 1 end
            tree.pathable = bPathable
            tree.forestID = values.forestID
        end
    end

    -- Populate the tree Forests lists
    for _,tree in pairs(self.AllTrees) do
        local id = tree.forestID
        self.treeForests[id] = self.treeForests[id] or {}
        table.insert(self.treeForests[id], tree)
    end

    self:print("Loaded Tree Map for "..GetMapName())
    self:print("Pathable count: "..pathable_count.." out of "..self.TreeCount)
    self:print(#self.treeForests.." Forests loaded.")
end

function Gatherer:GenerateTreeMap()
    local path = "../../dota_addons/"..self.addonName.."/scripts/vscripts/tree_maps/"..GetMapName()..".lua"
    self.treeMap = io.open(path, 'w')
    if not self.treeMap then
        self:print("Error: Can't open path "..path)
        return
    end

    self:print("Generating Tree Map for "..GetMapName().."...")
    self.treeMap:write("local trees = {")
    for forestID,treesInForest in pairs(self.treeForests) do
        for _,tree in pairs(treesInForest) do
            local pathable = tree:IsPathable() and 1 or 0
            local forestID = tree:GetForestID()
            self.treeMap:write("\n"..string.rep(" ",4)..string.format("%4s",tree:GetTreeID()).." = {pathable = "..pathable..", forestID = "..forestID.."},")
        end        
    end
    self.treeMap:write("\n}\n")
    self.treeMap:write("return trees")
    self.treeMap:close()
    self:print("Tree Map generated at "..path)
end

function Gatherer:InitGoldMines()
    Gatherer.GoldMines = Entities:FindAllByModel('models/mine/mine.vmdl')
    
    for k,gold_mine in pairs(Gatherer.GoldMines) do
        local location = gold_mine:GetAbsOrigin()
        local construction_size = BuildingHelper:GetConstructionSize(gold_mine)
        local pathing_size = BuildingHelper:GetBlockPathingSize(gold_mine)
        BuildingHelper:SnapToGrid(construction_size, location)

        -- Add gridnav blockers to the gold mines
        local gridNavBlockers = BuildingHelper:BlockGridSquares(construction_size, pathing_size, location)
        BuildingHelper:AddGridType(construction_size, location, "GoldMine")
        gold_mine:SetAbsOrigin(location)
        gold_mine.blockers = gridNavBlockers

        -- Find and store the mine entrance
        local mine_entrance = Entities:FindAllByNameWithin("*mine_entrance", location, 300)
        for k,v in pairs(mine_entrance) do
            gold_mine.entrance = v:GetAbsOrigin()
        end

        function gold_mine:SetCapacity(value)
            gold_mine.max_capacity = value
        end

        function gold_mine:GetMaxCapacity(value)
            return gold_mine.max_capacity
        end

        function gold_mine:HasRoomForGatherer()
            return TableCount(gold_mine.gatherers) < gold_mine:GetMaxCapacity()
        end

        function gold_mine:AddGatherer(unit)
            gold_mine.gatherers[#gold_mine.gatherers+1] = unit
            print("Added Gatherer, currently ", TableCount(gold_mine.gatherers))
        end

        function gold_mine:RemoveGatherer(unit)
            for k,v in pairs(gold_mine.gatherers) do
                if v == unit then
                    gold_mine.gatherers[k] = nil
                    print("Removed Gatherer currently ", TableCount(gold_mine.gatherers))
                    break
                end
            end
        end

        -- Keep a list of gatherers currently working inside the gold mine
        gold_mine.gatherers = {}
        gold_mine:SetCapacity(1)

        -- Find and store the mine light
    end
end

------------------------------------------------
--           Gatherer Unit Methods            --
------------------------------------------------

function Gatherer:Init(unit)
    self:print("Init "..unit:GetUnitName().." "..unit:GetEntityIndex())

    -- Give modifier to attack trees
    if unit:CanGatherLumber() then
        unit:SetCanAttackTrees(true)
    end

    -- Store unit
    if not self.GathererUnits[unit:GetEntityIndex()] then
        self.GathererUnits[unit:GetEntityIndex()] = unit
    end

    -- Permanent access to gather and return abilities (if any)
    unit.GatherAbility = unit:FindAbilityByKeyValue("GatherAbility")
    unit.ReturnAbility = unit:FindAbilityByKeyValue("ReturnAbility")

    -- Keep track of how much resources is the unit carrying
    unit.lumber_gathered = 0
    unit.gold_gathered = 0

    -- Find a tree near a position and cast the gather ability on it
    function unit:GatherFromNearestTree(position, distance, bManualOrder)
        position = position or unit:GetAbsOrigin() -- If no position, use the unit origin
        distance = distance or Gatherer.MinDistanceToTree -- If no distance, use the minimum

        local gather_ability = unit:GetGatherAbility()
        local return_ability = unit:GetReturnAbility()

        local empty_tree = FindEmptyNavigableTreeNearby(unit, position, distance) --TODO: Not Empty
        if empty_tree then Gatherer:print("GatherFromNearestTree "..empty_tree:GetTreeID())
        else Gatherer:print("Error, cant find valid nearest tree") end

        -- Can the unit still gather more resources?
        if unit.lumber_gathered == 0 or unit:CanCarryMoreLumber() then 
            if gather_ability:IsHidden() and return_ability then -- Swap to a gather ability and keep extracting
                unit:SwapAbilities(gather_ability:GetAbilityName(), return_ability:GetAbilityName(), true, false)
            end

            if empty_tree then
                local tree_index = empty_tree:GetTreeID()
                unit.target_tree = empty_tree --The new selected tree
                Gatherer:print("Now targeting Tree "..tree_index)
                if bManualOrder then
                    Gatherer:CreateSelectionParticle(unit, empty_tree)
                end
                ExecuteOrderFromTable({UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
            end

        else -- Return
            unit.target_tree = empty_tree --The new selected tree
            unit:ReturnResources(false, false) -- Propagate return order
        end
    end

    -- Find a gold mine and cast the gather ability on it
    function unit:GatherFromNearestGoldMine(target)
        local gather_ability = unit:GetGatherAbility()
        local return_ability = unit:GetReturnAbility()
        local gold_mine = target or Gatherer:GetClosestGoldMineToPosition(unit:GetAbsOrigin())

        -- Gold gather
        if gold_mine and unit:CanCarryMoreGold() then
            if gather_ability:IsHidden() and return_ability then -- Swap to a gather ability and keep extracting
                unit:SwapAbilities(gather_ability:GetAbilityName(), return_ability:GetAbilityName(), true, false)
            end

            local mine_index = gold_mine:GetEntityIndex()
            Gatherer:print("Gathering From Nearest Gold Mine: "..mine_index)
            Gatherer:CreateSelectionParticle(unit, gold_mine, 220)
            ExecuteOrderFromTable({UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = mine_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
        
        else -- Return
            unit.target_mine = gold_mine
            unit:ReturnResources(queue, false) -- Propagate return order
        end
    end

    -- use the return ability, swap as required
    function unit:ReturnResources(bQueue, bSkip)
        unit.gatherer_skip = bSkip ~= nil and bSkip or true -- Skip order filter?
        local return_ability = unit.ReturnAbility
        Gatherer:print("ReturnResources Order")
        if return_ability:IsHidden() then unit:SwapAbilities(return_ability:GetAbilityName(),unit.GatherAbility:GetAbilityName(),true,false) end
        ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
                            AbilityIndex = unit.ReturnAbility:GetEntityIndex(), Queue = queue })
    end

    function unit:FindGatherTree()
        -- similar to to FindEmptyNavigableTreeNearby
    end

    function unit:FindClearSpaceAroundTree(tree)
        local points = {}
        local size = unit:GetCollisionSize()
        local angle = 360/size*2
        local center = tree:GetAbsOrigin()
        local origin = unit:GetAbsOrigin()
        for i=0,size-1 do
            local rotate_pos = center + Vector(1,0,0) * Gatherer.MinDistanceToTree
            local point = RotatePosition(center, QAngle(0, angle*i, 0), rotate_pos)
            table.insert(points, point)
        end
        table.sort(points, function(a,b) return (a-origin):Length2D()<(b-origin):Length2D() end) --sort by distance
        local teamNumber = unit:GetTeamNumber()
        for k,point in pairs(points) do
            if not GridNav:IsBlocked(point) then
                local units = FindUnitsInRadius(teamNumber,point,nil,size,DOTA_UNIT_TARGET_TEAM_BOTH,DOTA_UNIT_TARGET_BASIC+DOTA_UNIT_TARGET_HERO,0,0,false)
                if #units == 0 or #units == 1 and units[1] == unit then
                    Gatherer:DrawCircle(point, Vector(0,255,0), unit:GetCollisionSize())
                    return point
                else
                    Gatherer:DrawCircle(point, Vector(255,0,0), unit:GetCollisionSize())
                end
            end
        end

        return center
    end

    -- After returning resource, if node was removed, find another, else gather from the same node
    function unit:ResumeGather()
        local resource = unit.last_resource_gathered
        local gather_ability = unit:GetGatherAbility()
        local return_ability = unit:GetReturnAbility()

        if gather_ability:IsHidden() then
            unit:SwapAbilities(gather_ability:GetAbilityName(), return_ability:GetAbilityName(), true, false)
        end

        if resource == "lumber" then
            if unit.target_tree then
                if unit.target_tree:IsStanding() then
                    unit:CastAbilityOnTarget(unit.target_tree, gather_ability, unit:GetPlayerOwnerID())
                else                                            
                    unit:GatherFromNearestTree(unit.target_tree:GetAbsOrigin())
                end
            else
                gather_ability:ToggleOff()
                unit:SwapAbilities(gather_ability:GetAbilityName(), return_ability:GetAbilityName(), true, false)
                Gatherer:print("Error, can't resume gathering lumber")
            end

        elseif resource == "gold" then
            if IsValidEntity(unit.target_mine) then
                unit:SwapAbilities(gather_ability:GetAbilityName(), return_ability:GetAbilityName(), true, false)
                unit:CastAbilityOnTarget(unit.target_mine, gather_ability, unit:GetPlayerOwnerID())
            else
                gather_ability:ToggleOff()
                unit:SwapAbilities(gather_ability:GetAbilityName(), return_ability:GetAbilityName(), true, false)
            end
        end
    end

    function unit:CancelGather()
        unit.state = "idle"
        unit.gatherer_state = "idle"

        unit:RemoveModifierByName("modifier_gatherer_hidden")
        if IsValidEntity(unit.mine) then
            unit.mine:RemoveGatherer(unit)
            unit:RemoveNoDraw()
        end
        if unit.gatherer_timer then Timers:RemoveTimer(unit.gatherer_timer) end

        unit:SetNoCollision(false)

        if unit.GatherAbility.callbacks and unit.GatherAbility.callbacks.OnCancelGather then
            unit.GatherAbility.callbacks.OnCancelGather()
        end
        unit.GatherAbility:ToggleOff()

        if unit.ReturnAbility then
            unit.ReturnAbility:ToggleOff()

             -- If there are resources carried, make the return ability visible
            if unit.lumber_gathered > 0 or unit.gold_gathered > 0 then
                unit.GatherAbility:SetHidden(true)
                unit.ReturnAbility:SetHidden(false)
            end
        end
    end

    -- Show the stack of resources that the unit is carrying
    function unit:SetCarriedResourceStacks(resource_name, value)
        unit[resource_name.."_gathered"] = value

        local modifierName = "modifier_carrying_"..resource_name
        if not unit:HasModifier(modifierName) then
            unit:AddNewModifier(unit, nil, modifierName, {})
        end
        unit:SetModifierStackCount(modifierName, unit, value)
    end

    -- Carrying capacity can be enhanced by upgrades, in that case the ability must have a lumber_capacity AbilitySpecial
    function unit:GetLumberCapacity()
        return unit.GatherAbility and unit.GatherAbility:GetLevelSpecialValueFor("lumber_capacity", unit.GatherAbility:GetLevel()-1) or 0
    end

    function unit:CanCarryMoreLumber()
        return unit.lumber_gathered < unit:GetLumberCapacity()
    end

    function unit:GetGoldCapacity()
        return unit.GatherAbility and unit.GatherAbility:GetLevelSpecialValueFor("gold_capacity", unit.GatherAbility:GetLevel()-1) or 0
    end

    function unit:CanCarryMoreGold()
        return not unit:HasModifier("modifier_carrying_gold")
    end

    function unit.GatherAbility:RequiresEmptyTree()
        return unit.GatherAbility:GetKeyValue("RequiresEmptyTree") == 1 or false
    end

    function unit.GatherAbility:GetGoldMineBuilding()
        return unit.GatherAbility:GetKeyValue("GoldMineBuilding") or "gold_mine"
    end

    -- Used as soon as the unit reaches the tree
    function unit:StartGatheringLumber(tree)
        local lumber_interval = unit.GatherAbility:GetKeyValue("LumberGainInterval") or 1
        local lumber_per_interval = unit.GatherAbility:GetKeyValue("LumberPerInterval") or 1
        local damage_to_tree = unit.GatherAbility:GetKeyValue("DamageTree")
        local return_ability = unit:GetReturnAbility()

        Gatherer:print("StartGatheringLumber - Gain "..lumber_per_interval.." lumber every "..lumber_interval.." seconds")
        unit:Stop()
        unit:SetForwardVector((tree:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized())
        unit.gatherer_timer = Timers:CreateTimer(lumber_interval, function()
            unit:SetForwardVector((tree:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized())
            if damage_to_tree then
                Gatherer:DamageTree(unit, tree, damage_to_tree)
            end

            -- Increase up to the max, or return the resources
            if unit:CanCarryMoreLumber() then
                if tree:IsStanding() then
                    -- Show the return ability
                    if return_ability and return_ability:IsHidden() then
                        unit:SwapAbilities(unit.GatherAbility:GetAbilityName(), return_ability:GetAbilityName(), false, true)
                    end
                else
                    -- Find another tree
                    unit:GatherFromNearestTree(tree:GetAbsOrigin())
                    return
                end

                return lumber_interval
            else  
                -- If no return, gain the resource directly
                if not return_ability then
                    unit.GatherAbility.callbacks.OnLumberGained(lumber_per_interval)
                    return lumber_interval
                else
                    -- Cast Return Resources
                    unit:CastAbilityNoTarget(return_ability, unit:GetPlayerOwnerID())
                end
            end
        end)
    end

    -- Used as soon as the unit goes inside the mine
    function unit:StartGatheringGold(mine)
        local gold_interval = unit.GatherAbility:GetKeyValue("GoldGainInterval") or 1
        local gold_per_interval = unit.GatherAbility:GetKeyValue("GoldPerInterval") or 10
        local damage_to_mine = unit.GatherAbility:GetKeyValue("DamageMine")
        local inside_gold_mine = unit.GatherAbility:GetKeyValue("GoldMineInside")
        local return_ability = unit:GetReturnAbility()

        if inside_gold_mine then
             -- Hide builder
            mine:AddGatherer(unit)
            unit:AddNoDraw()
            unit:SetAbsOrigin(mine:GetAbsOrigin())
            unit.mine = mine
        end
        unit:AddNewModifier(unit, nil, "modifier_gatherer_hidden", {restricted=not unit:GetKeyValue("GoldMineControllable")})
        unit.gatherer_state = "gathering_gold"
        
        unit.gatherer_timer = Timers:CreateTimer(gold_interval, function()
            local gold_gain = gold_per_interval
            if damage_to_mine then
                gold_gain = Gatherer:DamageMine(unit, mine, damage_to_mine)
            end

            -- If no return, gain the resource directly
            if not return_ability then
                unit.GatherAbility.callbacks.OnGoldGained(gold_gain)
                return gold_interval
            else
                -- Exit mine and return the resources
                unit.mine = nil
                mine:RemoveGatherer(unit)
                unit:RemoveNoDraw()
                unit:RemoveModifierByName("modifier_gatherer_hidden")

                local return_ability = unit:GetReturnAbility()
                return_ability:SetHidden(false)
                unit.GatherAbility:SetHidden(true)

                -- Set modifier_carrying_gold stacks
                unit:SetCarriedResourceStacks("gold", gold_gain)
                                
                -- Find where to put the builder outside the mine
                FindClearSpaceForUnit(unit, mine.entrance, true)

                -- Cast ReturnResources
                unit:ReturnResources(false)
            end
        end)
    end
end

-- Goes through the structures of the player checking for the closest valid resource deposit of this type
function CDOTA_BaseNPC:FindClosestResourceDeposit(resource_type)
    local position = self:GetAbsOrigin()
    
    -- Find a building to deliver
    local playerID = self:GetPlayerOwnerID()
    local buildings = BuildingHelper:GetBuildings(playerID)
    local distance = math.huge
    local closest_building = nil

    for _,building in pairs(buildings) do
        local buildingName = building:GetUnitName()
        local bValidResourceDeposit = Gatherer:IsUnitValidDepositForResource(building, resource_type)
        if bValidResourceDeposit and not building:IsUnderConstruction() then
            local this_distance = (position - building:GetAbsOrigin()):Length()
            if this_distance < distance then
                distance = this_distance
                closest_building = building
            end
        end
    end

    if not closest_building then
        Gatherer:print("Error: Can't find a deposit for "..resource_type.."!")
    end
    return closest_building     
end

function Gatherer:DamageTree(unit, tree, value)
    local return_ability = unit:GetReturnAbility()
    local playerID = unit:GetPlayerOwnerID()

    unit.gatherer_state = "gathering_lumber"
    local lumber_gain = math.min(tree.health, value)
    tree.health = tree.health - value
    
    if tree.health <= 0 then
        tree:CutDown(unit:GetTeamNumber())
        unit.GatherAbility.callbacks.OnTreeCutDown(tree)
    else
        unit.GatherAbility.callbacks.OnTreeDamaged(tree)
    end
        
    -- Increment lumber_gathered stacks
    unit:SetCarriedResourceStacks("lumber", unit.lumber_gathered + lumber_gain)

    return lumber_gain
end

-- Gets called after the builder goes outside the mine
-- Used in Human and Orc Gather Gold
function Gatherer:DamageMine(unit, mine, value)
    local gold_gain = math.min(mine:GetHealth(), value)

    mine:SetHealth(mine:GetHealth() - value)
    unit.gold_gathered = gold_gain

    -- If the gold mine has no health left for another harvest
    if mine:GetHealth() < value then

        -- TODO: DestroyGoldMine method
        -- Destroy the nav blockers associated with it
        for k, v in pairs(mine.blockers) do
          DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
          DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
        end
        print("Gold Mine Collapsed at ", mine:GetHealth())
        mine:RemoveSelf()

        unit.GatherAbility.callbacks.OnGoldMineCollapsed(mine)
        unit.target_mine = nil
    end

    return gold_gain
end

function Gatherer:CheckGatherCancel(order)
    local units = order.units
    local order_type = order.order_type
    local abilityIndex = order.entindex_ability or 0
    local queue = order["queue"] == 1
    local entityIndex = units["0"]
    local unit = EntIndexToHScript(entityIndex)
    if IsValidEntity(unit) then
        if order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET and abilityIndex ~= 0 then
            -- Skip BuildingHelper ghost cast
            local ability = EntIndexToHScript(abilityIndex)
            if IsValidEntity(ability) and ability:GetKeyValue("Building") then return end
        end

        local selectedEntities = PlayerResource:GetSelectedEntities(unit:GetPlayerOwnerID())
        for k,entIndex in pairs(selectedEntities) do
            local ent = EntIndexToHScript(entIndex)
            if ent and ent.CancelGather and ent.gatherer_state ~= "idle" then
                ent:CancelGather()
            elseif ent and ent.gatherer_timer then
                Timers:RemoveTimer(ent.gatherer_timer)
            end
        end
    end
end

function Gatherer:CastGatherAbility(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local target_class = target:GetClassname()

    local callbacks = Gatherer:SetGatherCallbacks(event)
    local return_ability = caster:GetReturnAbility()
    ability.callbacks = callbacks --Store em

    caster:Interrupt() -- Stops any instance of Hold/Stop the builder might have

        -- Possible states
        -- moving_to_tree
        -- moving_to_mine
        -- moving_to_repair
        -- moving_to_build (set on Building Helper when a build queue advances)
        -- returning_lumber
        -- returning_gold
        -- gathering_lumber
        -- gathering_gold
        -- repairing
        -- idle

    -- If a tree is targeted and the caster is a valid lumber gatherer
    if target_class == "ent_dota_tree" and caster:CanGatherLumber() then
        local tree = target

        -- Check if it requires an empty tree to redirect
        if ability:RequiresEmptyTree() then
            -- TODO: Builder count instead, also the .builder has to be a wisp i.e. ON TOP of it
            if (tree.builder ~= nil and tree.builder ~= caster) then
                local tree = FindEmptyNavigableTreeNearby(caster, tree:GetAbsOrigin(), 150)
                if not tree or tree == target then
                    return
                end
            end
        end

        -- If the caster already had a tree targeted but changed with a right click to another tree, destroy the old move timer
        if caster.gatherer_timer then Timers:RemoveTimer(caster.gatherer_timer) end

        caster.last_resource_gathered = "lumber"
        caster.gatherer_state = "moving_to_tree"
        caster.target_tree = tree

        tree.builder = caster --TODO: List of builders
        local tree_pos = caster:FindClearSpaceAroundTree(tree)

        -- Hide Return
        if return_ability then
            return_ability:SetHidden(true)
            ability:SetHidden(false)
        end

        -- Fake toggle the ability, cancel if any other order is given
        ability:ToggleOn()

        -- No Collision while moving to gather
        caster:SetNoCollision(true)

        caster.gatherer_timer = Timers:CreateTimer(function() 
            if not IsValidEntity(caster) or not caster:IsAlive() then return end -- End if killed

            -- Move towards the tree until close range
            local distance = (tree_pos - caster:GetAbsOrigin()):Length()
            
            if distance > self.MinDistanceToTree then
                caster:MoveToPosition(tree_pos)
                return self.ThinkInterval
            else
                -- Fire the callback to Gather
                callbacks.OnTreeReached(tree)

                -- Start the timer for lumber gain
                caster:StartGatheringLumber(tree)
                return
            end
        end)
    
    -- GOLD
    elseif string.match(target:GetUnitName(),"gold_mine") and caster:CanGatherGold() then
        local gold_mine --target can be a gold_mine or a certain type of gathering platform stored on the target.mine
        local target_name = target:GetUnitName()
        local mine_target_name = ability:GetGoldMineBuilding()
        
        if target_name ~= mine_target_name then
            print("Must target a "..mine_target_name..", not a "..target_name)
            return false
        else
            -- Redirection
            if target_name ~= "gold_mine" and IsValidEntity(target.mine) and target.mine:GetUnitName() == "gold_mine" then
                gold_mine = target.mine
            else
                gold_mine = target
            end
        end

        local mine_pos = gold_mine:GetAbsOrigin()
        caster.gold_gathered = 0
        caster.target_mine = gold_mine
        caster.target_tree = nil -- Forget the tree
        caster.last_resource_gathered = "gold"
        caster.gatherer_state = "moving_to_mine"

        -- Destroy any old move timer
        if caster.gatherer_timer then Timers:RemoveTimer(caster.gatherer_timer) end

        -- Fake toggle the ability, cancel if any other order is given
        ability:SetHidden(false)
        ability:ToggleOn()

        -- No Collision while moving to gather
        caster:SetNoCollision(true)

        local mine_entrance_pos = gold_mine.entrance+RandomVector(50)
        caster.gatherer_timer = Timers:CreateTimer(function() 
            if not IsValidEntity(caster) or not caster:IsAlive() then return end -- End if unit killed
            if not IsValidEntity(gold_mine) or not gold_mine:IsAlive() then caster:CancelGather() end -- Cancel if mine killed

            -- Move towards the mine until close range
            local distance = (mine_pos - caster:GetAbsOrigin()):Length()
            
            if distance > self.MinDistanceToMine then
                caster:MoveToPosition(mine_entrance_pos)
                return self.ThinkInterval
            else
                callbacks.OnGoldMineReached(gold_mine)
                
                if gold_mine:HasRoomForGatherer() then
                    callbacks.OnGoldMineFree(gold_mine)

                    -- Start the timer for gold gain
                    caster:StartGatheringGold(gold_mine)

                else --wait until its free
                    return self.ThinkInterval
                end
            end
        end)
            
        -- Hide Return
        local return_ability = caster:GetReturnAbility()
        if return_ability then
            return_ability:SetHidden(true)
        end
    end
end

function Gatherer:CastReturnAbility(event)
    local callbacks = Gatherer:SetReturnCallbacks(event)
    local caster = event.caster
    local return_ability = event.ability
    local playerID = caster:GetPlayerOwnerID()
    
    caster:Interrupt() -- Stops any instance of Hold/Stop the gatherer might have
    
    -- Return Ability On
    return_ability:ToggleOn()

    local gather_ability = caster:GetGatherAbility()

    -- Destroy any old move timer
    if caster.gatherer_timer then Timers:RemoveTimer(caster.gatherer_timer) end

    -- Send back to the last resource gathered
    local coming_from = caster.last_resource_gathered

    -- LUMBER
    if coming_from == "lumber" then

        -- Find where to return the resources
        local building = caster:FindClosestResourceDeposit("lumber")
        local return_position = caster:GetReturnPosition(building)
        caster.target_building = building
        caster.gatherer_state = "returning_lumber"

        -- Move towards it
        caster.gatherer_timer = Timers:CreateTimer(function() 
            if not (caster and IsValidEntity(caster) and caster:IsAlive()) then return end -- End if killed

            if caster.target_building and IsValidEntity(caster.target_building) then
                local building_pos = caster.target_building:GetAbsOrigin()
                local collision_size = building:GetHullRadius() * 2
                local distance = (building_pos - caster:GetAbsOrigin()):Length()
            
                if distance > collision_size then
                    caster:MoveToPosition(return_position)
                    return self.ThinkInterval
                else                    
                    callbacks.OnLumberDepositReached(caster.target_building)
                    caster:ResumeGather()
                    return
                end
            else
                -- Find a new building deposit
                building = caster:FindClosestResourceDeposit("lumber")
                caster.target_building = building
                return_position = caster:GetReturnPosition(building)
                return self.ThinkInterval
            end
        end)

    -- GOLD
    elseif coming_from == "gold" then
        -- Find where to return the resources
        local building = caster:FindClosestResourceDeposit("gold")
        local return_position = caster:GetReturnPosition(building)
        caster.target_building = building
        caster.target_building = building
        caster.gatherer_state = "returning_gold"
        local collision_size = building:GetHullRadius() * 2

        -- Move towards it
        caster.gatherer_timer = Timers:CreateTimer(function() 
            if not IsValidEntity(caster) or not caster:IsAlive() then return end -- End if killed
           
            if caster.target_building and IsValidEntity(caster.target_building) and caster.gatherer_state == "returning_gold" then
                local building_pos = building:GetAbsOrigin()
                local distance = (building_pos - caster:GetAbsOrigin()):Length()
            
                if distance > collision_size then
                    caster:MoveToPosition(return_position)
                    return self.ThinkInterval
                elseif caster.gold_gathered and caster.gold_gathered > 0 then

                    callbacks.OnGoldDepositReached(caster.target_building)
                    caster:ResumeGather()
                end
            else
                -- Find a new building deposit
                building = caster:FindClosestResourceDeposit("gold")
                caster.target_building = building
                return_position = caster:GetReturnPosition(building)
                return self.ThinkInterval
            end
        end)
    
    -- No resources to return, give the gather ability back
    else
        print("TRIED TO RETURN NO RESOURCES")
        gather_ability:ToggleOff()
        gather_ability:SetHidden(false)
        return_ability:SetHidden(true)
    end
end

-- Define callbacks to be returned in the gather module
function Gatherer:SetGatherCallbacks(event)
    local callbacks = {}

    -- Tree Related Callbacks
    function event:OnTreeReached(callback)
        callbacks.OnTreeReached = callback
    end

    function event:OnLumberGained(callback)
        callbacks.OnLumberGained = callback
    end

    function event:OnTreeDamaged(callback)
        callbacks.OnTreeDamaged = callback
    end

    function event:OnTreeCutDown(callback)
        callbacks.OnTreeCutDown = callback
    end

    -- Gold Mine Related Callbacks
    function event:OnGoldMineReached(callback)
        callbacks.OnGoldMineReached = callback
    end

    function event:OnGoldMineFree(callback)
        callbacks.OnGoldMineFree = callback
    end

    function event:OnGoldGained(callback)
        callbacks.OnGoldGained = callback
    end

    function event:OnGoldMineCollapsed(callback)
        callbacks.OnGoldMineCollapsed = callback
    end

    -- Shared Callbacks
    function event:OnMaxResourceGathered(callback)
        callbacks.OnMaxResourceGathered = callback
    end

    function event:OnCancelGather(callback)
        callbacks.OnCancelGather = callback
    end

    return callbacks
end

function Gatherer:SetReturnCallbacks(event)
    local callbacks = {}

    function event:OnLumberDepositReached(callback)
        callbacks.OnLumberDepositReached = callback
    end

    function event:OnGoldDepositReached(callback)
        callbacks.OnGoldDepositReached = callback
    end

    return callbacks
end

function Gatherer:GetClosestGoldMineToPosition(position)
    local allGoldMines = self.GoldMines
    local distance = math.huge
    local closest_mine = nil

    for k,gold_mine in pairs (allGoldMines) do
        if IsValidEntity(gold_mine) and not gold_mine.building_on_top then
            local mine_location = gold_mine:GetAbsOrigin()
            local this_distance = (position - mine_location):Length2D()
            if this_distance < distance then
                distance = this_distance
                closest_mine = gold_mine
            end
        end
    end
    return closest_mine
end

------------------------------------------------
--         Short methods and functions        --
------------------------------------------------

function Gatherer:ClickedOnTrees(point)
    return #GridNav:GetAllTreesAroundPoint(point, self.TreeRadius, true) > 0
end

function Gatherer:CreateSelectionParticle(unit, target, radius)
    radius = radius or 64
    local particle = ParticleManager:CreateParticleForPlayer("particles/ui_mouseactions/clicked_unit_select.vpcf", PATTACH_CUSTOMORIGIN, nil, unit:GetPlayerOwner())
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(255,255,255))
    ParticleManager:SetParticleControl(particle, 2, Vector(radius,0,0))
end

function Gatherer:IsUnitValidDepositForResource(unit, resource_type)
    return self.Deposits[unit:GetUnitName()] and self.Deposits[unit:GetUnitName()]:match(resource_type)
end

-- Defined on DeterminePathableTrees() and updated on tree_cut
function CDOTA_MapTree:IsPathable()
    return self.pathable == true
end

-- Defined on DetermineForests()
function CDOTA_MapTree:GetForestID()
    return self.forestID or 0
end

function CDOTA_MapTree:GetTreeID()
    return GetTreeIdForEntityIndex(self:GetEntityIndex())
end

function GetTreeHandleFromId(treeID)
    return EntIndexToHScript(GetEntityIndexForTreeId(tonumber(treeID)))
end

function CDOTA_BaseNPC:FindAbilityByKeyValue(key)
    local abilityName = self:GetKeyValue(key)
    if abilityName then
        return self:FindAbilityByName(abilityName)
    end
end

-- A unit is a gatherer if it has a GatherAbility KV
function CDOTA_BaseNPC:IsGatherer()
    return self:GetKeyValue("GatherAbility") ~= nil
end

function CDOTA_BaseNPC:GetGatherAbility()
    return self.GatherAbility
end

function CDOTA_BaseNPC:GetReturnAbility()
    return self.ReturnAbility
end

function CDOTA_BaseNPC:GetReturnPosition(target)
    return target:GetAbsOrigin() + (self:GetAbsOrigin() - target:GetAbsOrigin()):Normalized() * target:GetHullRadius()
end

-- Enables/disables the access to right-clicking
function CDOTA_BaseNPC:SetCanAttackTrees(bAble)
    if bAble then
        self:AddNewModifier(self, nil, "modifier_attack_trees", {})
    else
        self:RemoveModifierByName("modifier_attack_trees")
    end
end

function CDOTA_BaseNPC:CanAttackTrees()
    return self:HasModifier("modifier_attack_trees")
end

-- Enables/disables collision (phasing)
function CDOTA_BaseNPC:SetNoCollision(bAble)
    if bAble then
        self:AddNewModifier(self, nil, "modifier_no_collision", {})
    else
        self:RemoveModifierByName("modifier_no_collision")
    end
end

-- Returns true if the unit is a valid lumberjack
function CDOTA_BaseNPC:CanGatherLumber()
    local gatherResources = self:GetKeyValue("GatherResources")
    return gatherResources and gatherResources:match("lumber")
end

-- Returns true if the unit is a gold miner
function CDOTA_BaseNPC:CanGatherGold()
    local gatherResources = self:GetKeyValue("GatherResources")
    return gatherResources and gatherResources:match("gold")
end

-- ToggleAbility On only if its turned Off
function CDOTABaseAbility:ToggleOn()
    if self:GetToggleState() == false then
        self:ToggleAbility()
    end
end

-- ToggleAbility Off only if its turned On
function CDOTABaseAbility:ToggleOff()
    if self:GetToggleState() == true then
        self:ToggleAbility()
    end
end

------------------------------------------------
--                Debug methods               --
------------------------------------------------

function Gatherer:print(...)
    if self.DebugPrint then print('[Gatherer] '.. ...) end
end

function Gatherer:DrawCircle(position, vColor, radius)
    vColor = vColor or Vector(255,255,255)
    radius = radius or 32
    if self.DebugDraw then DebugDrawCircle(position, vColor, 255, radius, true, self.DebugDrawDuration) end
end

function Gatherer:DrawLine(start, target)
    if self.DebugDraw then DebugDrawLine(start, target, 255, 255, 255, true, 5) end
end

function Gatherer:DrawText(position, text)
    if self.DebugDraw then DebugDrawText(Vector(position.x-text:len()*16, position.y, position.z), text, true, self.DebugDrawDuration) end
end

-- Goes through all trees showing whether they are pathable or not
function Gatherer:DebugTrees()
    self:print("Debug drawing "..self.TreeCount.." trees")
    
    for _,tree in pairs(self.AllTrees) do
        if tree:IsStanding() then
            if tree:IsPathable() then
                self:DrawCircle(tree:GetAbsOrigin(), Vector(0,255,0), 32)
                if not tree.builder then
                    self:DrawText(tree:GetAbsOrigin(), "OK")
                end
            else
                self:DrawCircle(tree:GetAbsOrigin(), Vector(255,0,0), 32)
            end
        end
    end
end

if not Gatherer.AllTrees then Gatherer:start() else Gatherer:OnScriptReload() end


------------------------------------------------
--          TODO Dirty methods below          --
------------------------------------------------

-- A tree is "empty" if it doesn't have a stored .builder in it
function FindEmptyNavigableTreeNearby( unit, position, radius )
    local nearby_trees = GridNav:GetAllTreesAroundPoint(position, radius, true)
    local origin = unit:GetAbsOrigin()
    --DebugDrawLine(origin, position, 255, 255, 255, true, 10)

    local pathable_trees = filter(function(v) return v:IsPathable() end, nearby_trees)
    if #pathable_trees == 0 then
        print("FindEmptyNavigableTreeNearby Can't find a pathable tree with radius ",radius," for this position")
        if radius < 1000 then
            return FindEmptyNavigableTreeNearby( unit, position, radius*2 ) --TODO: Use Forests
        else
            return nil
        end
    end

    -- Sort by Closest
    local sorted_list = SortListByClosest(pathable_trees, position)

    for _,tree in pairs(sorted_list) do
        if (not tree.builder or tree.builder == unit ) and tree:IsPathable() then
            --DebugDrawCircle(tree:GetAbsOrigin(), Vector(0,255,0), 100, 32, true, 10)
            return tree
        end
    end

    return FindEmptyNavigableTreeNearby(unit, position, radius*2) --recurse on a bigger radius, potentially problematic. TODO
end

function SortListByClosest( list, position )
    local trees = {}
    for _,v in pairs(list) do
        trees[#trees+1] = v
    end

    local sorted_list = {}
    for _,tree in pairs(list) do
        local closest_tree = GetClosestEntityToPosition(trees, position)
        sorted_list[#sorted_list+1] = trees[closest_tree]
        trees[closest_tree] = nil -- Remove it
    end
    return sorted_list
end

function GetClosestEntityToPosition(list, position)
    local distance = 20000
    local closest = nil

    for k,ent in pairs(list) do
        local this_distance = (position - ent:GetAbsOrigin()):Length()
        if this_distance < distance then
            distance = this_distance
            closest = k
        end
    end

    return closest  
end

function IsMineOccupiedByTeam( mine, teamID )
    return (IsValidEntity(mine.building_on_top) and mine.building_on_top:GetTeamNumber() == teamID)
end

------------------------------------------------
--               Functional Lua               --
------------------------------------------------

-- map(double, {1,2,3,4}) -> {2,4,6,8}
function map(func, tbl)
    local newtbl = {}
    for i,v in pairs(tbl) do
        newtbl[i] = func(v)
    end
    return newtbl
end

-- filter(is_even, {1,2,3,4}) -> {2,4}
function filter(func, tbl)
    local newtbl= {}
    for i,v in pairs(tbl) do
        if func(v) then
            newtbl[i]=v
        end
    end
    return newtbl
end

-- head({1,2,3,4}) -> 1
function head(tbl)
    return tbl[1]
end

-- tail({1,2,3}) -> {2,3}
function tail(tbl)
    if #tbl < 1 then
        return nil
    else
        local newtbl = {}
        local tblsize = #tbl
        local i = 2
        while (i <= tblsize) do
            table.insert(newtbl, i-1, tbl[i])
            i = i + 1
        end
        return newtbl
    end
end

-- foldr(operator.mul, 1, {1,2,3,4,5}) -> 120
function foldr(func, val, tbl)
    for i,v in pairs(tbl) do
        val = func(val, v)
    end
    return val
end

-- reduce(operator.add, {1,2,3,4}) -> 10
function reduce(func, tbl)
    return foldr(func, head(tbl), tail(tbl))
end

operator = {
    mod = math.mod;
    pow = math.pow;
    add = function(n,m) return n + m end;
    sub = function(n,m) return n - m end;
    mul = function(n,m) return n * m end;
    div = function(n,m) return n / m end;
    gt  = function(n,m) return n > m end;
    lt  = function(n,m) return n < m end;
    eq  = function(n,m) return n == m end;
    le  = function(n,m) return n <= m end;
    ge  = function(n,m) return n >= m end;
    ne  = function(n,m) return n ~= m end;
}

---------------------------------------------------------------