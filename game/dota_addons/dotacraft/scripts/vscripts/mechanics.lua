-- Contains general mechanics used extensively thourought different scripts

-- Modifies the lumber of this player. Accepts negative values
function ModifyLumber( player, lumber_value )
	local pID = player:GetAssignedHero():GetPlayerID()
	
	if lumber_value > 0 then
		player.lumber = player.lumber + lumber_value
	    --print("Lumber Gained. Player " .. pID .. " is currently at " .. player.lumber)
	    FireGameEvent('cgm_player_lumber_changed', { player_ID = pID, lumber = player.lumber })
	else
		if PlayerHasEnoughLumber( player, math.abs(lumber_value) ) then
			player.lumber = player.lumber + lumber_value
		    --print("Lumber Spend. Player " .. pID .. " is currently at " .. player.lumber)
		    FireGameEvent('cgm_player_lumber_changed', { player_ID = pID, lumber = player.lumber })
		end
	end
end

-- Modifies the food limit of this player. Accepts negative values
function ModifyFoodLimit( player, food_limit_value )
	local pID = player:GetAssignedHero():GetPlayerID()

	player.food_limit = player.food_limit + food_limit_value
	if player.food_limit > 100 then
		player.food_limit = 100
	end
	print("Food Limit Changed. Player " .. pID .. " can use up to " .. player.food_limit)
	FireGameEvent('cgm_player_food_limit_changed', { player_ID = pID, food_used = player.food_used, food_limit = player.food_limit })	
end

-- Modifies the food used of this player. Accepts negative values
-- Can go over the limit if a build is destroyed while the unit is already spawned/training
function ModifyFoodUsed( player, food_used_value )
	local pID = player:GetAssignedHero():GetPlayerID()

	player.food_used = player.food_used + food_used_value
    print("Food Used Changed. Player " .. pID .. " is currently at " .. player.food_used)
    FireGameEvent('cgm_player_food_used_changed', { player_ID = pID, food_used = player.food_used, food_limit = player.food_limit })
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