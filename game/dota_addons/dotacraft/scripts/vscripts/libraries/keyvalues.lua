--[[
    Simple Lua KeyValues library
    Author: Martin Noya // github.com/MNoya

    Installation:
    - require this file inside your code

    Usage:
    - Your npc custom files will be validated on require, error will occur if one is missing or has faulty syntax.
    - This allows to safely grab key-value definitions in npc custom abilities/items/units/heroes
    
        "some_custom_entry"
        {
            "CustomName" "Barbarian"
            "CustomKey"  "1"
            "CustomStat" "100 200"
        }

        With a handle:
            handle:GetKeyValue() -- returns the whole table based on the handles baseclass
            handle:GetKeyValue("CustomName") -- returns "Barbarian"
            handle:GetKeyValue("CustomKey")  -- returns 1 (number)
            handle:GetKeyValue("CustomStat") -- returns 100 or 200 if level of the handle equals 2
        
        Same results with strings:
            GetKeyValue("some_custom_entry")
            GetKeyValue("some_custom_entry", "CustomName")
            GetKeyValue("some_custom_entry", "CustomStat") -- default level 1
            GetKeyValue("some_custom_entry", "CustomStat", 2) -- get the level 2 of the value

    - Ability Special value grabbing:

        "some_custom_ability"
        {
            "AbilitySpecial"
            {
                "01"
                {
                    "var_type"    "FIELD_INTEGER"
                    "some_key"    "-3 -4 -5"
                }
            }
        }

        With string:
            GetAbilitySpecial("some_custom_ability", "some_key")    -- returns "-3 -4 -5"
            GetAbilitySpecial("some_custom_ability", "some_key", 2) -- returns "-4"

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
    return GetUnitKV(self:GetUnitName(), key, self:GetLevel())
end

-- Dynamic version of CDOTABaseAbility:GetAbilityKeyValues()
function CDOTABaseAbility:GetKeyValue(key)
    return GetAbilityKV(self:GetAbilityName(), key, self:GetLevel())
end

-- Item version
function CDOTA_Item:GetKeyValue(key)
    return GetItemKV(self:GetAbilityName(), key, self:GetLevel())
end

-- Global functions
-- Key is optional, returns the whole table by omission
-- Level is optional, returns the whole value by omission
function GetKeyValue(name, key, level)
    local t = KeyValues.All[name]
    if key and t then
        if t[key] and level then return split(t[key])[level]
        else return t[key] end
    else return t end
end

function GetUnitKV(unitName, key, level)
    local t = KeyValues.UnitKV[unitName]
    if key and t then
        if t[key] and level then return split(t[key])[level]
        else return t[key] end
    else return t end
end

function GetAbilityKV(abilityName, key, level)
    local t = KeyValues.AbilityKV[abilityName]
    if key and t then
        if t[key] and level then return split(t[key])[level]
        else return t[key] end
    else return t end
end

function GetItemKV(itemName, key, level)
    local t = KeyValues.ItemKV[itemName]
    if key and t then
        if t[key] and level then return split(t[key])[level]
        else return t[key] end
    else return t end
end

function GetAbilitySpecial(name, key, level)
    local t = KeyValues.All[name]
    if key and t then
        local tspecial = t["AbilitySpecial"]
        if tspecial then
            -- Find the key we are looking for
            for _,values in pairs(tspecial) do
                if values[key] then
                    if not level then return values[key]
                    else
                        print(values[key])
                        local s = split(values[key])
                        if s[level] then return s[level] -- If we match the level, return that one
                        else return s[#s] end -- Otherwise, return the max
                    end
                    break
                end
            end
        end
    else return t end
end

function split(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

if not KeyValues.All then LoadGameKeyValues() end