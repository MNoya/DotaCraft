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

-- Returns bool
function PlayerHasEnoughGold( player, gold_cost )
	local hero = player:GetAssignedHero()
	local pID = hero:GetPlayerID()
	local gold = hero:GetGold()

	if gold < gold_cost then
		FireGameEvent( 'custom_error_show', { player_ID = playerID, _error = "Need more Gold" } )		
		return false
	else
		return true
	end
end


-- Returns bool
function PlayerHasEnoughLumber( player, lumber_cost )
	local pID = player:GetAssignedHero():GetPlayerID()

	if player.lumber < lumber_cost then
		FireGameEvent( 'custom_error_show', { player_ID = playerID, _error = "Need more Lumber" } )		
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

-- Custom Corpse Mechanic
function LeavesCorpse( unit )
	
	-- Heroes don't leave corpses (includes illusions)
	if unit:IsHero() then
		return false

	-- Ignore buildings	
	elseif unit.GetInvulnCount ~= nil then
		return false

	-- Ignore custom buildings
	elseif (unit:FindAbilityByName("ability_building") == nil) then
		return false

	-- Ignore units that start with dummy keyword	
	elseif string.find(unit:GetUnitName(), "dummy") then
		return false

	-- Ignore units that were specifically set to leave no corpse
	elseif unit.no_corpse then
		return false

	-- ?
	--elseif unit.AddAbility == nil then
	--	return false

	-- Leave corpse
	else
		print("Leave corpse")
		return true
	end
end