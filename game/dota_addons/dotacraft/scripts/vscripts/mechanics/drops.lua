function DropItems( creep )
    if creep:GetName() == "npc_dota_creature" then return end -- If the creep doesnt have a hammer name, it won't drop items
    local targetName = string.sub(creep:GetName(), 5) -- Name of the entity in hammer, skip first 4 characters to match towards the item_drops.kv
    local mapName = string.sub(GetMapName(), 3) -- This will have issues for maps starting with 10_ or more
    local dropTable = GameRules.Drops
    local itemTable = GameRules.Items

    print(creep:GetClassname(), creep:GetDebugName())

    local mapDrops = dropTable[mapName]
    if not mapDrops then
        print("ERROR: Missing drop info for "..mapName)
        return
    end

    local creepDrops = mapDrops[targetName]
    if not creepDrops then
        print("ERROR: Missing "..targetName.." info for "..mapName.." in map_drops.kv")
    else
        -- Reach each drop line
        for item_type,v in pairs(creepDrops) do
            if item_type == "item" then
                print("Dropping "..v)
                CreateDrop(v, creep:GetAbsOrigin())
            else
                local item_type_table = itemTable[item_type]
                local possible_item_drops = item_type_table[tostring(v)]
                local choices = TableCount(possible_item_drops)
                local itemName = possible_item_drops[tostring(RandomInt(1, choices))]
                print("Dropping one "..item_type.." from level "..v.." at random...","Got: ", itemName)
                CreateDrop(itemName, creep:GetAbsOrigin())
            end
        end
    end
end

function CreateDrop( item_name, origin )
    local item = CreateItem(item_name, nil, nil)
    if not item then
        print("ERROR: Could not find data for item drop! "..item_name)
        return
    end

    item:SetPurchaseTime(0)
    local drop = CreateItemOnPositionSync( origin, item )
    local pos_launch = origin+RandomVector(RandomFloat(50,100))
    item:LaunchLoot(false, 200, 0.75, pos_launch)
end