-- The first Hero is free, only costs 5 supply and comes with a free Town Portal Scroll and a free skill point.
-- Additional Heroes require resources, and come with one skill point but do not have additional Town Portal Scrolls. 
-- To build a second Hero, you must upgrade your Town Hall to a Keep instead of a Town Hall. 
-- To build a third Hero you must have a third level Town Hall building such as a Castle.
-- You cannot train more than 3 Heroes
-- 

function BuildHero( event )
	local caster = event.caster
	local player = caster:GetPlayerOwner()
	local hero = player:GetAssignedHero()
	local playerID = player:GetPlayerID()
	local unit_name = event.Hero
	local origin = event.caster:GetAbsOrigin() + RandomVector(250)

	-- Get a random position to create the new_hero in
	local origin = caster:GetAbsOrigin() + RandomVector(150)

	-- handle_UnitOwner needs to be nil, else it will crash the game.
	local new_hero = CreateUnitByName(unit_name, origin, true, hero, nil, hero:GetTeamNumber())
	new_hero:SetPlayerID(playerID)
	new_hero:SetControllableByPlayer(playerID, true)
	new_hero:SetOwner(hero)
	
	if caster.flag then
		local position = caster.flag:GetAbsOrigin()
		Timers:CreateTimer(0.05, function() 
			FindClearSpaceForUnit(new_hero, new_hero:GetAbsOrigin(), true)
			new_hero:MoveToPosition(position) 
		end)
		print(new_hero:GetUnitName().." moving to position",position)
	end

	table.insert(player.heroes, new_hero)
	CheckAbilityRequirements(new_hero, player)

	-- Swap the (hidden) finished hero ability for a passive version, to indicate it has been trained
	local ability = event.ability
	local ability_name = ability:GetAbilityName()
	
	-- Cut the _train and rank
	local new_ability_name = string.gsub(ability_name, "_train" , "")
	new_ability_name = string.sub(new_ability_name, 1 , string.len(new_ability_name) - 1)

	-- Swap and Disable
	caster:AddAbility(new_ability_name)
	caster:SwapAbilities(ability_name, new_ability_name, false, true)
	caster:RemoveAbility(ability_name)
	local new_ability = caster:FindAbilityByName(new_ability_name)
	new_ability:SetLevel(new_ability:GetMaxLevel())

end

function UpgradeAltarAbilities( event )
	local caster = event.caster
	local abilityOnProgress = event.ability
	local level = event.Level -- The level to upgrade the other train abilities

	for i=0,15 do
		local ability = caster:GetAbilityByIndex(i)
		if ability then
			local ability_name = ability:GetAbilityName()
			if string.find(ability_name, "_train") then
				if ability_name ~= abilityOnProgress:GetAbilityName() then	
					if level == "0"	then -- Disable completely
						ability:SetHidden(true)
						--caster:RemoveAbility(ability_name)
					else	

						local ability_len = string.len(ability_name)
						local rank = string.sub(ability_name, ability_len , ability_len)
						local new_ability_name = string.gsub(ability_name, rank , level)

						-- Show this ability be a _disabled version?
						--[[local disabled = true
						if HasCityCenterLevel(player, level) then

							disabled = false
						end]]

						caster:AddAbility(new_ability_name)
						caster:SwapAbilities(ability_name, new_ability_name, false, true)
						caster:RemoveAbility(ability_name)


						local new_ability = caster:FindAbilityByName(new_ability_name) 
						new_ability:SetLevel(new_ability:GetMaxLevel())
						print("Swapped "..ability_name.." with "..new_ability:GetAbilityName())
					end
				else
					-- Things go wrong if the ability being channeled is removed so just set it hidden
					ability:SetHidden(true)
				end
			end
		end			
	end

	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	FireGameEvent( 'ability_values_force_check', { player_ID = playerID })
end

function ReEnableAltarAbilities( event )
	local caster = event.caster

	for i=0,15 do
		local ability = caster:GetAbilityByIndex(i)
		if ability then
			local ability_name = ability:GetAbilityName()

			-- Gotta adjust back the abilities

			if string.find(ability_name, "_train") and ability:IsHidden() then
				ability:SetHidden(false)
			end
		end
	end

end