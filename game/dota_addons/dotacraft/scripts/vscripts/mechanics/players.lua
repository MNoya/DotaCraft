if not Players then
    Players = class({})
end

function Players:Init( playerID, hero )

    -- Tables
    hero.units = {} -- This keeps the handle of all the units of the player army, to iterate for unlocking upgrades
    hero.structures = {} -- This keeps the handle of the constructed units, to iterate for unlocking upgrades
    hero.heroes = {} -- Owned hero units (not this assigned hero, which will be a fake)
    hero.altar_structures = {} -- Keeps altars linked

    hero.buildings = {} -- This keeps the name and quantity of each building
    hero.upgrades = {} -- This kees the name of all the upgrades researched, so each unit can check and upgrade itself on spawn

    hero.idle_builders = {} -- Keeps indexes of idle builders to send to the panorama UI
    
    -- Resource tracking
    hero.gold = 0
    hero.lumber = 0
    hero.food_limit = 0 -- The amount of food available to build units
    hero.food_used = 0 -- The amount of food used by this player creatures

    -- Other variables
    hero.city_center_level = 1
    hero.altar_level = 1
end

---------------------------------------------------------------

function Players:GetUnits( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.units
end

function Players:GetStructures( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.structures
end

function Players:GetHeroes( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.heroes
end

function Players:GetAltars( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.altar_structures
end

function Players:GetUpgradeTable( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.upgrades
end

function Players:GetBuildingTable( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.buildings
end

function Players:GetIdleBuilders( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.idle_builders
end

-- Returns the city_center_level
function Players:GetCityLevel( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero and hero.city_center_level or 1
end

function Players:SetCityCenterLevel( playerID, level )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    hero.city_center_level = level
end

-- Returns float with the percentage to reduce income
function Players:GetUpkeep( playerID )
    local food_used = Players:GetFoodUsed(playerID)
    if food_used > 80 then
        return 0.4 -- High Upkeep
    elseif food_used > 50 then
        return 0.7 -- Low Upkeep
    else
        return 1 -- No Upkeep
    end
end

-- Adjusts name inside tools
function Players:GetPlayerName( playerID )
    local playerName = PlayerResource:GetPlayerName(playerID)
    if playerName == "" then playerName = "Player "..playerID end
    return playerName
end

---------------------------------------------------------------

function Players:GetGold( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero:GetGold()
end

function Players:GetLumber( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.lumber
end

function Players:GetFoodUsed( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    
    return hero.food_used
end

function Players:GetFoodLimit( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    
    return hero.food_limit
end

---------------------------------------------------------------

function Players:SetGold( playerID, value )
    local player = PlayerResource:GetPlayer(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    
    hero:SetGold(value, false)
    hero.gold = value
    --CustomGameEventManager:Send_ServerToPlayer(player, "player_gold_changed", { gold = math.floor(hero.gold) })
end

function Players:SetLumber( playerID, value )
    local player = PlayerResource:GetPlayer(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    
    hero.lumber = value

    CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = math.floor(hero.lumber) })
	Players:UpdateJavaScriptPlayer(playerID);
end

function Players:SetFoodLimit( playerID, value )
    local player = PlayerResource:GetPlayer(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    
    hero.food_limit = value
    CustomGameEventManager:Send_ServerToPlayer(player, 'player_food_changed', { food_used = hero.food_used, food_limit = hero.food_limit }) 
	Players:UpdateJavaScriptPlayer(playerID);
end

function Players:SetFoodUsed( playerID, value )
    local player = PlayerResource:GetPlayer(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    hero.food_used = value
    CustomGameEventManager:Send_ServerToPlayer(player, 'player_food_changed', { food_used = hero.food_used, food_limit = hero.food_limit }) 
	Players:UpdateJavaScriptPlayer(playerID)
end

function Players:UpdateJavaScriptPlayer(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)	
	
	local Gold = math.floor(hero.gold)
	local Lumber = math.floor(hero.lumber)
	local FoodUsed = hero.food_used
	local FoodLimit = hero.food_limit
	
	local PlayerTable = GetNetTableValue("dotacraft_player_table", tostring(playerID))
	local ColorID = PlayerTable.Color;

	SetNetTableValue("dotacraft_player_table", tostring(playerID), {Color = ColorID, food_used = FoodUsed, food_limit = FoodLimit, lumber = Lumber, gold = Gold})
end
---------------------------------------------------------------

-- Modifies the gold of this player, accepts negative values
function Players:ModifyGold( playerID, gold_value )
    PlayerResource:ModifyGold(playerID, gold_value, false, 0)
end

-- Modifies the lumber of this player, accepts negative values
function Players:ModifyLumber( playerID, lumber_value )
    if lumber_value == 0 then return end

    local current_lumber = Players:GetLumber( playerID )
    local new_lumber = current_lumber + lumber_value

    if lumber_value > 0 then
        Players:SetLumber( playerID, new_lumber )
    else
        if Players:HasEnoughLumber( playerID, math.abs(lumber_value) ) then
            Players:SetLumber( playerID, new_lumber )
        end
    end
end

-- Modifies the food limit of this player, accepts negative values
-- Can't go over the limit unless pointbreak cheat is enabled
function Players:ModifyFoodLimit( playerID, food_limit_value )
    local food_limit = Players:GetFoodLimit(playerID) + food_limit_value

    if food_limit > 100 and not GameRules.PointBreak then
        food_limit = 100
    end

    Players:SetFoodLimit(playerID, food_limit)
end

-- Modifies the food used of this player, accepts negative values
-- Can go over the limit if a build is destroyed while the unit is already spawned/training
function Players:ModifyFoodUsed( playerID, food_used_value )
    local food_used = Players:GetFoodUsed(playerID) + food_used_value

    Players:SetFoodUsed(playerID, food_used)
end

---------------------------------------------------------------

-- Returns bool
function Players:HasEnoughGold( playerID, gold_cost )
    local gold = Players:GetGold( playerID )

    if not gold_cost or gold >= gold_cost then 
        return true
    else
        SendErrorMessage(playerID, "#error_not_enough_gold")
        return false
    end
end


-- Returns bool
function Players:HasEnoughLumber( playerID, lumber_cost )
    local lumber = Players:GetLumber(playerID)

    if not lumber_cost or lumber >= lumber_cost then 
        return true 
    else
        SendErrorMessage(playerID, "#error_not_enough_lumber")
        return false
    end
end

-- Return bool
function Players:HasEnoughFood( playerID, food_cost )
    local food_used = Players:GetFoodUsed(playerID)
    local food_limit = Players:GetFoodLimit(playerID)

    return (food_used + food_cost <= food_limit)
end

function Players:EnoughForDoMyPower( playerID, ability )
    local gold_cost = ability:GetGoldCost(ability:GetLevel()) or 0
    local lumber_cost = ability:GetSpecialValueFor("lumber_cost") or 0
    local food_cost = ability:GetSpecialValueFor("food_cost") or 0

    local current_gold = Players:GetGold(playerID)
    local current_lumber = Players:GetLumber(playerID)
    local current_food = Players:GetFoodLimit(playerID) - Players:GetFoodUsed(playerID)

    local bCanAffordGoldCost = current_gold >= gold_cost
    local bCanAffordLumberCost = current_lumber >= lumber_cost
    local bCanAffordFoodCost = current_food >= food_cost

    return bCanAffordGoldCost and bCanAffordLumberCost and bCanAffordFoodCost
end

---------------------------------------------------------------

function Players:AddUnit( playerID, unit )
    local playerUnits = Players:GetUnits(playerID)

    table.insert(playerUnits, unit)
end

function Players:AddHero( playerID, hero )
    local playerHeroes = Players:GetHeroes(playerID)

    table.insert(playerHeroes, hero)
end

function Players:AddStructure( playerID, building )
    local playerStructures = Players:GetStructures(playerID)
    local buildingTable = Players:GetBuildingTable(playerID)

    local name = building:GetUnitName()
    buildingTable[name] = buildingTable[name] and (buildingTable[name] + 1) or 1

    table.insert(playerStructures, building)
end

---------------------------------------------------------------

function Players:RemoveUnit( playerID, unit )
    -- Attempt to remove from player units
    local playerUnits = Players:GetUnits(playerID)
    local unit_index = getIndexTable(playerUnits, unit)
    if unit_index then
        table.remove(playerUnits, unit_index)
    end
end

function Players:RemoveStructure( playerID, unit )
    local playerStructures = Players:GetStructures(playerID)
    local buildingTable = Players:GetBuildingTable(playerID)

    -- Substract 1 to the player building tracking table for that name
    local buildingTable = Players:GetBuildingTable( playerID )
    local unitName = unit:GetUnitName()
    if buildingTable[unitName] then
        buildingTable[unitName] = buildingTable[unitName] - 1
    end

    -- Remove the handle from the player structures
    local playerStructures = Players:GetStructures( playerID )
    local structure_index = getIndexTable(playerStructures, unit)
    if structure_index then 
        table.remove(playerStructures, structure_index)
    end

    if IsAltar(unit) then
        -- Remove from altar structures
        local playerAltars = Players:GetAltars( playerID )
        local altar_index = getIndexTable(playerStructures, unit)
        if altar_index then 
            table.remove(playerAltars, altar_index)
        end
    end
end

---------------------------------------------------------------

-- Returns bool
function Players:HasResearch( playerID, research_name )
    local upgrades = Players:GetUpgradeTable(playerID)
    return upgrades[research_name]
end

-- Returns bool
function Players:HasRequirementForAbility( playerID, ability_name )
    local requirements = GameRules.Requirements
    local buildings = Players:GetBuildingTable(playerID)
    local upgrades = Players:GetUpgradeTable(playerID)
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

function Players:HasAltar( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return IsValidAlive(hero.altar) and hero.altar or false
end

---------------------------------------------------------------

-- Return ability handle or nil
function Players:FindAbilityOnStructures( playerID, ability_name )
    local structures = Players:GetStructures(playerID)

    for _,building in pairs(structures) do
        local ability_found = building:FindAbilityByName(ability_name)
        if ability_found then
            return ability_found
        end
    end
    return nil
end

-- Return ability handle or nil
function Players:FindAbilityOnUnits( playerID, ability_name )
    local units = Players:GetUnits(playerID)

    for _,unit in pairs(units) do
        local ability_found = unit:FindAbilityByName(ability_name)
        if ability_found then
            return ability_found
        end
    end
    return nil
end


-- Returns int, 0 if the player doesnt have the research
function Players:GetCurrentResearchRank( playerID, research_name )
    local upgrades = Players:GetUpgradeTable(playerID)
    local max_rank = MaxResearchRank(research_name)

    local current_rank = 0
    if max_rank > 0 then
        for i=1,max_rank do
            local ability_len = string.len(research_name)
            local this_research = string.sub(research_name, 1 , ability_len - 1)..i
            if Players:HasResearch(playerID, this_research) then
                current_rank = i
            end
        end
    end

    return current_rank
end

-- Goes through the structures of the player, checking for the max level city center
-- If no city center is found, the player has a 2 minute window in which a city center must be built or all his structures will be revealed
function Players:CheckCurrentCityCenters( playerID )
    local structures = Players:GetStructures( playerID )
    local city_center_level = 0

    for k,building in pairs(structures) do
        if IsCityCenter(building) then
            local level = building:GetLevel()
            if level > city_center_level then
                city_center_level = level
            end
        end
    end
    Players:SetCityCenterLevel(playerID, city_center_level)

    print("Current City Center Level for player "..playerID.." is: "..city_center_level)

    if city_center_level == 0 then
        local time_to_reveal = 120
        print("Player "..player:GetPlayerID().." has no city centers left standing. Revealed in "..time_to_reveal.." seconds until a City Center is built.")
        structures.RevealTimer = Timers:CreateTimer(time_to_reveal, function()
            Players:RevealToAllEnemies( playerID )
        end)
    else
        Players:StopRevealing(playerID)
    end
end

-- Creates revealer entities on each building of the player
function Players:RevealToAllEnemies( playerID )
    local units = Players:GetUnits(playerID)
    local structures = Players:GetStructures(playerID)

    print("Revealing Player "..playerID)

    local playerName = Players:GetPlayerName(playerID)
    GameRules:SendCustomMessage("Revealing "..playerName, 0, 0)

    for k,building in pairs(structures) do
        local origin = building:GetAbsOrigin()
        local vision = buildling:GetDayTimeVisionRange()
        local ent = SpawnEntityFromTableSynchronous("ent_fow_revealer", {origin = origin, vision = vision, teamnumber = 0})
        building.revealer = ent
    end
end

function Players:StopRevealing( playerID )
    local structures = Players:GetStructures(playerID)

    print("Stop Revealing Player "..playerID)

    if structures.RevealTimer then
        Timers:RemoveTimer(structures.RevealTimer)
        structures.RevealTimer = nil
    end

    for k,building in pairs(structures) do
        if building.revealer then
            DoEntFireByInstanceHandle(building.revealer, "Kill", "1", 1, nil, nil)
            building.revealer = nil
        end
    end
end

-- Returns a string with the race of the player
function Players:GetRace( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
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

function Players:FindHighestLevelCityCenter( unit )
    local playerID = unit:GetPlayerOwnerID()
    local position = unit:GetAbsOrigin()
    local buildings = Players:GetStructures( playerID )
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

function Players:SetMainCityCenter( playerID, building )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    hero.main_city_center = building
end

-- Hero count is limited to 3
function Players:CanTrainMoreHeroes( playerID )
    return Players:HeroCount( playerID ) < 3
end

function Players:HeroCount( playerID )
    return #Players:GetHeroes(playerID)
end