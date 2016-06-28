if not Drops then
    Drops = class({})
end

function Drops:Init()
    self.DropList = LoadKeyValues("scripts/kv/map_drops.kv")
    self.TierList = LoadKeyValues(("scripts/kv/items.kv"))

    -- Validate item drops
    local missing = {}
    for mapName,mapDrops in pairs(self.DropList) do
        for creepName,creepDrops in pairs(mapDrops) do
            for item_type,v in pairs(creepDrops) do
                if item_type == "item" then
                    local itemName = "item_"..v
                    if not GetItemKV(itemName) then
                        if not missing.singles then missing.singles = {} end
                        missing.singles[v] = 1
                    end
                else
                    local item_type_table = self.TierList[item_type]
                    local possible_item_drops = item_type_table[tostring(v)]
                    local choices = TableCount(possible_item_drops)
                    for i=1,choices do
                        local itemName = "item_"..possible_item_drops[tostring(i)]
                        if not GetItemKV(itemName) then
                            if not missing[item_type] then missing[item_type] = {} end
                            missing[item_type][itemName] = 1
                        end
                    end
                end
            end
        end
    end
    local miss = TableCount(missing)
    if miss > 0 then
        self:print("MISSING ITEMS")
        for k,cat in pairs(missing) do
            print("-- "..k:upper().." --")
            for name,_ in pairs(cat) do
                print("\""..name.."\"")
            end
        end
    end
end

-- Returns a list of all the possible map drops of the current map
function Drops:GetMapDropList()
    local drops = {}
    local mapDrops = self.DropList[dotacraft:GetMapName()]
    for creepName,creepDrops in pairs(mapDrops) do
        for item_type,v in pairs(creepDrops) do
            if item_type == "item" then
                local itemName = "item_"..v
                drops[itemName] = true
            else
                local item_type_table = self.TierList[item_type]
                local possible_item_drops = item_type_table[tostring(v)]
                local choices = TableCount(possible_item_drops)
                for i=1,choices do
                    local itemName = "item_"..possible_item_drops[tostring(i)]
                    drops[itemName] = true
                end
            end
        end
    end
    local dropList = {}
    for k,v in pairs(drops) do
        table.insert(dropList,k)
    end

    return dropList    
end

function Drops:GetRandomDrop()
    local possible_item_drops = self:GetMapDropList()
    return possible_item_drops[RandomInt(1, #possible_item_drops)]
end

function Drops:Roll( creep )
    if creep:GetName() == "npc_dota_creature" then return end -- If the creep doesnt have a hammer name, it won't drop items
    local cutCreep = string.find(creep:GetName(), '_', 1, true)
    if not cutCreep then
        self:print("ERROR: Creep hammer name should follow the naming format XYZ_creepname, got '"..creep:GetName().."' instead")
        return
    end
    local targetName = string.sub(creep:GetName(), cutCreep+1) -- Name of the entity in hammer, starting after first entityIndex_

    local mapName = dotacraft:GetMapName()
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
                local itemName = "item_"..possible_item_drops[tostring(RandomInt(1, choices))]
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
Drops:Init()