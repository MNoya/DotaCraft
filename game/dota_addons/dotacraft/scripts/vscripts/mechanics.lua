-- Contains general mechanics used extensively thourought different scripts

-- Modifies the lumber of this player. Accepts negative values
function ModifyLumber( player, lumber_value )
	if lumber_value == 0 then return end
	if lumber_value > 0 then
		player.lumber = player.lumber + lumber_value
	    CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = player.lumber })
	else
		if PlayerHasEnoughLumber( player, math.abs(lumber_value) ) then
			player.lumber = player.lumber + lumber_value
		    CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = player.lumber })
		end
	end
end

-- Modifies the food limit of this player. Accepts negative values
function ModifyFoodLimit( player, food_limit_value )
	player.food_limit = player.food_limit + food_limit_value
	if player.food_limit > 100 then
		player.food_limit = 100
	end
	CustomGameEventManager:Send_ServerToPlayer(player, 'player_food_changed', { food_used = player.food_used, food_limit = player.food_limit })	
end

-- Modifies the food used of this player. Accepts negative values
-- Can go over the limit if a build is destroyed while the unit is already spawned/training
function ModifyFoodUsed( player, food_used_value )
	player.food_used = player.food_used + food_used_value
    CustomGameEventManager:Send_ServerToPlayer(player, 'player_food_changed', { food_used = player.food_used, food_limit = player.food_limit })
end

-- Returns Int
function GetFoodProduced( unit )
	if unit and IsValidEntity(unit) then
		if GameRules.UnitKV[unit:GetUnitName()] and GameRules.UnitKV[unit:GetUnitName()].FoodProduced then
			return GameRules.UnitKV[unit:GetUnitName()].FoodProduced
		end
	end
	return 0
end

-- Returns Int
function GetFoodCost( unit )
	if unit and IsValidEntity(unit) then
		if GameRules.UnitKV[unit:GetUnitName()] and GameRules.UnitKV[unit:GetUnitName()].FoodCost then
			return GameRules.UnitKV[unit:GetUnitName()].FoodCost
		end
	end
	return 0
end

-- Returns Int
function GetGoldCost( unit )
	if unit and IsValidEntity(unit) then
		if GameRules.UnitKV[unit:GetUnitName()] and GameRules.UnitKV[unit:GetUnitName()].GoldCost then
			return GameRules.UnitKV[unit:GetUnitName()].GoldCost
		end
	end
	return 0
end

-- Returns Int
function GetLumberCost( unit )
	if unit and IsValidEntity(unit) then
		if GameRules.UnitKV[unit:GetUnitName()] and GameRules.UnitKV[unit:GetUnitName()].LumberCost then
			return GameRules.UnitKV[unit:GetUnitName()].LumberCost
		end
	end
	return 0
end

function GetBuildTime( unit )
	if unit and IsValidEntity(unit) then
		if GameRules.UnitKV[unit:GetUnitName()] and GameRules.UnitKV[unit:GetUnitName()].BuildTime then
			return GameRules.UnitKV[unit:GetUnitName()].BuildTime
		end
	end
	return 0
end

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

	if gold < gold_cost then
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Need more Gold" } )		
		return false
	else
		return true
	end
end


-- Returns bool
function PlayerHasEnoughLumber( player, lumber_cost )
	local pID = player:GetAssignedHero():GetPlayerID()

	if player.lumber < lumber_cost then
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Need more Lumber" } )		
		return false
	else
		return true
	end
end

-- Return bool
function PlayerHasEnoughFood( player, food_cost )
	local pID = player:GetAssignedHero():GetPlayerID()

	if player.food_used + food_cost > player.food_limit then
		-- send the warning only once every time
		if not player.need_more_farms then
			FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Need more Farms" } )
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

-- Returns int, 0 if it doesnt exist
function MaxResearchRank( research_name )
	local unit_upgrades = GameRules.UnitUpgrades
	local upgrade_name = GetResearchAbilityName( research_name )

	if unit_upgrades[upgrade_name] and unit_upgrades[upgrade_name].max_rank then
		return tonumber(unit_upgrades[upgrade_name].max_rank)
	else
		return 0
	end
end

-- Returns string with the "short" ability name, without any rank or suffix
function GetResearchAbilityName( research_name )

	local ability_name = string.gsub(research_name, "_research" , "")
	ability_name = string.gsub(ability_name, "_disabled" , "")
	ability_name = string.gsub(ability_name, "1" , "")
	ability_name = string.gsub(ability_name, "2" , "")
	ability_name = string.gsub(ability_name, "3" , "")

	return ability_name
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

function IsBuilder( unit )
	local unitName = unit:GetUnitName()
	if unitName == "human_peasant" or unitName == "nightelf_wisp" or unitName == "undead_acolyte" or unitName == "orc_peon" then
		return true
	else
		return false
	end
end

function IsBase( unit )
	local race = GetUnitRace(unit)
	local unitName = unit:GetUnitName()
	if race == "human" then
		if unitName == "human_town_hall" or unitName == "human_keep" or unitName == "human_castle" then
			return true
		end
	elseif race == "nightelf" then
		if unitName == "nightelf_tree_of_life" or unitName == "nightelf_tree_of_ages" or unitName == "nightelf_tree_of_eternity" then
			return true
		end
	elseif race == "orc" then
		if unitName == "orc_great_hall" or unitName == "orc_stronghold" or unitName == "orc_fortress" then
			return true
		end
	elseif race == "undead" then
		if unitName == "undead_necropolis" or unitName == "undead_halls_of_the_dead" or unitName == "undead_black_citadel" then
			return true
		end
	end
	return false
end


-- Custom Corpse Mechanic
function LeavesCorpse( unit )
	
	-- Heroes don't leave corpses (includes illusions)
	if unit:IsHero() then
		return false

	-- Ignore buildings	
	elseif unit.GetInvulnCount ~= nil then
		return false

	-- Ignore custom buildings
	elseif unit:FindAbilityByName("ability_building") then
		return false

	-- Ignore units that start with dummy keyword	
	elseif string.find(unit:GetUnitName(), "dummy") then
		return false

	-- Ignore units that were specifically set to leave no corpse
	elseif unit.no_corpse then
		return false

	-- Leave corpse
	else
		print("Leave corpse")
		return true
	end
end

function SetNoCorpse( event )
	event.target.no_corpse = true
end

function PrintAbilities( unit )
	print("List of Abilities in "..unit:GetUnitName())
	for i=0,15 do
		local ability = unit:GetAbilityByIndex(i)
		if ability then print(i.." - "..ability:GetAbilityName()) end
	end
	print("---------------------")
end

function GenerateAbilityString(player, ability_table)
	local abilities_string = ""
	local index = 1
	while ability_table[tostring(index)] do
		local ability_name = ability_table[tostring(index)]
		local ability_available = false
		if FindAbilityOnStructures(player, ability_name) or FindAbilityOnUnits(player, ability_name) then
			ability_available = true
		end
		index = index + 1
		if ability_available then
			print(index,ability_name,ability_available)
			abilities_string = abilities_string.."1,"
		else
			abilities_string = abilities_string.."0,"
		end
	end
	return abilities_string
end

function GetUnitRace( unit )
	local name = unit:GetUnitName()
	local name_split = split(name, "_")
	return name_split[1]
end

function IsCustomBuilding( unit )
    local ability_building = unit:FindAbilityByName("ability_building")
    local ability_tower = unit:FindAbilityByName("ability_tower")
    if ability_building or ability_tower then
        return true
    else
        return false
    end
end

function IsCustomTower( unit )
    local ability_tower = unit:FindAbilityByName("ability_tower")
    if ability_tower then
        return true
    else
        return false
    end
end

function AddUnitToSelection( unit )
	--local player = unit:GetPlayerOwner()
	local player = PlayerResource:GetPlayer(0)
	CustomGameEventManager:Send_ServerToPlayer(player, "add_to_selection", { ent_index = unit:GetEntityIndex() })
end

-- A tree is "empty" if it doesn't have a stored .builder in it
function FindEmptyNavigableTreeNearby( unit, position, radius )
	local nearby_trees = GridNav:GetAllTreesAroundPoint(position, radius, true)
	local origin = unit:GetAbsOrigin()
	--DebugDrawLine(origin, position, 255, 255, 255, true, 10)

	-- Sort by Closest
	local sorted_list = SortListByClosest(nearby_trees, position)

 	for _,tree in pairs(sorted_list) do
 		local tree_point = tree:GetAbsOrigin()
		if (not tree.builder or tree.builder == unit ) and IsTreePositionPathAble(origin, tree_point) then
			--DebugDrawCircle(tree:GetAbsOrigin(), Vector(0,255,0), 100, 100, true, 10)
			return tree
		end
	end

	--DebugDrawCircle(position, Vector(255,0,0), radius*2, 100, true, 10)
	print("NO EMPTY NAVIGABLE TREE NEARBY")
	return nil
end

function SortListByClosest( list, position )
    local trees = {}
    for _,v in pairs(list) do
        trees[#trees+1] = v
    end

    local sorted_list = {}
    for _,tree in pairs(list) do
        local closest_tree = GetClosestEntityToPosition(trees, position)
        sorted_list[#sorted_list+1] = trees[closest_tree]
        trees[closest_tree] = nil -- Remove it
    end
    return sorted_list
end

function GetClosestEntityToPosition(list, position)
	local distance = 20000
	local closest = nil

	for k,ent in pairs(list) do
		local this_distance = (position - ent:GetAbsOrigin()):Length()
		if this_distance < distance then
			distance = this_distance
			closest = k
		end
	end

	return closest	
end


function IsTreePositionPathAble( origin, position )
	local found_path = false
	local positions = {}
	local pos1 = Vector(position.x + 100, position.y, position. z)
	local pos2 = Vector(position.x - 100, position.y, position. z)
	local pos3 = Vector(position.x, position.y + 100, position. z)
	local pos4 = Vector(position.x, position.y - 100, position. z)
	table.insert(positions, pos1)
	table.insert(positions, pos2)
	table.insert(positions, pos3)
	table.insert(positions, pos4)

	for k,vector in pairs(positions) do
		if GridNav:CanFindPath(origin, vector) then
			--DebugDrawCircle(vector, Vector(0, 255, 0), 100, 20, true, 5)
			found_path = true
			break
		else
			--DebugDrawCircle(vector, Vector(255, 0,0), 100, 20, true, 5)
		end
	end

	--print("IsTreePositionPathAble",found_path)
	return found_path
	
end

function GetClosestGoldMineToPosition( position )
	local allGoldMines = Entities:FindAllByModel('models/mine/mine.vmdl') --Target name in Hammer
	local distance = 20000
	local closest_mine = nil
	for k,gold_mine in pairs (allGoldMines) do
		local mine_location = gold_mine:GetAbsOrigin()
		local this_distance = (position - mine_location):Length()
		if this_distance < distance then
			distance = this_distance
			closest_mine = gold_mine
		end
	end
	return closest_mine
end

function HasTrainAbility( unit )
	for i=0,15 do
		local ability = unit:GetAbilityByIndex(i)
		if ability then
			local ability_name = ability:GetAbilityName()
			if string.match(ability_name, "_train_") then
				return true
			end
		end
	end
	return false
end