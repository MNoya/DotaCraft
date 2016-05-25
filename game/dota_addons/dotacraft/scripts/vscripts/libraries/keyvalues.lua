--[[
    Simple Lua KeyValues library by Noya

    Installation:
    - require this file inside your code

    Usage:
    - Your npc custom files will be validated on require, error will occur if one is missing or has faulty syntax.
    - This allows to safely grab key-value definitions in npc custom abilities/items/units/heroes
    
        "some_custom_entry"
        {
            "CustomName" "Barbarian"
            "CustomStat" "100"
        }

        With a handle:
            handle:GetKeyValue() -- returns the whole table based on the handles baseclass
            handle:GetKeyValue("CustomName") -- returns "Barbarian"
        
        Same results with strings:
            GetKeyValue("some_custom_entry")
            GetKeyValue("some_custom_entry", "CustomName")

    Notes:
    - In case a key can't be matched, the returned value will be nil
    - Don't identify your units/heroes with the same name or it will only grab one of them.
]]

if not KeyValues then
    KeyValues = {}
end

-- Load all the necessary key value files
function LoadGameKeyValues()
    local scriptPath ="scripts/npc/"
    local files = { AbilityKV = "npc_abilities_custom", ItemKV = "npc_items_custom",
                    UnitKV = "npc_units_custom", HeroKV = "npc_heroes_custom" }

    -- Load and validate the files
    for k,v in pairs(files) do
        local file = LoadKeyValues(scriptPath..v..".txt")
        if not file then
            print("[KeyValues] Critical Error on "..v..".txt")
            return
        else
            GameRules[k] = file --backwards compatibility
            KeyValues[k] = file
        end
    end   

    -- Merge All KVs
    KeyValues.All = {}
    for name,path in pairs(files) do
        for key,value in pairs(KeyValues[name]) do
            if not KeyValues.All[key] then
                KeyValues.All[key] = value
            else
                --print("[KeyValues] Duplicated entry for "..key.." found in "..path)
            end
        end
    end

    -- Merge units and heroes
    for key,value in pairs(KeyValues.HeroKV) do
        if not KeyValues.UnitKV[key] then
            KeyValues.UnitKV[key] = value
        else
            --print("[KeyValues] Duplicated unit/hero entry for "..key)
        end
    end
end

-- Works for heroes and units on the same table due to merging both tables on game init
function CDOTA_BaseNPC:GetKeyValue(key)
    return GetUnitKV(self:GetUnitName(), key)
end

-- Dynamic version of CDOTABaseAbility:GetAbilityKeyValues()
function CDOTABaseAbility:GetKeyValue(key)
    return GetAbilityKV(self:GetAbilityName(), key)
end

-- Item version
function CDOTA_Item:GetKeyValue(key)
    return GetItemKV(self:GetAbilityName(), key)
end

-- Global functions. Key is optional (returns the whole table by omission)
function GetKeyValue(name, key)
    local t = KeyValues.All[name]
    if key and t then return t[key]
    else return t end
end

function GetUnitKV(unitName, key)
    local t = KeyValues.UnitKV[unitName]
    if key and t then return t[key]
    else return t end
end

function GetAbilityKV(abilityName, key)
    local t = KeyValues.AbilityKV[abilityName]
    if key and t then return t[key]
    else return t end
end

function GetItemKV(itemName, key)
    local t = KeyValues.ItemKV[itemName]
    if key and t then return t[key]
    else return t end
end

if not KeyValues.All then LoadGameKeyValues() end