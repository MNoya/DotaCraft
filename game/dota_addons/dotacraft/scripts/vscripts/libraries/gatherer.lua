if not Gatherer then
    Gatherer = class({})
end

TREE_HEALTH = 50 --TODO: Setings file
TREE_RADIUS = 50
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
    
    -- Game Event Listeners
    ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(Gatherer, 'OnGameRulesStateChange'), self)
    ListenToGameEvent('tree_cut', Dynamic_Wrap(Gatherer, 'OnTreeCut'), self)

    -- Panorama Event Listeners
    CustomGameEventManager:RegisterListener("right_click_order", Dynamic_Wrap(Gatherer, "OnRightClick"))

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

function Gatherer:OnRightClick(event)
    local playerID = event.PlayerID
    local point = event.position
    if not point then return end
    local position = GetGroundPosition(Vector(point["0"], point["1"], 0), nil)

    if Gatherer:ClickedOnTrees(position) then
        Gatherer:print("Clicked On Trees around "..VectorString(position))
        Gatherer:OnTreeClick(PlayerResource:GetSelectedEntities(playerID), position)
    end
end

-- Tree Gather Right-Click
function Gatherer:OnTreeClick(units, position)
    local entityIndex = units["0"]
    local unit = EntIndexToHScript(entityIndex)
    if not unit:CanGatherLumber() then return end
   
    local race = GetUnitRace(unit)
    local gather_ability = FindGatherAbility(unit)
    local return_ability = FindReturnAbility(unit)
    local pID = unit:GetPlayerOwnerID()
    local player = PlayerResource:GetPlayer(pID)

    -- If clicking near a tree with the first unit of the selection group
    if unit:CanGatherLumber() then
        if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
            local empty_tree = FindEmptyNavigableTreeNearby(unit, position, TREE_RADIUS)
            if empty_tree then
                local tree_index = empty_tree:GetTreeID()
                --print("Order: Cast on Tree ",tree_index)
                ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
            end
        elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
            -- Can the unit still gather more resources?
            if (unit.lumber_gathered and unit.lumber_gathered < unit:GetLumberCapacity()) and not unit:HasModifier("modifier_returning_gold") then
                --print("Keep gathering")

                -- Swap to a gather ability and keep extracting
                local empty_tree = FindEmptyNavigableTreeNearby(unit, position, TREE_RADIUS)
                if empty_tree then
                    local tree_index = empty_tree:GetTreeID()
                    unit:SwapAbilities(gather_ability:GetAbilityName(), return_ability:GetAbilityName(), true, false)
                    --print("Order: Cast on Tree ",tree_index)
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                end
            else
                -- Return
                local empty_tree = FindEmptyNavigableTreeNearby(unit, position, TREE_RADIUS)
                unit.target_tree = empty_tree --The new selected tree
                --print("Order: Return resources")
                unit.gatherer_skip = false -- Let it propagate to all selected units
                ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = queue})
            end
        end
        return false
    end
end

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
        print("No unit!", entityIndex, unit)
        return true
    end

    -- Get the currently selected units and send new orders
    local entityList = PlayerResource:GetSelectedEntities(unit:GetPlayerOwnerID())
    if not entityList then
        return true
    end

    ------------------------------------------------
    --              No Target Return              --
    ------------------------------------------------
    if order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET and abilityIndex and abilityIndex ~= 0 then
        
        local ability = EntIndexToHScript(abilityIndex)
        if not ability then
            print("Error: CAST_NO_TARGET with an incorrect index")
            return true
        end
        local abilityName = ability:GetAbilityName()

        if string.match(abilityName, "_return_resources") then
            for k,entIndex in pairs(entityList) do
                local ent = EntIndexToHScript(entIndex)
                ent.gatherer_skip = true

                local return_ability = FindReturnAbility(ent)
                if return_ability and not return_ability:IsHidden() then
                    --print("Order: Return resources")
                    ExecuteOrderFromTable({ UnitIndex = entIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = queue})
                end
            end
        end
        return true

    ------------------------------------------------
    --          Tree Gather Multi Orders          --
    ------------------------------------------------
    elseif order_type == DOTA_UNIT_ORDER_CAST_TARGET_TREE then
        if DEBUG then print("DOTA_UNIT_ORDER_CAST_TARGET_TREE ",unit) end
    
        local abilityIndex = abilityIndex
        local ability = EntIndexToHScript(abilityIndex) 
        local abilityName = ability:GetAbilityName()

        local treeID = targetIndex
        local tree_index = GetEntityIndexForTreeId(treeID)
        local tree_handle = EntIndexToHScript(tree_index)

        local position = tree_handle:GetAbsOrigin()
        if DEBUG then
            DebugDrawCircle(position, Vector(255,0,0), 100, 150, true, 5)
            DebugDrawLine(unit:GetAbsOrigin(), position, 255, 255, 255, true, 5)
            print("Ability "..abilityName.." cast on tree number ",targetIndex, " handle index ",tree_handle:GetEntityIndex(),"position ",position)
        end
        if not string.match(abilityName, "gather") then
            return true
        end

        if DEBUG then DebugDrawText(unit:GetAbsOrigin(), "LOOKING FOR TREE INDEX "..targetIndex, true, 10) end

        local numBuilders = 0
        for k,entityIndex in pairs(entityList) do
            local u = EntIndexToHScript(entityIndex)
            if u:CanGatherLumber() then
                numBuilders = numBuilders + 1
            end
        end

        if numBuilders == 1 then
            return true
        end

        if abilityName == "nightelf_gather" then
            for k,entityIndex in pairs(entityList) do
                --print("GatherTreeOrder for unit index ",entityIndex, position)

                --Execute the order to a navigable tree
                local ent = EntIndexToHScript(entityIndex)
                local empty_tree = FindEmptyNavigableTreeNearby(ent, position, 150 + 20 * numBuilders)
                if empty_tree then
                    local tree_index = empty_tree:GetTreeID()
                    empty_tree.builder = ent -- Assign the wisp to this tree, so next time this isn't empty
                    ent.gatherer_skip = true
                    local gather_ability = ent:FindAbilityByName("nightelf_gather")
                    if gather_ability and gather_ability:IsFullyCastable() then
                        --print("Order: Cast on Tree ",tree_index)
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                    end
                else
                    --print("No Empty Tree?")
                end
            end

        elseif string.match(abilityName,"_gather") then

            for k,entityIndex in pairs(entityList) do
                --print("GatherTreeOrder for unit index ",entityIndex, position)

                --Execute the order to a navigable tree
                local unit = EntIndexToHScript(entityIndex)
                local race = GetUnitRace(unit)
                local empty_tree = FindEmptyNavigableTreeNearby(unit, position, 150 + 20 * numBuilders)
                if empty_tree then 

                    empty_tree.builder = unit
                    unit.gatherer_skip = true
                    local gather_ability = FindGatherAbility(unit)
                    local return_ability = FindReturnAbility(unit)
                    if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                        local tree_index = empty_tree:GetTreeID()
                        --print("Order: Cast on Tree ",tree_index)
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                    elseif return_ability and not return_ability:IsHidden() then
                        --print("Order: Return resources")
                        unit.gatherer_skip = false -- Let it propagate to all selected units
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = queue})
                    end
                else
                    print("No Empty Tree?")
                end
            end
        end

        -- Drop the original order
        return false
    end

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

    function unit:FindGatherTree()
        -- similar to to FindEmptyNavigableTreeNearby
    end

    function unit:FindGoldMine()
        -- this could be not just gold mine but other npc based resource nodes
    end

    function unit:ReturnResources()
        -- use the return ability
    end

    function unit:CancelGather()
        -- cancel process
    end

    function unit:CancelReturn()
        -- cancel process
    end

    function unit:GetLumberCapacity()
        local gather_ability = FindGatherAbility( unit )
        return gather_ability and gather_ability:GetLevelSpecialValueFor("lumber_capacity", gather_ability:GetLevel()-1) or 0
    end

    unit:SetCanAttackTrees(true)
end

function CDOTA_BaseNPC:IsGatherer()
    -- return if it has been Init
end

------------------------------------------------
--         Short methods and functions        --
------------------------------------------------

function Gatherer:ClickedOnTrees(point)
    return #GridNav:GetAllTreesAroundPoint(point, TREE_RADIUS, true) > 0
end

-- Defined on DeterminePathableTrees() and updated on tree_cut
function CDOTA_MapTree:IsPathable()
    return self.pathable == true
end

function CDOTA_MapTree:GetTreeID()
    return GetTreeIdForEntityIndex(self:GetEntityIndex())
end

function GetTreeHandleFromId(treeID)
    return EntIndexToHScript(GetEntityIndexForTreeId(tonumber(treeID)))
end

-- Enables/disables the access to right-clicking
function CDOTA_BaseNPC:SetCanAttackTrees(bAble)
    if bAble then
        self:AddNewModifier(self, nil, "modifier_attack_trees", {})
    else
        self:RemoveModifierByName("modifier_attack_trees")
    end
end

-- Returns true if the unit is a valid lumberjack
function CDOTA_BaseNPC:CanGatherLumber()
    local gatherResources = self:GetKeyValues()["GatherResources"]
    return gatherResources and gatherResources:match("lumber")
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

if not Gatherer.AllTrees then Gatherer:start() end


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

    return FindEmptyNavigableTreeNearby(unit, position, radius*2) --recurse on a bigger radius, potentially problematic. TODO
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

-- Returns true if the unit is a gold miner
function CanGatherGold( unit )
    local unitName = unit:GetUnitName()
    local unitTable = GameRules.UnitKV[unitName]
    local gatherResources = unitTable and unitTable["GatherResources"]
    return gatherResources and string.match(gatherResources,"gold")
end

function FindGatherAbility( unit )
    local unitName = unit:GetUnitName()
    local unitTable = GameRules.UnitKV[unitName]
    local abilityName = unitTable and unitTable["GatherAbility"]
    return unit:FindAbilityByName(abilityName)
end

function FindReturnAbility( unit )
    local unitName = unit:GetUnitName()
    local unitTable = GameRules.UnitKV[unitName]
    local abilityName = unitTable and unitTable["ReturnAbility"]
    return unit:FindAbilityByName(abilityName)
end

---------------------------------------------------------------