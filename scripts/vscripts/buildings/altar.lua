-- The first Hero is free, only costs 5 supply and comes with a free Town Portal Scroll and a free skill point.
-- Additional Heroes require resources, and come with one skill point but do not have additional Town Portal Scrolls. 
-- To build a second Hero, you must upgrade your Town Hall to a Keep instead of a Town Hall. 
-- To build a third Hero you must have a third level Town Hall building such as a Castle.
-- You cannot train more than 3 Heroes, nor buy the same hero more than once
-- When a hero dies, the altar will gain the ability to respawn it for a cost

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

	-- Keep simple track of the abilities being queued, these can't be removed/upgraded else the channeling wont go off
	if not caster.altar_queue then
		caster.altar_queue = {}
	end

	-- Simple track of the current global rank
	if not caster.AltarLevel then
		caster.AltarLevel = 2
	else
		caster.AltarLevel = caster.AltarLevel + 1
	end

	table.insert(caster.altar_queue, abilityOnProgress:GetAbilityName())
	print("ALTAR LEVEL "..caster.AltarLevel.." QUEUE:")
	DeepPrintTable(caster.altar_queue)

	for i=0,15 do
		local ability = caster:GetAbilityByIndex(i)
		if ability then
			local ability_name = ability:GetAbilityName()
			if string.find(ability_name, "_train") then
				if ability_name ~= abilityOnProgress:GetAbilityName() then	
					if caster.AltarLevel == 4	then -- Disable completely
						ability:SetHidden(true)
						--caster:RemoveAbility(ability_name)
					else	

						local ability_len = string.len(ability_name)
						local rank = string.sub(ability_name, ability_len , ability_len)
						if rank ~= "0" then
							local new_ability_name = string.gsub(ability_name, rank , caster.AltarLevel)

							-- If the ability has to be channeled (i.e. is queued), it cant be removed!
							if not tableContains(caster.altar_queue, ability_name) then
								caster:AddAbility(new_ability_name)
								caster:SwapAbilities(ability_name, new_ability_name, false, true)
								caster:RemoveAbility(ability_name)

								local new_ability = caster:FindAbilityByName(new_ability_name) 
								new_ability:SetLevel(new_ability:GetMaxLevel())
								print("Swapped "..ability_name.." with "..new_ability:GetAbilityName())
							else
								ability:SetHidden(true)
								print("Table Contains "..ability_name.." set Hidden because the altar will be casting it later")
							end
						end
					end
				else
					-- Things go wrong if the ability being channeled is removed so just set it hidden
					ability:SetHidden(true)
				end
			end
		end			
	end

	-- Look to disable the upgraded abilities if the requirements arent met
	local player = caster:GetPlayerOwner()
	CheckAbilityRequirements(caster, player)

	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	FireGameEvent( 'ability_values_force_check', { player_ID = playerID })

	PrintAbilities(caster)
end

function ReEnableAltarAbilities( event )
	local caster = event.caster
	local ability = event.ability

	 -- Remove the "item_" to compare
	local item_name = ability:GetAbilityName()
    local train_ability_name = string.gsub(item_name, "item_", "")
	print("ABILITY NAME : "..train_ability_name)

	-- Remove it from the altar queue
	local queue_element = getIndex(caster.altar_queue, train_ability_name)
    table.remove(caster.altar_queue, queue_element)

	-- This is the level at which all train abilities should end up
	caster.AltarLevel = caster.AltarLevel - 1

	print("ALTAR LEVEL "..caster.AltarLevel.." QUEUE:")
	DeepPrintTable(caster.altar_queue)

	print("--")
	for i=0,15 do
		local ability = caster:GetAbilityByIndex(i)
		if ability then
			local ability_name = ability:GetAbilityName()

			-- Gotta adjust back the abilities
			-- The hidden train ability was one in the queue
			if string.find(ability_name, "_train") then
			 	if ability:IsHidden() then

			 		-- The level which abilities have to be downgraded and set visible depends on the current AltarLevel
			 		-- There's some critical issues with different cancelling of the queue that have to be considered

					if not tableContains(caster.altar_queue, ability_name) then

						-- Adjust the correct rank of this ability
						local ability_len = string.len(ability_name)
						local rank = tonumber(string.sub(ability_name, ability_len , ability_len))
						local adjusted_ability_name = string.gsub(ability_name, rank , tostring( caster.AltarLevel))
						print(rank,ability_name,caster.AltarLevel,adjusted_ability_name)

						local correct_ability = caster:FindAbilityByName(adjusted_ability_name)
						if correct_ability then
							correct_ability:SetHidden(false)
							print(adjusted_ability_name.." is now visible")
						else
							-- The ability has to be set to a new level that didn't exist originally
							print("Adding new adjusted ability "..adjusted_ability_name)
							caster:AddAbility(adjusted_ability_name)
							caster:SwapAbilities(ability_name, adjusted_ability_name, false, true)
							caster:RemoveAbility(ability_name)

							local new_adjusted_ability = caster:FindAbilityByName(adjusted_ability_name)
							new_adjusted_ability:SetLevel(new_adjusted_ability:GetMaxLevel())

						end
					else
						ability:SetHidden(true)
						print("Table Contains "..ability_name.." - Keep it hidden, its queued")
					end
				else
					-- If the ability is disabled, need to adjust
					if string.find(ability_name, "_disabled")  then
						ability_name = string.gsub(ability_name, "_disabled" , "")
						print("Adjusted ability name")
					end

					local ability_len = string.len(ability_name)
					local rank = string.sub(ability_name, ability_len , ability_len)
					print(ability_name,rank)
					if rank ~= "1" then

						local downgraded_ability_name = string.gsub(ability_name, rank , tostring( tonumber(rank) - 1))
						print("downgraded_ability_name: ", downgraded_ability_name)

						caster:AddAbility(downgraded_ability_name)
						caster:SwapAbilities(ability_name, downgraded_ability_name, false, true)
						caster:RemoveAbility(ability_name)
						caster:RemoveAbility(ability_name.."_disabled")

						local new_ability = caster:FindAbilityByName(downgraded_ability_name) 
						new_ability:SetLevel(new_ability:GetMaxLevel())
						print("Swapped "..ability_name.." with "..new_ability:GetAbilityName())
						print("--")
					else
						print("RANK 0 WAOW")
						print('--')
					end
				end
			end
		end
	end

	-- Look to disable the downgraded abilities if the requirements arent met
	local player = caster:GetPlayerOwner()
	CheckAbilityRequirements(caster, player)

	PrintAbilities(caster)

end