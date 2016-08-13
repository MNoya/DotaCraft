if not Players then
    Players = class({})
end

function Players:Init( playerID, hero )

    -- Tables
    hero.units = {} -- This keeps the handle of all the units of the player army, to iterate for unlocking upgrades
    hero.structures = {} -- This keeps the handle of the constructed units, to iterate for unlocking upgrades
    hero.heroes = {} -- Owned hero units (not this assigned hero, which will be a fake)
    hero.altar_structures = {} -- Keeps altars linked
    hero.altar_queue = {}  -- Heroes queued

    hero.buildings = {} -- This keeps the name and quantity of each building
    hero.upgrades = {} -- This kees the name of all the upgrades researched, so each unit can check and upgrade itself on spawn

    hero.idle_builders = {} -- Keeps indexes of idle builders to send to the panorama UI
    hero.flags = {} -- Particle flags for each building currently selected
    
    -- Resource tracking
    hero.gold = 0
    hero.lumber = 0
    hero.food_limit = 0 -- The amount of food available to build units
    hero.food_used = 0 -- The amount of food used by this player creatures

    -- Other variables
    hero.city_center_level = 1
    hero.altar_level = 1
	Players:UpdateJavaScriptPlayer(playerID)

    if PlayerResource:IsFakeClient(playerID) then
        Scores:InitPlayer(playerID)
    end
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

    return hero.heroes or {}
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

-- For particles
function Players:GetPlayerFlags( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.flags
end

function Players:ClearPlayerFlags( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local flags = Players:GetPlayerFlags( playerID )
    local selected = PlayerResource:GetSelectedEntities(playerID)

    if not flags then return end
    
    for entIndex,particleTable in pairs(flags) do
        local flagParticle = particleTable.flagParticle
        local lineParticle = particleTable.lineParticle

        if flagParticle then
            ParticleManager:DestroyParticle(flagParticle, true)
            flags[entIndex].flagParticle = nil
        end

        if lineParticle then
            ParticleManager:DestroyParticle(lineParticle, true)
            flags[entIndex].lineParticle = nil
        end
    end
end

function Players:IsValidNetTablePlayer(playerTable)
	return ( playerTable ~= nil and not playerTable.isNull )
end

-- In case of objects being removed from the game but still kept on the player tables
function Players:FixAllTables(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    hero.units = Players:FixTable(Players:GetUnits(playerID))
    hero.structures = Players:FixTable(Players:GetStructures(playerID))
    hero.heroes = Players:FixTable(Players:GetHeroes(playerID))
    hero.altar_structures = Players:FixTable(Players:GetAltars(playerID))
end

function Players:FixTable(list)
    local newList = {}
    for _,v in pairs(list) do
        if IsValidEntity(v) and v:IsAlive() then
            table.insert(newList, v)
        end
    end
    return newList
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
end

function Players:SetFoodLimit( playerID, value )
    local player = PlayerResource:GetPlayer(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    
    hero.food_limit = value
    CustomGameEventManager:Send_ServerToPlayer(player, 'player_food_changed', { food_used = hero.food_used, food_limit = hero.food_limit }) 
end

function Players:SetFoodUsed( playerID, value )
    local player = PlayerResource:GetPlayer(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    hero.food_used = value
    CustomGameEventManager:Send_ServerToPlayer(player, 'player_food_changed', { food_used = hero.food_used, food_limit = hero.food_limit }) 
end

function Players:UpdateJavaScriptPlayer( playerID )
	Timers:CreateTimer("Player_".. playerID .."_Updater", {	useGameTime = true, endTime = 1, callback = function()
		if PlayerResource:IsValidPlayer(playerID) then
			local hero = PlayerResource:GetSelectedHeroEntity(playerID)	
	
			local Gold = PlayerResource:GetGold(playerID)
			local Lumber = math.floor(hero.lumber)
			local FoodUsed = hero.food_used
			local FoodLimit = hero.food_limit
	
			local HasAltar = Players:HasAltar(playerID)
			if HasAltar then HasAltar = true else HasAltar = false end
	
			local TechTier = Players:GetCityLevel(playerID)
			local HeroCount = 0
			local ColorID = hero.color_id
			-- WIP Noya herocounter
			CustomNetTables:SetTableValue("dotacraft_player_table", tostring(playerID), {color_id = ColorID, food_used = FoodUsed, food_limit = FoodLimit, lumber = Lumber, gold = Gold, tech_tier = TechTier, has_altar = HasAltar, hero_count = HeroCount})
		end
		
		return 1
	end})
	
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

    Scores:IncrementUnitsProduced(playerID, unit)
end

function Players:AddHero( playerID, hero )
    local playerHeroes = Players:GetHeroes(playerID)

    table.insert(playerHeroes, hero)

    Scores:AddHeroesUsed(playerID, hero:GetUnitName())
end

function Players:AddStructure( playerID, building )
    local playerStructures = Players:GetStructures(playerID)
    local buildingTable = Players:GetBuildingTable(playerID)

    local name = building:GetUnitName()
    buildingTable[name] = buildingTable[name] and (buildingTable[name] + 1) or 1

    table.insert(playerStructures, building)

    Scores:IncrementBuildingsProduced( playerID, building )
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
        local altar_index = getIndexTable(playerAltars, unit)
        if altar_index then 
            table.remove(playerAltars, altar_index)
        end
    end
end

function Players:UpgradeStructure(playerID, oldUnit, newUnit)
    local playerStructures = Players:GetStructures(playerID)
    local buildingTable = Players:GetBuildingTable(playerID)

    -- Remove the handle from the player structures
    local playerStructures = Players:GetStructures( playerID )
    local structure_index = getIndexTable(playerStructures, oldUnit)
    if structure_index then 
        table.remove(playerStructures, structure_index)
    end

    Players:AddStructure( playerID, newUnit )
end

---------------------------------------------------------------

function Players:SetResearchLevel(playerID, research_name, level)
    local upgradeTable = Players:GetUpgradeTable(playerID)
    level = (upgradeTable[research_name] and math.max(upgradeTable[research_name], level)) or level
    upgradeTable[research_name] = level
end

function Players:GetCurrentResearchRank(playerID, research_name)
    local upgradeTable = Players:GetUpgradeTable(playerID)
    return upgradeTable[research_name] or 0
end

-- Returns bool
function Players:HasResearch(playerID, research_name)
    return Players:GetCurrentResearchRank(playerID, research_name) > 0
end

-- Returns bool
function Players:HasRequirementForAbility(playerID, ability_name)
    local requirements = GameRules.Requirements
    local buildings = Players:GetBuildingTable(playerID)
    local upgrades = Players:GetUpgradeTable(playerID)

    -- Unlock all abilities cheat
    if GameRules.Synergy then
        return true
    end

    if requirements[ability_name] then

        -- Go through each requirement line and check if the player has that building on its list
        for k,v in pairs(requirements[ability_name]) do

            -- If it's an ability tied to a research, check the upgrades table
            if requirements[ability_name].research then
                if k ~= "research" and Players:GetCurrentResearchRank(playerID, k) < v then
                    --print("Failed the research requirements for "..ability_name..", no "..k.." "..v.." found")
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

function Players:GetResearchCountForPlayerRace(playerID)
    local race = Players:GetRace( playerID )
    local techCount = { human = 34, orc = 30, undead = 28, nightelf = 32 }
    return techCount[race]
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

-- Goes through the structures of the player, checking for the max level city center
-- If no city center is found, the player has a 2 minute window in which a city center must be built or all his structures will be revealed
function Players:CheckCurrentCityCenters( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
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
        print("Player "..playerID.." has no city centers left standing. Revealed in "..time_to_reveal.." seconds until a City Center is built.")
        hero.RevealTimer = Timers:CreateTimer(time_to_reveal, function()
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
        local vision = building:GetDayTimeVisionRange()
        local ent = SpawnEntityFromTableSynchronous("ent_fow_revealer", {origin = origin, vision = vision, teamnumber = 0})
        building.revealer = ent
    end
end

function Players:StopRevealing( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local structures = Players:GetStructures(playerID)

    print("Stop Revealing Player "..playerID)

    if hero.RevealTimer then
        Timers:RemoveTimer(hero.RevealTimer)
        hero.RevealTimer = nil
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
    return hero:GetRace()
end

function Players:FindHighestLevelCityCenter(unit)
    local playerID = unit:GetPlayerOwnerID()
    local position = unit:GetAbsOrigin()
    local buildings = Players:GetStructures(playerID)
    local level = 0 --Priority to the highest level city center
    local distance = math.huge
    local closest_building

    for _,building in pairs(buildings) do
        if IsValidAlive(building) and IsCityCenter(building) and not building:IsUnderConstruction() and building:GetLevel() > level then
            level = building:GetLevel()
            local this_distance = (position - building:GetAbsOrigin()):Length2D()
            if this_distance < distance then
                distance = this_distance
                closest_building = building
            end
        end
    end
    return closest_building
end

function Players:FindClosestCityCenter(playerID, position)
    local structures = Players:GetStructures(playerID)
    local distance = math.huge
    local closest_building

    for _,building in pairs(structures) do
        if IsValidAlive(building) and IsCityCenter(building) and not building:IsUnderConstruction() then
            local this_distance = (position - building:GetAbsOrigin()):Length2D()
            if this_distance < distance then
                distance = this_distance
                closest_building = building
            end
        end
    end
    return closest_building
end

-- FindClosestCityCenter for all team members and returns the best
function Players:FindClosestFriendlyCityCenter(playerID, position)
    local teamMembers = Teams:GetPlayersOnTeam(PlayerResource:GetTeam(playerID))
    local distance = math.huge
    local closest
    for _,pID in pairs(teamMembers) do
        local unit = self:FindClosestCityCenter(pID, position)
        local this_distance = (position - unit:GetAbsOrigin()):Length2D()
        if this_distance < distance then
            distance = this_distance
            closest = unit
        end
    end
    return closest
end

function Players:FindClosestUnit(playerID, position, filterFunction)
    local units = Players:GetUnits(playerID)
    local heroes = Players:GetHeroes(playerID)
    local structures = Players:GetStructures(playerID)
    local distance = math.huge
    local closest
    if not filterFunction then 
        filterFunction = function(...) return true end
    end

    for _,unit in pairs(units) do
        if IsValidAlive(unit) and filterFunction(unit) then
            local this_distance = (position - unit:GetAbsOrigin()):Length2D()
            if this_distance < distance then
                distance = this_distance
                closest = unit
            end
        end
    end

    for _,hero in pairs(heroes) do
        if IsValidAlive(hero) then
            local this_distance = (position - hero:GetAbsOrigin()):Length2D()
            if this_distance < distance then
                distance = this_distance
                closest = hero
            end
        end
    end

    for _,structures in pairs(structures) do
        if IsValidAlive(structures) then
            local this_distance = (position - structures:GetAbsOrigin()):Length2D()
            if this_distance < distance then
                distance = this_distance
                closest = structures
            end
        end
    end
    return closest
end

-- FindClosestUnit for all team members and returns the best
function Players:FindClosestFriendlyUnit(playerID, position, filterFunction)
    local teamMembers = Teams:GetPlayersOnTeam(PlayerResource:GetTeam(playerID))
    local distance = math.huge
    local closest
    for _,pID in pairs(teamMembers) do
        local unit = self:FindClosestUnit(pID, position, filterFunction)
        local this_distance = (position - unit:GetAbsOrigin()):Length2D()
        if this_distance < distance then
            distance = this_distance
            closest = unit
        end
    end
    return closest
end

function Players:SetMainCityCenter(playerID, building)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    PlayerResource:SetDefaultSelectionEntity(playerID, building)

    hero.main_city_center = building
end

function Players:GetAltarLevel( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    return hero.altar_level or 0
end

function Players:CanTrainMoreHeroes( playerID )
    local altar_level = Players:GetAltarLevel(playerID)
    return altar_level <= 3
end

function Players:HeroCount( playerID )
    return #Players:GetHeroes(playerID)
end

---------------------------------------------------------------

-- defined in races.kv, loaded on Units
function Players:GetBaseHeroName(playerID)
    return Units:GetBaseHeroNameForRace(Players:GetRace(playerID))
end
function Players:GetCityCenterName(playerID)
    return Units:GetCityCenterNameForRace(Players:GetRace(playerID))
end

function Players:GetBuilderName(playerID)
    return Units:GetBuilderNameForRace(Players:GetRace(playerID))
end

function Players:GetNumInitialBuilders(playerID)
    return Units:GetNumInitialBuildersForRace(Players:GetRace(playerID))
end

---------------------------------------------------------------
