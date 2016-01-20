if not Scores then
    Scores = class({})
end

function Scores:Init()
    Scores.data = {}
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            Scores.data[playerID] = {}
            
            Scores.data[playerID].unit_score = 0
            Scores.data[playerID].hero_score = 0
            Scores.data[playerID].resource_score = 0
            Scores.data[playerID].total_score = 0
            Scores.data[playerID].units_produced = 0
            Scores.data[playerID].units_killed = 0
            Scores.data[playerID].buildings_produced = 0
            Scores.data[playerID].buildings_razed = 0
            Scores.data[playerID].largest_army = 0
            Scores.data[playerID].heroes_used = {}
            Scores.data[playerID].heroes_killed = 0
            Scores.data[playerID].items_obtained = 0
            Scores.data[playerID].mercenaries_hired = 0
            Scores.data[playerID].experienced_gained = 0
            Scores.data[playerID].gold_mined = 0
            Scores.data[playerID].lumber_harvested = 0
            Scores.data[playerID].resource_traded = 0
            Scores.data[playerID].tech_percentage = 0
            Scores.data[playerID].gold_lost_to_upkeep = 0
        end
    end
end

---------------------------------------------------------------
--                          TOTAL

function Scores:IncrementUnitScore( playerID, unit )
    local combined_resource_cost = GetGoldCost(unit) + GetLumberCost(unit)
    Scores.data[playerID].unit_score = Scores.data[playerID].unit_score + combined_resource_cost
    Scores:IncrementTotalScore( playerID, combined_resource_cost )
end

function Scores:IncrementHeroScore( playerID, value )
    Scores.data[playerID].hero_score = Scores.data[playerID].hero_score + value
    Scores:IncrementTotalScore( playerID, value )
end

function Scores:IncrementResourceScore( playerID, value )
    Scores.data[playerID].hero_score = Scores.data[playerID].hero_score + value
    Scores:IncrementTotalScore( playerID, value )
end

function Scores:IncrementTotalScore( playerID, value )
    Scores.data[playerID].total_score = Scores.data[playerID].total_score + value
end

---------------------------------------------------------------
--                          UNITS

function Scores:IncrementUnitsProduced( playerID, unit )
    Scores.data[playerID].units_produced = Scores.data[playerID].units_produced + 1
    Scores:CheckUpdateLargestArmy( playerID )
    Scores:IncrementUnitScore(playerID, unit)
end

function Scores:IncrementUnitsKilled( playerID, unit )
    Scores.data[playerID].units_killed = Scores.data[playerID].units_killed + 1
    Scores:IncrementUnitScore(playerID, unit)
end

function Scores:IncrementBuildingsProduced( playerID, unit )
    Scores.data[playerID].buildings_produced = Scores.data[playerID].buildings_produced + 1
    Scores:IncrementUnitScore(playerID, unit)
end

function Scores:IncrementBuildingsRazed( playerID, unit )
    Scores.data[playerID].buildings_razed = Scores.data[playerID].buildings_razed + 1
    Scores:IncrementUnitScore(playerID, unit)
end

function Scores:CheckUpdateLargestArmy( playerID )
    local current_army_size = #Players:GetUnits(playerID)
    local current_max = Players:GetLargestArmy(playerID)
    if current_army_size > current_max then
        Scores.data[playerID].largest_army = current_army_size
    end
end

---------------------------------------------------------------
--                          HEROES

function Scores:AddHeroesUsed( playerID, heroName )
    table.insert(Scores.data[playerID].heroes_used, heroName)
end

function Scores:IncrementHeroesKilled( playerID )
    Scores.data[playerID].heroes_killed = Scores.data[playerID].heroes_killed + 1
    Scores:IncrementHeroScore( playerID, 100 )
end

function Scores:IncrementItemsObtained( playerID )
    Scores.data[playerID].items_obtained = Scores.data[playerID].items_obtained + 1
end

function Scores:IncrementMercenariesHired( playerID )
    Scores.data[playerID].mercenaries_hired = Scores.data[playerID].mercenaries_hired + 1
end

function Scores:IncrementXPGained( playerID, value )
    Scores.data[playerID].experienced_gained = Scores.data[playerID].experienced_gained + value
    Scores:IncrementHeroScore( playerID, 10 )
end

---------------------------------------------------------------
--                        RESOURCES

function Scores:IncrementGoldMined( playerID, value )
    Scores.data[playerID].gold_mined = Scores.data[playerID].gold_mined + value
    Scores:IncrementResourceScore( playerID, value )
end

function Scores:IncrementLumberHarvested( playerID, value )
    Scores.data[playerID].lumber_harvested = Scores.data[playerID].lumber_harvested + value
    Scores:IncrementResourceScore( playerID, value )
end

function Scores:IncrementResourcesTraded( playerID, value )
    Scores.data[playerID].resource_traded = Scores.data[playerID].resource_traded + value
    Scores:IncrementResourceScore( playerID, value )
end

function Scores:IncrementTechPercentage( playerID )
    local maxResearch = Players:GetResearchCountForPlayerRace(playerID)
    local increment = 100/maxResearch
    Scores.data[playerID].tech_percentage = Scores.data[playerID].tech_percentage + increment
end

function Scores:AddGoldLostToUpkeep( playerID, value )
    Scores.data[playerID].gold_lost_to_upkeep = Scores.data[playerID].gold_lost_to_upkeep + value
end

---------------------------------------------------------------

function Players:GetPlayerScores( playerID )
    local scores = {}
    scores.unit_score = Players:GetUnitScore(playerID)
    scores.hero_score = Players:GetHeroScore(playerID)
    scores.resource_score = Players:GetResourceScore(playerID)
    scores.total_score = Players:GetTotalScore(playerID)

    scores.units_produced = Players:GetUnitsProduced(playerID)
    scores.units_killed = Players:GetUnitsKilled(playerID)
    scores.buildings_produced = Players:GetBuildingsProduced(playerID)
    scores.buildings_razed = Players:GetBuildingsRazed(playerID)
    scores.largest_army = Players:GetLargestArmy(playerID)

    scores.heroes_used = Players:GetListHeroesUsed(playerID)
    scores.heroes_killed = Players:GetHeroesKilled(playerID)
    scores.items_obtained = Players:GetItemsObtained(playerID)
    scores.mercenaries_hired = Players:GetMercenariesHired(playerID)
    scores.experienced_gained = Players:GetExperienceGained(playerID)

    scores.gold_mined = Players:GetGoldMined(playerID)
    scores.lumber_harvested = Players:GetLumberHarvested(playerID)
    scores.resource_traded = Players:GetResourceTraded(playerID)
    scores.tech_percentage = Players:GetTechPercentage(playerID)
    scores.gold_lost_to_upkeep = Players:GetGoldLostToUpkeep(playerID)

    return scores
end

function Players:GetUnitScore( playerID )
    return Scores.data[playerID].unit_score
end

function Players:GetHeroScore( playerID )
    return Scores.data[playerID].hero_score
end

function Players:GetResourceScore( playerID )
    return Scores.data[playerID].resource_score
end

function Players:GetTotalScore( playerID )
    return Scores.data[playerID].total_score
end

function Players:GetUnitsProduced( playerID )
    return Scores.data[playerID].units_produced
end

function Players:GetUnitsKilled( playerID )
    return Scores.data[playerID].units_killed
end

function Players:GetBuildingsProduced( playerID )
    return Scores.data[playerID].buildings_produced
end

function Players:GetBuildingsRazed( playerID )
    return Scores.data[playerID].buildings_razed
end

function Players:GetLargestArmy( playerID )
    return Scores.data[playerID].largest_army
end

function Players:GetListHeroesUsed( playerID )
    return Scores.data[playerID].heroes_used
end

function Players:GetHeroesKilled( playerID )
    return Scores.data[playerID].heroes_killed
end

function Players:GetItemsObtained( playerID )
    return Scores.data[playerID].items_obtained
end

function Players:GetMercenariesHired( playerID )
    return Scores.data[playerID].mercenaries_hired
end

function Players:GetExperienceGained( playerID )
    return Scores.data[playerID].experienced_gained
end

function Players:GetGoldMined( playerID )
    return Scores.data[playerID].gold_mined
end

function Players:GetLumberHarvested( playerID )
    return Scores.data[playerID].lumber_harvested
end
    
function Players:GetResourceTraded( playerID )
    return Scores.data[playerID].resource_traded
end 

function Players:GetTechPercentage( playerID )
    return math.floor(Scores.data[playerID].tech_percentage)
end

function Players:GetGoldLostToUpkeep( playerID )
    return Scores.data[playerID].gold_lost_to_upkeep
end