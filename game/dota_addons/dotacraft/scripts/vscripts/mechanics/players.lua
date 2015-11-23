-- Returns float with the percentage to reduce income
function GetUpkeep( player )
    if player.food_used > 80 then
        return 0.4 -- High Upkeep
    elseif player.food_used > 50 then
        return 0.7 -- Low Upkeep
    else
        return 1 -- No Upkeep
    end
end

-- Returns bool
function PlayerHasEnoughGold( player, gold_cost )
    local hero = player:GetAssignedHero()
    local pID = hero:GetPlayerID()
    local gold = hero:GetGold()

    if not gold_cost or  gold > gold_cost then 
        return true
    else
        SendErrorMessage(pID, "#error_not_enough_gold")
        return true
    end
end


-- Returns bool
function PlayerHasEnoughLumber( player, lumber_cost )
    local pID = player:GetAssignedHero():GetPlayerID()

    if not lumber_cost or player.lumber > lumber_cost then 
        return true 
    else
        SendErrorMessage(pID, "#error_not_enough_lumber")
        return false
    end
end

-- Return bool
function PlayerHasEnoughFood( player, food_cost )
    local pID = player:GetAssignedHero():GetPlayerID()

    if player.food_used + food_cost > player.food_limit then
        -- send the warning only once every time
        if not player.need_more_farms then
            local race = GetPlayerRace(player)
            SendErrorMessage(pID, "#error_not_enough_food_"..race)
            player.need_more_farms = true
        end
        return false
    else
        return true
    end
end

-- Returns bool
function PlayerHasResearch( player, research_name )
    if player.upgrades[research_name] then
        return true
    else
        return false
    end
end

-- Returns bool
function PlayerHasRequirementForAbility( player, ability_name )
    local requirements = GameRules.Requirements
    local buildings = player.buildings
    local upgrades = player.upgrades
    local requirement_failed = false

    if requirements[ability_name] then

        -- Go through each requirement line and check if the player has that building on its list
        for k,v in pairs(requirements[ability_name]) do

            -- If it's an ability tied to a research, check the upgrades table
            if requirements[ability_name].research then
                if k ~= "research" and (not upgrades[k] or upgrades[k] == 0) then
                    --print("Failed the research requirements for "..ability_name..", no "..k.." found")
                    return false
                end
            else
                --print("Building Name","Need","Have")
                --print(k,v,buildings[k])

                -- If its a building, check every building requirement
                if not buildings[k] or buildings[k] == 0 then
                    --print("Failed one of the requirements for "..ability_name..", no "..k.." found")
                    return false
                end
            end
        end
    end

    return true
end


-- Return ability handle or nil
function FindAbilityOnStructures( player, ability_name )
    local structures = player.structures

    for _,building in pairs(structures) do
        local ability_found = building:FindAbilityByName(ability_name)
        if ability_found then
            return ability_found
        end
    end
    return nil
end

-- Return ability handle or nil
function FindAbilityOnUnits( player, ability_name )
    local units = player.units

    for _,unit in pairs(units) do
        local ability_found = unit:FindAbilityByName(ability_name)
        if ability_found then
            return ability_found
        end
    end
    return nil
end


-- Returns int, 0 if not PlayerHasResearch()
function GetCurrentResearchRank( player, research_name )
    local upgrades = player.upgrades
    local max_rank = MaxResearchRank( research_name )

    local current_rank = 0
    if max_rank > 0 then
        for i=1,max_rank do
            local ability_len = string.len(research_name)
            local this_research = string.sub(research_name, 1 , ability_len - 1)..i
            if PlayerHasResearch(player, this_research) then
                current_rank = i
            end
        end
    end

    return current_rank
end

-- Goes through the structures of the player, checking for the max level city center
-- If no city center is found, the player has a 2 minute window in which a city center must be built or all his structures will be revealed
function CheckCurrentCityCenters( player )
    local structures = player.structures
    local city_center_level = 0
    for k,building in pairs(structures) do
        if IsCityCenter(building) then
            local level = building:GetLevel()
            if level > city_center_level then
                city_center_level = level
            end
        end
    end
    player.city_center_level = city_center_level

    print("Current City Center Level for player "..player:GetPlayerID().." is: "..city_center_level)

    if player.city_center_level == 0 then
        local time_to_reveal = 120
        print("Player "..player:GetPlayerID().." has no city centers left standing. Revealed in "..time_to_reveal.." seconds until a City Center is built.")
        player.RevealTimer = Timers:CreateTimer(time_to_reveal, function()
            RevealPlayerToAllEnemies(player)
        end)
    else
        StopRevealingPlayer(player)
    end
end

-- Creates revealer entities on each building of the player
function RevealPlayerToAllEnemies( player )
    local playerID = player:GetPlayerID()
    local units = player.units
    local structures = player.structures

    print("Revealing Player "..playerID)

    local playerName = PlayerResource:GetPlayerName(playerID)
    if playerName == "" then playerName = "Player "..playerID end
    GameRules:SendCustomMessage("Revealing "..playerName, 0, 0)

    for k,building in pairs(structures) do
        local origin = building:GetAbsOrigin()
        local vision = buildling:GetDayTimeVisionRange()
        local ent = SpawnEntityFromTableSynchronous("ent_fow_revealer", {origin = origin, vision = vision, teamnumber = 0})
        building.revealer = ent
    end
end

function StopRevealingPlayer( player )
    local structures = player.structures

    print("Stop Revealing Player "..player:GetPlayerID())

    if player.RevealTimer then
        Timers:RemoveTimer(player.RevealTimer)
        player.RevealTimer = nil
    end

    for k,building in pairs(structures) do
        if building.revealer then
            DoEntFireByInstanceHandle(building.revealer, "Kill", "1", 1, nil, nil)
            building.revealer = nil
        end
    end
end

-- Returns the player.city_center_level
function GetPlayerCityLevel( player )
    return player.city_center_level
end

-- Returns a string with the race of the player
function GetPlayerRace( player )
    local hero = player:GetAssignedHero()
    local hero_name = hero:GetUnitName()
    local race
    if hero_name == "npc_dota_hero_dragon_knight" then
        race = "human"
    elseif hero_name == "npc_dota_hero_furion" then
        race = "nightelf"
    elseif hero_name == "npc_dota_hero_life_stealer" then
        race = "undead"
    elseif hero_name == "npc_dota_hero_huskar" then
        race = "orc"
    end
    return race
end

function FindHighestLevelCityCenter( caster )
    local player = caster:GetPlayerOwner()
    local position = caster:GetAbsOrigin()
    if not player then print("ERROR, NO PLAYER") return end
    local buildings = player.structures
    local level = 0 --Priority to the highest level city center
    local distance = 20000
    local closest_building = nil

    for _,building in pairs(buildings) do
        if IsValidAlive(building) and IsCityCenter(building) and building.state == "complete" and building:GetLevel() > level then
            level = building:GetLevel()
            local this_distance = (position - building:GetAbsOrigin()):Length()
            if this_distance < distance then
                distance = this_distance
                closest_building = building
            end
        end
    end
    return closest_building
end

-- Hero count is limited to 3
function CanPlayerTrainMoreHeroes( playerID )
    local player = PlayerResource:GetPlayer(playerID)
    return (player.heroes and #player.heroes < 3)
end

function HeroCountForPlayer( playerID )
    local player = PlayerResource:GetPlayer(playerID)
    if player and player.heroes then
        return #player.heroes
    else
        return 0
    end
end