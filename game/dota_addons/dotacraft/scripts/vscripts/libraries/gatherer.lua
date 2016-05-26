require("libraries/timers")
require("libraries/keyvalues")

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
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(Gatherer, 'OnNPCSpawned'), self)
    ListenToGameEvent('tree_cut', Dynamic_Wrap(Gatherer, 'OnTreeCut'), self)

    -- Panorama Event Listeners
    CustomGameEventManager:RegisterListener("right_click_order", Dynamic_Wrap(Gatherer, "OnRightClick"))
    CustomGameEventManager:RegisterListener("gold_gather_order", Dynamic_Wrap(Gatherer, "OnGoldMineClick"))
    CustomGameEventManager:RegisterListener("repair_order", Dynamic_Wrap(Gatherer, "OnBuildingRepairClick"))

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
        Gatherer:print("Clicked On Trees around "..VectorString(position))
        Gatherer:OnTreeClick(PlayerResource:GetSelectedEntities(playerID), position)
    end
end

------------------------------------------------
--           Tree Gather Right-Click          --
------------------------------------------------
function Gatherer:OnTreeClick(units, position)
    local entityIndex = units["0"]
    local unit = EntIndexToHScript(entityIndex)
    if not unit:CanGatherLumber() then return end -- first unit must be able to get lumber
   
    local gather_ability = unit:GetGatherAbility()
    local return_ability = unit:GetReturnAbility()

    -- If clicking near a tree
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
    local gather_ability = unit:GetGatherAbility()

    -- Gold gather
    if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
        --print("Order: Cast on ",gold_mine:GetUnitName())
        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
    elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
        -- Can the unit still gather more resources?
        if (unit.lumber_gathered and unit.lumber_gathered < unit:GetLumberCapacity()) and not unit:HasModifier("modifier_returning_gold") then
            --print("Keep gathering")

            -- Swap to a gather ability and keep extracting
            unit:SwapAbilities(gather_ability:GetAbilityName(), unit:GetReturnAbility():GetAbilityName(), true, false)
            --print("Order: Cast on ",gold_mine:GetUnitName())
            ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
        else
            -- Return
            local return_ability = unit:GetReturnAbility()
            unit.target_mine = gold_mine
            --print("Order: Return resources")
            unit.gatherer_skip = false -- Let it propagate to all selected units
            ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = queue})
        end
    end
end

------------------------------------------------
--             Repair Right-Click             --
------------------------------------------------
function Gatherer:OnBuildingRepairClick(event)
    local playerID = event.PlayerID
    local entityIndex = event.mainSelected
    local targetIndex = event.targetIndex
    local building = EntIndexToHScript(targetIndex)
    local selectedEntities = PlayerResource:GetSelectedEntities(playerID)
    local queue = tobool(event.queue)

    local unit = EntIndexToHScript(entityIndex)
    local repair_ability = unit:GetRepairAbility()

    -- Repair
    if repair_ability and repair_ability:IsFullyCastable() and not repair_ability:IsHidden() then
        --print("Order: Repair ",building:GetUnitName())
        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = repair_ability:GetEntityIndex(), Queue = queue})
    elseif repair_ability and repair_ability:IsFullyCastable() and repair_ability:IsHidden() then
        --print("Order: Repair ",building:GetUnitName())
        
        -- Swap to the repair ability and send repair order
        unit:SwapAbilities(repair_ability:GetAbilityName(), unit:GetReturnAbility():GetAbilityName(), true, false)
        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = repair_ability:GetEntityIndex(), Queue = queue})
    end
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
        print("No unit!", entityIndex, unit)
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
            print("Error: CAST_NO_TARGET with an incorrect index")
            return true
        end
        local abilityName = ability:GetAbilityName()

        -- TODO this sucks
        if string.match(abilityName, "_return_resources") then
            for k,entIndex in pairs(entityList) do
                local ent = EntIndexToHScript(entIndex)
                ent.gatherer_skip = true

                local return_ability = ent:GetReturnAbility()
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
        if DEBUG then --TODO debug properly
            DebugDrawCircle(position, Vector(255,0,0), 100, 150, true, 5)
            DebugDrawLine(unit:GetAbsOrigin(), position, 255, 255, 255, true, 5)
            print("Ability "..abilityName.." cast on tree number ",targetIndex, " handle index ",tree_handle:GetEntityIndex(),"position ",position)
        end
        if not string.match(abilityName, "gather") then
            return true
        end

        if DEBUG then DebugDrawText(unit:GetAbsOrigin(), "LOOKING FOR TREE INDEX "..targetIndex, true, 10) end

        -- TODO filter
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
            -- TODO: This sucks
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
            -- TODO: This also sucks
            for k,entityIndex in pairs(entityList) do
                --print("GatherTreeOrder for unit index ",entityIndex, position)

                --Execute the order to a navigable tree
                local unit = EntIndexToHScript(entityIndex)
                local race = GetUnitRace(unit)
                local empty_tree = FindEmptyNavigableTreeNearby(unit, position, 150 + 20 * numBuilders)
                if empty_tree then 

                    empty_tree.builder = unit
                    unit.gatherer_skip = true
                    local gather_ability = unit:GetGatherAbility()
                    local return_ability = unit:GetReturnAbility()
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

    ------------------------------------------------
    --        Gold Mine Gather Multi Orders       --
    ------------------------------------------------
    elseif DOTA_UNIT_ORDER_CAST_TARGET and targetIndex ~= 0 then
        local target_handle = EntIndexToHScript(targetIndex)
        local target_name = target_handle:GetUnitName()

        if target_name == "gold_mine" or
          ((target_name == "nightelf_entangled_gold_mine" or target_name == "undead_haunted_mine") and target_handle:GetTeamNumber() == unit:GetTeamNumber()) then

            local gold_mine = target_handle
            for k,entityIndex in pairs(entityList) do
                local unit = EntIndexToHScript(entityIndex)
                local race = GetUnitRace(unit)
                local gather_ability = FindGatherAbility(unit)
                local return_ability = FindReturnAbility(unit)

                -- Gold gather
                if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
                    unit.gatherer_skip = true
                    --print("Order: Cast on ",gold_mine:GetUnitName())
                    ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
                    -- Can the unit still gather more resources?
                    if (unit.lumber_gathered and unit.lumber_gathered < unit:GetLumberCapacity()) and not unit:HasModifier("modifier_returning_gold") then
                        --print("Keep gathering")

                        -- Swap to a gather ability and keep extracting
                        unit.gatherer_skip = true
                        unit:SwapAbilities(gather_ability:GetAbilityName(), return_ability:GetAbilityName(), true, false)
                        --print("Order: Cast on ",gold_mine:GetUnitName())
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = targetIndex, AbilityIndex = gather_ability:GetEntityIndex(), Queue = queue})
                    else
                        -- Return
                        unit.target_mine = gold_mine
                        --print("Order: Return resources")
                        unit.gatherer_skip = false -- Let it propagate to all selected units
                        ExecuteOrderFromTable({ UnitIndex = entityIndex, OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = queue})
                    end
                end
            end
        end
    end

    Gatherer:CheckGatherCancel(order)

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

function Gatherer:DetermineForests()
    -- body
end

------------------------------------------------
--                Unit Methods                --
------------------------------------------------

-- TODO
function Gatherer:Init(unit)
    self:print("Init "..unit:GetUnitName().." "..unit:GetEntityIndex())

    -- Give modifier to attack trees
    unit:SetCanAttackTrees(true)

    -- Permanent access to gather and return abilities (if any)
    unit.GatherAbility = unit:FindAbilityByKeyValue("GatherAbility")
    unit.ReturnAbility = unit:FindAbilityByKeyValue("ReturnAbility")

    print("Gather Ability is ",unit.GatherAbility)
    print("Return Ability is ",unit.ReturnAbility)

    -- Keep track of how much resources is the unit carrying
    unit.lumber_gathered = 0
    unit.gold_gathered = 0

    -- Find a tree near a position and cast the gather ability on it
    function unit:GatherFromNearestTree(position)
        position = position or unit:GetAbsOrigin() -- If no position, use the unit origin


    end

    function unit:FindGatherTree()
        -- similar to to FindEmptyNavigableTreeNearby
    end

    -- Find a gold mine near the unit current position and cast the gather ability on it
    function unit:GatherFromNearestGoldMine()
        -- body
    end

    function unit:FindGoldMine()
        -- this could be not just gold mine but other npc based resource nodes
    end

    function unit:ReturnResources()
        -- use the return ability, swap as required
    end

    -- After returning resource, if note was removed, find another, else gather from the same node
    function unit:ResumeGather()

    end

    function unit:CancelGather()
        local caster = unit
        caster.state = "idle"

        print("CancelGather")

        if unit.gatherer_timer then Timers:RemoveTimer(unit.gatherer_timer) end

        unit:RemoveModifierByName("modifier_gathering_lumber")
        unit:RemoveModifierByName("modifier_gathering_gold")

        if unit.GatherAbility and unit.GatherAbility.callbacks and unit.GatherAbility.OnCancelGather then
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

    -- Carrying capacity can be enhanced by upgrades, in that case the ability must have a lumber_capacity AbilitySpecial
    function unit:GetLumberCapacity()
        return unit.GatherAbility and unit.GatherAbility:GetLevelSpecialValueFor("lumber_capacity", unit.GatherAbility:GetLevel()-1) or 0
    end

    function unit:GetGatherAbility()
        return unit.GatherAbility
    end

    function unit:GetReturnAbility()
        return unit.ReturnAbility
    end

    function unit.GatherAbility:RequiresEmptyTree()
        return unit.GatherAbility:GetKeyValue("RequiresEmptyTree") == 1 or false
    end

    function unit.GatherAbility:GetGoldMineTarget()
        return unit.GatherAbility:GetKeyValue("GoldMineTarget") or "gold_mine"
    end
end

function Gatherer:CheckGatherCancel(order)
    local units = order.units
    local order_type = order.order_type
    local abilityIndex = order.entindex_ability or 0
    local queue = order["queue"] == 1
    local entityIndex = units["0"]
    local unit = EntIndexToHScript(entityIndex)

    if unit and unit.CancelGather then
        if order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET and abilityIndex ~= 0 then

            -- Skip BuildingHelper ghost cast
            local ability = EntIndexToHScript(abilityIndex)
            if IsValidEntity(ability) and ability:GetKeyValue("Building") then return end
        
        end
        unit:CancelGather()
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
        local tree_pos = tree:GetAbsOrigin()

        -- Hide Return
        if return_ability then
            return_ability:SetHidden(true)
            ability:SetHidden(false)
        end

        -- Fake toggle the ability, cancel if any other order is given
        ability:ToggleOn()

        -- Recieving another order will cancel this
        --ability:ApplyDataDrivenModifier(caster, caster, "modifier_on_order_cancel_lumber", {})
        --apply MODIFIER_STATE_NO_UNIT_COLLISION
        --TODO: Do this without a modifier, or with lua modifier. Ability should be clean.

        caster.gatherer_timer = Timers:CreateTimer(function() 
            if not IsValidEntity(caster) or not caster:IsAlive() then return end -- End if killed

            -- Move towards the tree until close range
            local distance = (tree_pos - caster:GetAbsOrigin()):Length()
            
            if distance > MIN_DISTANCE_TO_TREE then
                caster:MoveToPosition(tree_pos)
                return THINK_INTERVAL
            else
                -- Fire the callback to Gather
                callbacks.OnTreeReached(tree)

                -- TODO: code this without a modifier, remove MODIFIER_STATE_NO_UNIT_COLLISION
                ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_lumber", {})
                return
            end
        end)
    
    -- GOLD
    elseif string.match(target:GetUnitName(),"gold_mine") and caster:CanGatherGold() then
        local gold_mine --target can be a gold_mine or a certain type of gathering platform stored on the target.mine
        local target_name = target:GetUnitName()
        local mine_target_name = ability:GetGoldMineTarget()
        
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
        caster.state = "moving_to_mine"

        -- Destroy any old move timer
        if caster.gatherer_timer then
            Timers:RemoveTimer(caster.gatherer_timer)
        end

        -- Fake toggle the ability, cancel if any other order is given
        ability:SetHidden(false)
        ability:ToggleOn()

        local mine_entrance_pos = gold_mine.entrance+RandomVector(50)
        caster.gatherer_timer = Timers:CreateTimer(function() 
            if not IsValidEntity(caster) or not caster:IsAlive() then return end -- End if killed

            -- Move towards the mine until close range
            local distance = (mine_pos - caster:GetAbsOrigin()):Length()
            
            if distance > MIN_DISTANCE_TO_MINE then
                caster:MoveToPosition(mine_entrance_pos)
                return THINK_INTERVAL
            else
                callbacks.OnGoldMineReached(gold_mine)
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
    
    caster:Interrupt() -- Stops any instance of Hold/Stop the builder might have
    
    -- Return Ability On
    return_ability:ToggleOn()

    local gather_ability = caster:GetGatherAbility()

    -- Destroy any old move timer
    if caster.gatherer_timer then Timers:RemoveTimer(caster.gatherer_timer) end

    -- Send back to the last resource gathered
    local coming_from = caster.last_resource_gathered

    -- LUMBER
    if caster:HasModifier("modifier_carrying_lumber") then
        -- Find where to return the resources
        local building = FindClosestResourceDeposit( caster, "lumber" )
        caster.target_building = building
        caster.gatherer_state = "returning_lumber"

        -- Move towards it
        caster.gatherer_timer = Timers:CreateTimer(function() 
            if not (caster and IsValidEntity(caster) and caster:IsAlive()) then return end -- End if killed

            if caster.target_building and IsValidEntity(caster.target_building) and caster.gatherer_state == "returning_lumber" then
                local building_pos = caster.target_building:GetAbsOrigin()
                local collision_size = GetCollisionSize(building)*2 --TODO Require BuildingHelper ?
                local distance = (building_pos - caster:GetAbsOrigin()):Length()
            
                if distance > collision_size then
                    caster:MoveToPosition(GetReturnPosition( caster, building ))        
                    return THINK_INTERVAL
                elseif caster.lumber_gathered and caster.lumber_gathered > 0 then
                    
                    callbacks.OnLumberDepositReached(caster.target_building)

                    SendBackToGather(caster, gather_ability, caster.last_resource_gathered)
                
                    return
                end
            else
                -- Find a new building deposit
                building = FindClosestResourceDeposit( caster, "lumber" )
                caster.target_building = building
                return THINK_INTERVAL
            end
        end)

    -- GOLD
    elseif caster:HasModifier("modifier_carrying_gold") then
        -- Find where to return the resources
        local building = FindClosestResourceDeposit( caster, "gold" ) --TODO Clean method
        caster.target_building = building
        caster.gatherer_state = "returning_gold"
        local collision_size = GetCollisionSize(building)*2 --TODO Remove

        -- Move towards it
        caster.gatherer_timer = Timers:CreateTimer(function() 
            if not IsValidEntity(caster) or not caster:IsAlive() then return end -- End if killed
           
            if caster.target_building and IsValidEntity(caster.target_building) and caster.gatherer_state == "returning_gold" then
                local building_pos = building:GetAbsOrigin()
                local distance = (building_pos - caster:GetAbsOrigin()):Length()
            
                if distance > collision_size then
                    caster:MoveToPosition(GetReturnPosition( caster, building ))
                    return THINK_INTERVAL
                elseif caster.gold_gathered and caster.gold_gathered > 0 then

                    callbacks.OnGoldDepositReached(caster.target_building)
                    SendBackToGather(caster, gather_ability, caster.last_resource_gathered)
                end
            else
                -- Find a new building deposit
                building = FindClosestResourceDeposit( caster, "gold" )
                caster.target_building = building
                return THINK_INTERVAL
            end
        end)
    
    -- No resources to return, give the gather ability back
    else
        --print("TRIED TO RETURN NO RESOURCES")
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

    function event:OnCurrentTreeCutDown(callback)
        callbacks.OnCurrentTreeCutDown = callback
    end

    -- Gold Mine Related Callbacks
    function event:OnGoldMineReached(callback)
        callbacks.OnGoldMineReached = callback
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

-- These should be deprecated all across the files
function FindGatherAbility( unit )
    if IsValidEntity(unit.GatherAbility) then return unit.GatherAbility end
    local abilityName = unit:GetKeyValue("GatherAbility")
    if abilityName then unit:FindAbilityByName(abilityName) end
end

function FindReturnAbility( unit )
    if IsValidEntity(unit.ReturnAbility) then return unit.ReturnAbility end
    local abilityName = unit:GetKeyValue("ReturnAbility")
    if abilityName then return unit:FindAbilityByName(abilityName) end
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

    local pathable_trees = filter(function(v) return v:IsPathable() end, nearby_trees)
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

function GetReturnPosition( unit, target )
    local origin = unit:GetAbsOrigin()
    local building_pos = target:GetAbsOrigin()
    local distance = target:GetHullRadius()
    return building_pos + (origin - building_pos):Normalized() * distance
end

function GetClosestGoldMineToPosition( position )
    local allGoldMines = Entities:FindAllByModel('models/mine/mine.vmdl') --Target name in Hammer
    local distance = 20000
    local closest_mine = nil
    for k,gold_mine in pairs (allGoldMines) do
        local mine_location = gold_mine:GetAbsOrigin()
        local this_distance = (position - mine_location):Length()
        if this_distance < distance then
            distance = this_distance
            closest_mine = gold_mine
        end
    end
    return closest_mine
end

function IsMineOccupiedByTeam( mine, teamID )
    return (IsValidEntity(mine.building_on_top) and mine.building_on_top:GetTeamNumber() == teamID)
end

-- Goes through the structures of the player finding the closest valid resource deposit of this type
function FindClosestResourceDeposit( caster, resource_type )
    local position = caster:GetAbsOrigin()
    
    -- Find a building to deliver
    local player = caster:GetPlayerOwner()
    local playerID = caster:GetPlayerOwnerID()
    local race = Players:GetRace(playerID)

    local buildings = Players:GetStructures(playerID)
    local distance = 20000
    local closest_building = nil

    if resource_type == "gold" then
        for _,building in pairs(buildings) do
            if building and IsValidEntity(building) and building:IsAlive() then
                if IsValidGoldDepositName( building:GetUnitName(), race ) and building.state == "complete" then
                    local this_distance = (position - building:GetAbsOrigin()):Length()
                    if this_distance < distance then
                        distance = this_distance
                        closest_building = building
                    end
                end
            end
        end

    elseif resource_type == "lumber" then
        for _,building in pairs(buildings) do
            if building and IsValidEntity(building) and building:IsAlive() then
                if IsValidLumberDepositName( building:GetUnitName(), race ) and building.state == "complete" then
                    local this_distance = (position - building:GetAbsOrigin()):Length()
                    if this_distance < distance then
                        distance = this_distance
                        closest_building = building
                    end
                end
            end
        end
    end
    if not closest_building then
        print("[ERROR] CANT FIND A DEPOSIT RESOURCE FOR "..resource_type.."! This shouldn't happen")
    end
    return closest_building     

end

function IsValidGoldDepositName( building_name, race )
    local GOLD_DEPOSITS = GameRules.Buildings[race]["gold"]
    for name,_ in pairs(GOLD_DEPOSITS) do
        if GOLD_DEPOSITS[building_name] then
            return true
        end
    end

    return false
end

function IsValidLumberDepositName( building_name, race )
    local LUMBER_DEPOSITS = GameRules.Buildings[race]["lumber"]
    for name,_ in pairs(LUMBER_DEPOSITS) do
        if LUMBER_DEPOSITS[building_name] then
            return true
        end
    end

    return false
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