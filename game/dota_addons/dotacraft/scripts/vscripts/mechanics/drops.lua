if not Drops then
    Drops = class({})
end

function Drops:Init()
    self.DropList = LoadKeyValues("scripts/kv/map_drops.kv")
    self.TierList = LoadKeyValues(("scripts/kv/items.kv"))

    -- Validate item drops of the current map
    local cutMap = string.find(GetMapName(), '_', 1, true)
    local mapName = string.sub(GetMapName(), cutMap+1)
    local mapDrops = self.DropList[mapName]

    for creepName,creepDrops in pairs(mapDrops) do
        for item_type,v in pairs(creepDrops) do
            if item_type == "item" then
                if not GetItemKV(v) then
                    self:print("MISSING "..v.." for "..creepName)
                end
            else
                local item_type_table = self.TierList[item_type]
                local possible_item_drops = item_type_table[tostring(v)]
                local choices = TableCount(possible_item_drops)
                for i=1,choices do
                    if not GetItemKV(possible_item_drops[tostring(i)]) then
                        self:print("MISSING "..possible_item_drops[tostring(i)].." for "..creepName)
                    end
                end
            end
        end
    end
end

function Drops:Roll( creep )
    if creep:GetName() == "npc_dota_creature" then return end -- If the creep doesnt have a hammer name, it won't drop items
    local cutCreep = string.find(creep:GetName(), '_', 1, true)
    if not cutCreep then
        self:print("ERROR: Creep hammer name should follow the naming format XYZ_creepname, got '"..creep:GetName().."' instead")
        return
    end
    local targetName = string.sub(creep:GetName(), cutCreep+1) -- Name of the entity in hammer, starting after first entityIndex_
    local cutMap = string.find(GetMapName(), '_', 1, true)
    if not cutMap then
        self:print("ERROR: Map name should follow the naming format X_mapname, got '"..GetMapName().."' instead")
        return
    end
    local mapName = string.sub(GetMapName(), cutMap+1) -- Map name starting after first X_
    local mapDrops = self.DropList[mapName]
    if not mapDrops then
        self:print("ERROR: Missing drop info for "..mapName)
        return
    end

    local creepDrops = mapDrops[targetName]
    if not creepDrops then
        self:print("ERROR: Missing "..targetName.." info for "..mapName.." in map_drops.kv")
    else
        -- Reach each drop line
        for item_type,v in pairs(creepDrops) do
            if item_type == "item" then
                self:print("Dropping "..v)
                self:Create(v, creep:GetAbsOrigin())
            else
                local item_type_table = self.TierList[item_type]
                local possible_item_drops = item_type_table[tostring(v)]
                local choices = TableCount(possible_item_drops)
                local itemName = possible_item_drops[tostring(RandomInt(1, choices))]
                self:print("Dropping one "..item_type.." from level "..v.." at random... "..itemName)
                self:Create(itemName, creep:GetAbsOrigin())
            end
        end
    end
end

function Drops:Create( item_name, origin )
    local item = CreateItem(item_name, nil, nil)
    if not item then
        self:print("ERROR: Could not find data for item drop! "..item_name)
        return
    end

    item:SetPurchaseTime(0)
    local drop = CreateItemOnPositionSync( origin, item )
    local pos_launch = origin+RandomVector(RandomFloat(50,100))
    item:LaunchLoot(false, 200, 0.75, pos_launch)
end

function Drops:print( ... )
    print("[DROPS] ".. ...)
end

if not Drops.DropList then Drops:Init() end