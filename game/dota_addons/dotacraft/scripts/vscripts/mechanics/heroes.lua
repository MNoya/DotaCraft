-- Returns string with the name of the city center associated with the hero_name
function GetCityCenterNameForHeroRace( hero_name )
    local citycenter_name = ""
    if hero_name == "npc_dota_hero_dragon_knight" then
        citycenter_name = "human_town_hall"
    elseif hero_name == "npc_dota_hero_furion" then
        citycenter_name = "nightelf_tree_of_life"
    elseif hero_name == "npc_dota_hero_life_stealer" then
        citycenter_name = "undead_necropolis"
    elseif hero_name == "npc_dota_hero_huskar" then
        citycenter_name = "orc_great_hall"
    end
    return citycenter_name
end

-- Returns string with the name of the builders associated with the hero_name
function GetBuilderNameForHeroRace( hero_name )
    local builder_name = ""
    if hero_name == "npc_dota_hero_dragon_knight" then
        builder_name = "human_peasant"
    elseif hero_name == "npc_dota_hero_furion" then
        builder_name = "nightelf_wisp"
    elseif hero_name == "npc_dota_hero_life_stealer" then
        builder_name = "undead_acolyte"
    elseif hero_name == "npc_dota_hero_huskar" then
        builder_name = "orc_peon"
    end
    return builder_name
end

function GetInternalHeroName( hero_name )
    local hero_table = GameRules.HeroKV[hero_name]
    if hero_table and hero_table["InternalName"] then
        return hero_table["InternalName"]
    else
        return hero_name
    end
end

function GetRealHeroName( internal_hero_name )
    local heroes = GameRules.HeroKV
    for hero_name,v in pairs(heroes) do
        for key,value in pairs(v) do
            if value == internal_hero_name then
                return hero_name
            end
        end
    end
end

-- Auxiliar function that goes through every ability and item, checking for any ability being channelled
function IsChanneling ( hero )
    
    for abilitySlot=0,15 do
        local ability = hero:GetAbilityByIndex(abilitySlot)
        if ability ~= nil and ability:IsChanneling() then 
            return true
        end
    end

    for itemSlot=0,5 do
        local item = hero:GetItemInSlot(itemSlot)
        if item ~= nil and item:IsChanneling() then
            return true
        end
    end

    return false
end