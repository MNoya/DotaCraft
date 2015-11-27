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
        if (not tree.builder or tree.builder == unit ) and IsTreePathable(tree) then
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
        if IsTreePathable(tree) then
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

-- This is defined on dotacraft:DeterminePathableTrees() and updated on tree_cut
function IsTreePathable( tree )
    return tree.pathable
end

function GetTreeIndexFromHandle(tree)
    return GetTreeIdForEntityIndex(empty_tree:GetEntityIndex())
end