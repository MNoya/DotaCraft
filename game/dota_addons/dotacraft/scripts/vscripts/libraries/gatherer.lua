if not Gatherer then
    Gatherer = class({})
end

TREE_HEALTH = 50 --TODO: Setings file
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

    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(Gatherer, 'OnGameRulesStateChange'), self)
    ListenToGameEvent('tree_cut', Dynamic_Wrap(Gatherer, 'OnTreeCut'), self)

    self.bShouldLoadTreeMap = not IsInToolsMode() -- Always re-determine pathable trees in tools, to account for map changes.
    self.DebugPrint = true
    self.DebugDraw = false
    self.DebugDrawDuration = 60
    self.indent = string.rep(" ",4)

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

function Gatherer:OnGameRulesStateChange(event)
    local newState = GameRules:State_Get()
    if newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        self:InitTrees()
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

function Gatherer:OrderFilter(order)
    local ret = true    

    if Gatherer.nextFilter then
        ret = Gatherer.nextFilter(Gatherer.nextContext, order)
    end

    if not ret then
        return false
    end

    local issuerID = order.issuer_player_id_const

    if issuerID == -1 then return true end

    -- Order filter goes here

    return true
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
        t.health = TREE_HEALTH
    end

    self:DeterminePathableTrees() -- Obtain tree map
end

function Gatherer:DeterminePathableTrees()
    -- Load an existing tree map
    if self.bShouldLoadTreeMap then
        local treeMapFile = LoadKeyValues("maps/tree_maps/"..GetMapName()..".txt")
        if treeMapFile then
            self:LoadTreeMap(treeMapFile)
            return
        else
            self:print("No Tree Map file found for "..GetMapName())
        end
    end

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

    -- Write to file
    self:GenerateTreeMap()
end

function Gatherer:LoadTreeMap(treeMapTable)
    local pathable_count = 0
    for treeID,value in pairs (treeMapTable) do
        local tree = GetTreeHandleFromId(treeID)
        if tree then
            local bPathable = value == 1
            if bPathable then pathable_count = pathable_count + 1 end
            tree.pathable = bPathable
        end
    end
    self:print("Loaded Tree Map for "..GetMapName())
    self:print("Pathable count: "..pathable_count.." out of "..self.TreeCount)
end

function Gatherer:GenerateTreeMap()
    local path = "../../dota_addons/"..self.addonName.."/maps/tree_maps/"..GetMapName()..".txt"
    self.treeMap = io.open(path, 'w')
    if not self.treeMap then
        self:print("Error: Can't open path "..path)
        return
    end

    self:print("Generating Tree Map for "..GetMapName().."...")
    self.treeMap:write("\""..GetMapName().."_TreeMap\"\n{\n")
    for _,tree in pairs(self.AllTrees) do
        local value = tree:IsPathable() and 1 or 0
        self.treeMap:write(self.indent.."\""..tree:GetTreeID().."\" \""..value.."\"\n")
    end
    self.treeMap:write("}")
    self.treeMap:close()
    self:print("Tree Map generated at "..path)
end

------------------------------------------------
--                Unit Methods                --
------------------------------------------------

-- TODO
function Gatherer:Init(unit)
    -- index gather/return ability
    -- give ability modifier to attack trees  
end

function CDOTA_BaseNPC:IsGatherer()
    -- return if it has been Init
end

function CDOTA_BaseNPC:FindGatherTree()
    -- similar to to FindEmptyNavigableTreeNearby
end

function CDOTA_BaseNPC:FindGoldMine()
    -- body
end

function CDOTA_BaseNPC:ReturnResources()
    -- use the return ability
end

function CDOTA_BaseNPC:CancelGather()
    -- cancel process
end


------------------------------------------------
--         Short methods and functions        --
------------------------------------------------

-- Defined on DeterminePathableTrees() and updated on tree_cut
function CDOTA_MapTree:IsPathable()
    return self.pathable == true
end

function CDOTA_MapTree:GetTreeID()
    return GetTreeIdForEntityIndex(self:GetEntityIndex())
end

-- Deprecated, should be replaced by tree:GetTreeID()
function GetTreeIndexFromHandle(treeHandle)
    return GetTreeIdForEntityIndex(treeHandle:GetEntityIndex())
end

function GetTreeHandleFromId(treeID)
    return EntIndexToHScript(GetEntityIndexForTreeId(tonumber(treeID)))
end

------------------------------------------------
--                Debug methods               --
------------------------------------------------

function Gatherer:print(...)
    if self.DebugPrint then print('[Gatherer] '.. ...) end
end

function Gatherer:DrawCircle(position, vColor, radius)
    if self.DebugDraw then DebugDrawCircle(position, vColor, 100, radius, true, self.DebugDrawDuration) end
end

function Gatherer:DrawText(position, text)
    if self.DebugDraw then DebugDrawText(position, text, true, self.DebugDrawDuration) end
end

-- Goes through all trees showing whether they are pathable or not
function Gatherer:DebugTrees()
    if not self.DebugDraw then return end
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

if not Gatherer.Trees then Gatherer:start() end


------------------------------------------------
--          TODO Dirty methods below          --
------------------------------------------------

-- A tree is "empty" if it doesn't have a stored .builder in it
function FindEmptyNavigableTreeNearby( unit, position, radius )
    local nearby_trees = GridNav:GetAllTreesAroundPoint(position, radius, true)
    local origin = unit:GetAbsOrigin()
    --DebugDrawLine(origin, position, 255, 255, 255, true, 10)

    local pathable_trees = GetAllPathableTreesFromList(nearby_trees)
    if #pathable_trees == 0 then
        print("FindEmptyNavigableTreeNearby Can't find a pathable tree with radius ",radius," for this position")
        return nil
    end

    -- Sort by Closest
    local sorted_list = SortListByClosest(pathable_trees, position)

    for _,tree in pairs(sorted_list) do
        if (not tree.builder or tree.builder == unit ) and tree:IsPathable() then
            --DebugDrawCircle(tree:GetAbsOrigin(), Vector(0,255,0), 100, 32, true, 10)
            return tree
        end
    end

    --print("NO EMPTY NAVIGABLE TREE NEARBY")
    return nil
end

function GetAllPathableTreesFromList( list )
    local pathable_trees = {}
    for _,tree in pairs(list) do
        if tree:IsPathable() then
            table.insert(pathable_trees, tree)
        end
    end
    return pathable_trees
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

---------------------------------------------------------------