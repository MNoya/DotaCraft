if not Heroes then
    Heroes = class({})
end

XP_PER_LEVEL_TABLE = {
    0, -- 1
    200, -- 2 +200
    500, -- 3 +300
    900, -- 4 +400
    1400, -- 5 +500
    2000, -- 6 +600
    2700, -- 7 +700
    3500, -- 8 +800
    4400, -- 9 +900
    5400 -- 10 +1000
 }

XP_CREEP_BOUNTY_TABLE = {
    25, 40, 60, 85, 115, 150, 190, 235, 285, 340
}
XP_HERO_BOUNTY_TABLE = {
    100, 120, 160, 220, 300, 400, 500, 600, 700, 800
}
XP_FIND_RADIUS = 1000

XP_NEUTRAL_SCALING = {
    0.80, 0.70, 0.62, 0.55,
    0, 0, 0, 0, 0, 0 
}

XP_SINGLEHERO_TIER_BONUS = {[2] = 1.15, [3] = 1.30}

function Heroes:DistributeXP(killed, attacker)
    if killed:IsIllusion() then return end -- Illusions don't grant XP
    if attacker:GetTeamNumber() == killed:GetTeamNumber() then return end -- Denies don't grant XP, also takes care of summons expiring

    -- You do not receive experience if any building such as a tower or ancient makes the killing blow.
    if IsCustomBuilding(attacker) then return end
    
    -- Heroes gain experience for attacking buildings with attacks such as towers.
    if IsCustomBuilding(killed) and not killed:HasAttackCapability() then return end

    local XPGain = killed:IsRealHero() and XP_HERO_BOUNTY_TABLE[killed:GetLevel()] or XP_CREEP_BOUNTY_TABLE[killed:GetLevel()]
    if not XPGain then return end

    -- You can receive experience for killing units of dropped players, but not get experience if your Heroes are over level 5
    local bDisconnectedOwner = false
    local bNeutral = killed:GetTeamNumber() == DOTA_TEAM_NEUTRALS
    local killedID = killed:GetPlayerOwnerID() or -1
    if killedID ~= -1 then
        local kHero = PlayerResource:GetSelectedHeroEntity(killedID)
        if kHero and kHero:HasOwnerAbandoned() then
            bDisconnectedOwner = true
        end
    end

    local teamNumber = attacker:GetTeamNumber()
    if teamNumber == DOTA_TEAM_NEUTRALS then return end

    -- If one Hero is nearby, but another is not, only the nearby Hero gains experience
    local heroList = FindUnitsInRadius(teamNumber, killed:GetAbsOrigin(), nil, XP_FIND_RADIUS, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

    -- Kills made when no Hero is nearby result in all your Heroes' (even allies) receiving experience
    if #heroList == 0 then
        heroList = Heroes:TeamHeroList(teamNumber)
    end

    local validHeroes = {}
    for _,hero in pairs(heroList) do
        local heroLevel = hero:GetLevel()
         -- Don't split experience if the heroes can't gain it (Improvement over wc3, where the XP is just lost)
        if hero:IsAlive() and ((bNeutral and heroLevel < 5) or (not bNeutral and heroLevel < 10)) then
            table.insert(validHeroes, hero)
        end
    end

    local heroCount = #validHeroes
    print("Distribute "..XPGain.." XP between "..heroCount.." heroes")
    for _,hero in pairs(validHeroes) do
        if hero:IsRealHero() and hero:GetTeam() ~= killed:GetTeam() then
            local bonus = ""

            -- Scale XP if neutral
            local xp = XPGain
            if bNeutral then
                local heroLevel = hero:GetLevel()
                xp = (XPGain * XP_NEUTRAL_SCALING[heroLevel]) / heroCount
                bonus = bonus.." [-"..(100-XP_NEUTRAL_SCALING[heroLevel]*100).."% due to neutral]"
            end

            -- If a player owns only one hero (dead heroes count), and is at tier 2 or Tier 3, they gain bonus experience.
            local playerID = hero:GetPlayerOwnerID()
            if #Players:GetHeroes(playerID) == 1 then
                local cityLevel = Players:GetCityLevel(playerID) or 0
                if cityLevel > 1 then
                    bonus = bonus.." [+"..(XP_SINGLEHERO_TIER_BONUS[cityLevel]-1).."% due to city level "..cityLevel.."]"
                    xp = xp * XP_SINGLEHERO_TIER_BONUS[cityLevel]
                end
            end
            xp = math.floor(xp+0.5)

            hero:AddExperience(xp, false, false)
            Scores:IncrementXPGained( hero:GetPlayerID(), xp )
            print("  Granted "..xp.." XP"..bonus.." to "..hero:GetUnitName())
        end 
    end
end

-- Returns a list of all heroes trained by this team, to use when spliting XP globally
function Heroes:TeamHeroList(teamNumber)
    local heroes = {}
    local playerIDs = Teams:GetPlayersOnTeam(teamNumber)
    for _,playerID in pairs(playerIDs) do
        local playerHeroes = Players:GetHeroes(playerID)
        for _,hero in pairs(playerHeroes) do
            table.insert(heroes, hero)
        end
    end
    return heroes
end

-- Returns a string with the race of the hero
-- Hero race names must be defined in the "Label" keyvalue
function CDOTA_BaseNPC_Hero:GetRace()
    return self:GetUnitLabel()
end

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

function GetHeroNameForRace( race )
    if race == "human" then
        return "npc_dota_hero_dragon_knight"
    elseif race == "orc" then
        return "npc_dota_hero_huskar"
    elseif race == "nightelf" then
        return "npc_dota_hero_furion"
    elseif race == "undead" then
        return "npc_dota_hero_life_stealer"
    end
end

function GetInternalHeroName( hero_name )
    return GetUnitKV(hero_name, "InternalName")
end

function GetRealHeroName( internal_hero_name )
    local heroes = KeyValues.UnitKV
    for hero_name,v in pairs(heroes) do
        for key,value in pairs(v) do
            if key == "InternalName" and type(value) == "string" and value:match(internal_hero_name) then
                return hero_name
            end
        end
    end
end