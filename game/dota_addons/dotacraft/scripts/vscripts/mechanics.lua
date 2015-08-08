-- Contains general mechanics used extensively thourought different scripts

function SendErrorMessage( pID, string )
	Notifications:ClearBottom(pID)
	Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
	EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end

-- Modifies the lumber of this player. Accepts negative values
function ModifyLumber( player, lumber_value )
	if lumber_value == 0 then return end
	if lumber_value > 0 then
		player.lumber = player.lumber + lumber_value
	    CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = math.floor(player.lumber) })
	else
		if PlayerHasEnoughLumber( player, math.abs(lumber_value) ) then
			player.lumber = player.lumber + lumber_value
		    CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = math.floor(player.lumber) })
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
		elseif GameRules.HeroKV[unit:GetUnitName()] and GameRules.HeroKV[unit:GetUnitName()].FoodCost then
			return GameRules.HeroKV[unit:GetUnitName()].FoodCost
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

-- Returns float
function GetBuildTime( unit )
	if unit and IsValidEntity(unit) then
		if GameRules.UnitKV[unit:GetUnitName()] and GameRules.UnitKV[unit:GetUnitName()].BuildTime then
			return GameRules.UnitKV[unit:GetUnitName()].BuildTime
		end
	end
	return 0
end

ATTACK_TYPES = {
	["DOTA_COMBAT_CLASS_ATTACK_BASIC"] = "normal",
	["DOTA_COMBAT_CLASS_ATTACK_PIERCE"] = "pierce",
	["DOTA_COMBAT_CLASS_ATTACK_SIEGE"] = "siege",
	["DOTA_COMBAT_CLASS_ATTACK_LIGHT"] = "chaos",
	["DOTA_COMBAT_CLASS_ATTACK_HERO"] = "hero",
	["DOTA_COMBAT_CLASS_ATTACK_MAGIC"] = "magic",
}

ARMOR_TYPES = {
	["DOTA_COMBAT_CLASS_DEFEND_SOFT"] = "unarmored",
	["DOTA_COMBAT_CLASS_DEFEND_WEAK"] = "light",
	["DOTA_COMBAT_CLASS_DEFEND_BASIC"] = "medium",
	["DOTA_COMBAT_CLASS_DEFEND_STRONG"] = "heavy",
	["DOTA_COMBAT_CLASS_DEFEND_STRUCTURE"] = "fortified",
	["DOTA_COMBAT_CLASS_DEFEND_HERO"] = "hero",
}

-- Returns a string with the wc3 damage name
function GetAttackType( unit )
	if unit and IsValidEntity(unit) then
		local unitName = unit:GetUnitName()
		if GameRules.UnitKV[unitName] and GameRules.UnitKV[unitName].CombatClassAttack then
			local attack_string = GameRules.UnitKV[unitName].CombatClassAttack
			return ATTACK_TYPES[attack_string]
		elseif unit:IsHero() then
			return "hero"
		end
	end
	return 0
end

-- Returns a string with the wc3 armor name
function GetArmorType( unit )
	if unit and IsValidEntity(unit) then
		local unitName = unit:GetUnitName()
		if GameRules.UnitKV[unitName] and GameRules.UnitKV[unitName].CombatClassDefend then
			local armor_string = GameRules.UnitKV[unitName].CombatClassDefend
			return ARMOR_TYPES[armor_string]
		elseif unit:IsHero() then
			return "hero"
		end
	end
	return 0
end

-- Changes the Attack Type string defined in the KV, and the current visual tooltip
-- attack_type can be normal/pierce/siege/chaos/magic/hero
function SetAttackType( unit, attack_type )
	local unitName = unit:GetUnitName()
	if GameRules.UnitKV[unitName].CombatClassAttack then
		local current_attack_type = GetAttackType(unit)
		unit:RemoveModifierByName("modifier_attack_"..current_attack_type)

		local attack_key = getIndexTable(ATTACK_TYPES, attack_type)
		GameRules.UnitKV[unitName].CombatClassAttack = attack_key		

		ApplyModifier(unit, "modifier_attack_"..attack_type)
	end
end

-- Changes the Armor Type string defined in the KV, and the current visual tooltip
-- attack_type can be unarmored/light/medium/heavy/fortified/hero
function SetArmorType( unit, armor_type )
	local unitName = unit:GetUnitName()
	if GameRules.UnitKV[unitName].CombatClassDefend then
		local current_armor_type = GetArmorType(unit)
		unit:RemoveModifierByName("modifier_armor_"..current_armor_type)

		local armor_key = getIndexTable(ATTACK_TYPES, armor_type)
		GameRules.UnitKV[unitName].CombatClassDefend = armor_key

		ApplyModifier(unit, "modifier_armor_"..armor_type)
	end
end

function GetDamageForAttackAndArmor( attack_type, armor_type )
--[[
http://classic.battle.net/war3/basics/armorandweapontypes.shtml
        Unarm   Light   Medium  Heavy   Fort   Hero   
Normal  100%    100%    150%    100%    70%    100%   
Pierce  150%    200%    75%     100%    35%    50%    
Siege   150%    100%    50%     100%    150%   50%      
Chaos   100%    100%    100%    100%    100%   100%     
Hero    100%    100%    100%    100%    50%    100%

-- Custom Attack Types
Magic   100%    125%    75%     200%    35%    50%
Spells  100%    100%    100%    100%    100%   70%  
]]
	if attack_type == "normal" then
		if armor_type == "unarmored" then
			return 1
		elseif armor_type == "light" then
			return 1
		elseif armor_type == "medium" then
			return 1.5
		elseif armor_type == "heavy" then
			return 1 --1.25 in dota
		elseif armor_type == "fortified" then
			return 0.7
		elseif armor_type == "hero" then
			return 1 --0.75 in dota
		end

	elseif attack_type == "pierce" then
		if armor_type == "unarmored" then
			return 1.5
		elseif armor_type == "light" then
			return 2
		elseif armor_type == "medium" then
			return 0.75
		elseif armor_type == "heavy" then
			return 1 --0.75 in dota
		elseif armor_type == "fortified" then
			return 0.35
		elseif armor_type == "hero" then
			return 0.5
		end

	elseif attack_type == "siege" then
		if armor_type == "unarmored" then
			return 1.5 --1 in dota
		elseif armor_type == "light" then
			return 1
		elseif armor_type == "medium" then
			return 0.5
		elseif armor_type == "heavy" then
			return 1 --1.25 in dota
		elseif armor_type == "fortified" then
			return 1.5
		elseif armor_type == "hero" then
			return 0.5 --0.75 in dota
		end

	elseif attack_type == "chaos" then
		if armor_type == "unarmored" then
			return 1
		elseif armor_type == "light" then
			return 1
		elseif armor_type == "medium" then
			return 1
		elseif armor_type == "heavy" then
			return 1
		elseif armor_type == "fortified" then
			return 1 --0.4 in Dota
		elseif armor_type == "hero" then
			return 1
		end

	elseif attack_type == "hero" then
		if armor_type == "unarmored" then
			return 1
		elseif armor_type == "light" then
			return 1
		elseif armor_type == "medium" then
			return 1
		elseif armor_type == "heavy" then
			return 1
		elseif armor_type == "fortified" then
			return 0.5
		elseif armor_type == "hero" then
			return 1
		end

	elseif attack_type == "magic" then
		if armor_type == "unarmored" then
			return 1
		elseif armor_type == "light" then
			return 1.25
		elseif armor_type == "medium" then
			return 0.75
		elseif armor_type == "heavy" then
			return 2
		elseif armor_type == "fortified" then
			return 0.35
		elseif armor_type == "hero" then
			return 0.5
		end
	end
	return 1
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
		SendErrorMessage(pID, "#error_not_enough_gold")
		return false
	else
		return true
	end
end


-- Returns bool
function PlayerHasEnoughLumber( player, lumber_cost )
	local pID = player:GetAssignedHero():GetPlayerID()

	if player.lumber < lumber_cost then
		SendErrorMessage(pID, "#error_not_enough_lumber")
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
	ability_name = string.gsub(ability_name, "0" , "")
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
	if not IsValidEntity(unit) then
		return
	end
	local unitName = unit:GetUnitName()
	if unitName == "human_peasant" or unitName == "nightelf_wisp" or unitName == "undead_acolyte" or unitName == "orc_peon" then
		return true
	else
		return false
	end
end

-- Returns true if the unit is a valid lumberjack
function CanGatherLumber( unit )
	local unitName = unit:GetUnitName()
	if unitName == "human_peasant" or unitName == "nightelf_wisp" or unitName == "undead_ghoul" or unitName == "orc_peon" then
		return true
	else
		return false
	end
end

-- Returns true if the unit is a gold miner
function CanGatherGold( unit )
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
	
	if not unit or not IsValidEntity(unit) then
		return false

	-- Heroes don't leave corpses (includes illusions)
	elseif unit:IsHero() then
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

-- Returns a string with the race of the unit
function GetUnitRace( unit )
	local name = unit:GetUnitName()
	local name_split = split(name, "_")
	return name_split[1]
end

function IsHuman( unit )
	return GetUnitRace(unit)=="human"
end

function IsOrc( unit )
	return GetUnitRace(unit)=="orc"
end

function IsNightElf( unit )
	return GetUnitRace(unit)=="nightelf"
end

function IsUndead( unit )
	return GetUnitRace(unit)=="undead"
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

function IsMechanical( unit )
	local unit_name = unit:GetUnitName()
	if GameRules.UnitKV[unit_name] then
		local bMechanical = GameRules.UnitKV[unit_name]["IsMechanical"]
		if bMechanical and bMechanical == "1" then
			return true
		end
	end
	return false
end

function HasGoldMineDistanceRestriction( unit_name )
	if GameRules.UnitKV[unit_name] then
		local bRestrictGoldMineDistance = GameRules.UnitKV[unit_name]["RestrictGoldMineDistance"]
		if bRestrictGoldMineDistance and bRestrictGoldMineDistance == 1 then
			return true
		end
	end
	return false
end

-- Shortcut for a very common check
function IsValidAlive( unit )
	return (IsValidEntity(unit) and unit:IsAlive())
end

-- Returns all visible enemies in radius of the unit
function FindEnemiesInRadius( unit, radius )
	local team = unit:GetTeamNumber()
	local position = unit:GetAbsOrigin()
	local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
	local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
	return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_CLOSEST, false)
end

-- Returns all units (friendly and enemy) in radius of the unit
function FindAllUnitsInRadius( unit, radius )
	local team = unit:GetTeamNumber()
	local position = unit:GetAbsOrigin()
	local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
	local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, target_type, flags, FIND_ANY_ORDER, false)
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

	local pathable_trees = GetAllPathableTreesFromList(nearby_trees)
	if #pathable_trees == 0 then
		print("FindEmptyNavigableTreeNearby Can't find a pathable tree with radius ",radius," for this position")
		return nil
	end

	-- Sort by Closest
	local sorted_list = SortListByClosest(pathable_trees, position)

 	for _,tree in pairs(sorted_list) do
		if (not tree.builder or tree.builder == unit ) and IsTreePathable(tree) then
			--DebugDrawCircle(tree:GetAbsOrigin(), Vector(0,255,0), 100, 32, true, 10)
			return tree
		end
	end

	--print("NO EMPTY NAVIGABLE TREE NEARBY")
	return nil
end

function GetAllPathableTreesFromList( list )
	local pathable_trees = {}
	for _,tree in pairs(list) do
		if IsTreePathable(tree) then
			table.insert(pathable_trees, tree)
		end
	end
	return pathable_trees
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

-- Returns if the builder is fully idle (not reparing or in a gathering process)
function IsIdleBuilder( unit )
	return (unit.state == "idle" and unit:IsIdle())
end

-- This is defined on dotacraft:DeterminePathableTrees() and updated on tree_cut
function IsTreePathable( tree )
	return tree.pathable
end

-- Takes a CDOTA_Buff handle and checks the Ability KV table for the IsPurgable key
function IsPurgableModifier( modifier_handle )
	local ability = modifier_handle:GetAbility()
	local modifier_name = modifier_handle:GetName()

	if ability and IsValidEntity(ability) then
		local ability_name = ability:GetAbilityName()
		local ability_table = GameRules.AbilityKV[ability_name]

		-- Check for item ability
		if not ability_table then
			--print(modifier_name.." might be an item")
			ability_table = GameRules.ItemKV[ability_name]
		end

		-- Proceed only if the ability is really found
		if ability_table then
			local modifier_table = ability_table["Modifiers"][modifier_name]
			if modifier_table then
				local IsPurgable = modifier_table["IsPurgable"]
				if IsPurgable and IsPurgable == 1 then
					--print(modifier_name.." from "..ability_name.." is purgable!")
					return true
				end
			else
				--print("Couldn't find modifier table for "..modifier_name)
			end
		end
	end

	return false
end

-- If it has the "IsDebuff" "1" key specified then it's a debuff, otherwise take it as a buff
function IsDebuff( modifier_handle )
	local ability = modifier_handle:GetAbility()
	local modifier_name = modifier_handle:GetName()

	if ability and IsValidEntity(ability) then
		local ability_name = ability:GetAbilityName()
		local ability_table = GameRules.AbilityKV[ability_name]

		-- Check for item ability
		if not ability_table then
			ability_table = GameRules.ItemKV[ability_name]
		end

		-- Proceed only if the ability is really found
		if ability_table then
			local modifier_table = ability_table["Modifiers"][modifier_name]
			if modifier_table then
				local IsDebuff = modifier_table["IsDebuff"]
				if IsDebuff and IsDebuff == 1 then
					return true
				end
			end
		end
	end

	return false
end

-- ToggleAbility On only if its turned Off
function ToggleOn( ability )
	if ability:GetToggleState() == false then
		ability:ToggleAbility()
	end
end

-- ToggleAbility Off only if its turned On
function ToggleOff( ability )
	if ability:GetToggleState() == true then
		ability:ToggleAbility()
	end
end

function IsMultiOrderAbility( ability )
	if IsValidEntity(ability) then
		local ability_name = ability:GetAbilityName()
		local ability_table = GameRules.AbilityKV[ability_name]

		if not ability_table then
			ability_table = GameRules.ItemKV[ability_name]
		end

		if ability_table then
			local AbilityMultiOrder = ability_table["AbilityMultiOrder"]
			if AbilityMultiOrder and AbilityMultiOrder == 1 then
				return true
			end
		else
			print("Cant find ability table for "..ability_name)
		end
	end
	return false
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

function IsMineOccupiedByTeam( mine, teamID )
	return (IsValidEntity(mine.building_on_top) and mine.building_on_top:GetTeamNumber() == teamID)
end

function ApplyConstructionEffect( unit )
	local item = CreateItem("item_apply_modifiers", nil, nil)
	item:ApplyDataDrivenModifier(unit, unit, "modifier_construction", {})
	item = nil
end

function RemoveConstructionEffect( unit )
	unit:RemoveModifierByName("modifier_construction")
end

-- Undead Ground
function CreateBlight(location, size)

	-- Radius should be an odd number for precision
	local radius = 960
	if size == "small" then
		radius = 704
	end
	local particle_spread = 256
	local count = 0
	
	-- Mark every grid square as blighted
    for x = location.x - radius, location.x + radius, 64 do
        for y = location.y - radius, location.y + radius, 64 do
            local position = Vector(x, y, location.z)
            if not HasBlight(position) then

            	-- Make particle effects every particle_spread
            	if (x-location.x) % particle_spread == 0 and (y-location.y) % particle_spread == 0 then
            		local particle = ParticleManager:CreateParticle("particles/custom/undead/blight_aura.vpcf", PATTACH_CUSTOMORIGIN, nil)
	    			ParticleManager:SetParticleControl(particle, 0, position)
	    			GameRules.Blight[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosY(position.y)] = particle
	    			count = count+1
	    		else
        	   		GameRules.Blight[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosY(position.y)] = false
        	   	end
            end
        end
    end

    print("Made "..count.." new blight particles")
   
end

-- Blight can be dispelled once the building that generated it has been destroyed or unsummoned.
function RemoveBlight( location, radius )
	location.x = SnapToGrid64(location.x)
    location.y = SnapToGrid64(location.y)
    radius = radius - (radius%64) + 256

    local count = 0
	for x = location.x - radius, location.x + radius, 64 do
        for y = location.y - radius, location.y + radius, 64 do
        	local dispelBlight = true
        	local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, location, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,unit in pairs(units) do
				if IsCustomBuilding(unit) and IsUndead(unit) then
					dispelBlight = false
					break
				end
			end

			-- No undead building was found nearby this gridnav position, remove blight around the position
			local position = Vector(x, y, location.z)

			if dispelBlight and HasBlightParticle( position ) then
				-- Clear this blight zone
				local blight_index = GameRules.Blight[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosY(position.y)]
				ParticleManager:DestroyParticle(blight_index, false)
				ParticleManager:ReleaseParticleIndex(blight_index)
				count = count+1

				for blight_x = x - 128, x + 128, 64 do
					for blight_y = y - 128, y + 128, 64 do
						GameRules.Blight[GridNav:WorldToGridPosX(blight_x)..","..GridNav:WorldToGridPosY(blight_y)] = nil
					end
				end
			end
		end
	end
	print("Removed "..count.." blight particles")
end

-- Takes a Vector and checks if there is marked as blight in the grid
function HasBlight( position )
	return GameRules.Blight[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosY(position.y)] ~= nil
end

-- Not every gridnav square needs a blight particle
function HasBlightParticle( position )
	return GameRules.Blight[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosY(position.y)]
end


-- Ground/Air Attack mechanics
function UnitCanAttackTarget( unit, target )
	if not unit:HasAttackCapability() then
		return false
	end
	local enabled_attacks = GetEnabledAttacks(unit)
	local target_type = GetMovementCapability(target)

	if string.match(enabled_attacks, target_type) then
		return true
	else
		return false
	end
end

-- Returns "air" if the unit can fly
function GetMovementCapability( unit )
	if unit:HasFlyMovementCapability() then
		return "air"
	else 
		return "ground"
	end
end

-- Searches for "EnabledAttacks" in the KV files
-- Default by omission is "ground", other possible returns should be "ground,air" or "air"
function GetEnabledAttacks( unit )
	local unitName = unit:GetUnitName()
	local enabled_attacks

	if unit:IsHero() then
		enabled_attacks = GameRules.HeroKV[unitName]["EnabledAttacks"]
	else
		enabled_attacks = GameRules.UnitKV[unitName]["EnabledAttacks"]
	end

	if enabled_attacks then
		return enabled_attacks
	else
		return "ground"
	end
end

-- Searches for "EnabledAttacks", false by omission
function HasSplashAttack( unit )
	local unitName = unit:GetUnitName()
	local unit_table = GameRules.UnitKV[unitName]
	
	if unit_table then
		if unit_table["SplashAttack"] and unit_table["SplashAttack"] == 1 then
			return true
		end
	end

	return false
end

function GetMediumSplashRadius( unit )
	local unitName = unit:GetUnitName()
	local unit_table = GameRules.UnitKV[unitName]
	if unit_table["SplashMediumRadius"] then
		return unit_table["SplashMediumRadius"]
	end
	return 0
end

function GetSmallSplashRadius( unit )
	local unitName = unit:GetUnitName()
	local unit_table = GameRules.UnitKV[unitName]
	if unit_table["SplashSmallRadius"] then
		return unit_table["SplashSmallRadius"]
	end
	return 0
end

function GetMediumSplashDamage( unit )
	local unitName = unit:GetUnitName()
	local unit_table = GameRules.UnitKV[unitName]
	if unit_table["SplashMediumDamage"] then
		return unit_table["SplashMediumDamage"]
	end
	return 0
end

function GetSmallSplashDamage( unit )
	local unitName = unit:GetUnitName()
	local unit_table = GameRules.UnitKV[unitName]
	if unit_table["SplashSmallDamage"] then
		return unit_table["SplashSmallDamage"]
	end
	return 0
end

function HoldPosition( unit )
	ApplyModifier(unit, "modifier_hold_position")
end

-- Global item applier
function ApplyModifier( unit, modifier_name )
	local item = CreateItem("item_apply_modifiers", nil, nil)
	item:ApplyDataDrivenModifier(unit, unit, modifier_name, {})
	item:RemoveSelf()
end