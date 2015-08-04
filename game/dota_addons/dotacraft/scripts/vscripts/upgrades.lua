-- Go through every ability and check if the requirements are met
-- Swaps abilities with _disabled to their non disabled version and viceversa
-- This is called in multiple events:
	-- On every unit & building after ResearchComplete or after a building is destroyed
	-- On single unit after spawning in MoveToRallyPoint
	-- On single building after spawning in OnConstructionStarted
function CheckAbilityRequirements( unit, player )

	local requirements = GameRules.Requirements
	local buildings = player.buildings
	local upgrades = player.upgrades

	-- Check the Researches for this player, adjusting the abilities that have been already upgraded
   CheckResearchRequirements( unit, player )

	-- The disabled abilities end with this affix
	local len = string.len("_disabled")

	if IsValidEntity(unit) then
		local hero = unit:GetOwner()
		local pID = hero:GetPlayerID()

		--print("--- Checking Requirements on "..unit:GetUnitName().." ---")
		for abilitySlot=0,15 do
			local ability = unit:GetAbilityByIndex(abilitySlot)

			-- If the ability exists
			if ability then
				local ability_name = ability:GetAbilityName()

				-- Exists and isn't hidden, check its requirements
				if IsValidEntity(ability) then
					local disabled = false
				
					-- By default, all abilities that have a requirement start as _disabled
					-- This is to prevent applying passive modifier effects that have to be removed later
					-- The disabled ability is just a dummy for tooltip, precache and level 0.
					-- Check if the ability is disabled or not
					if string.find(ability_name, "_disabled") then
						-- Cut the disabled part from the name to check the requirements
						local ability_len = string.len(ability_name)
						ability_name = string.sub(ability_name, 1 , ability_len - len)
						disabled = true
					end

					-- Check if it has requirements on the KV table
					local player_has_requirements = PlayerHasRequirementForAbility( player, ability_name)

					--[[Act accordingly to the disabled/enabled state of the ability
						If the ability is _disabled
							Requirements succeed: Enable (the player has the necessary researches or buildings to utilize this)
						 	Requirements fail: Do nothing
						Else ability was enabled
						 	Requirements succeed: Do nothing
							Requirements fail: Set disabled (the player lost some requirement due to building destruction)
					]]

					-- Unlock all abilities inside the workshop tools
					if Convars:GetBool("developer") then
						player_has_requirements = true
					end

					if disabled then
						if player_has_requirements then
							-- Learn the ability and remove the disabled one (as we might run out of the 16 ability slot limit)
							--print("SUCCESS, ENABLED "..ability_name)
							unit:AddAbility(ability_name)

							local disabled_ability_name = ability_name.."_disabled"
							unit:SwapAbilities(disabled_ability_name, ability_name, false, true)
							unit:RemoveAbility(disabled_ability_name)

							-- Set the new ability level
							local ability = unit:FindAbilityByName(ability_name)
							ability:SetLevel(ability:GetMaxLevel())
						else
							--print("Ability Still DISABLED "..ability_name)
						end
					else
						if player_has_requirements then
							--print("Ability Still ENABLED "..ability_name)
							--ability:SetLevel(1)
						else	
							-- Disable the ability, swap to a _disabled
							--print("FAIL, DISABLED "..ability_name)

							local disabled_ability_name = ability_name.."_disabled"
							unit:AddAbility(disabled_ability_name)					
							unit:SwapAbilities(ability_name, disabled_ability_name, false, true)
							unit:RemoveAbility(ability_name)

							-- Set the new ability level
							print("Finding",disabled_ability_name)
							local disabled_ability = unit:FindAbilityByName(disabled_ability_name)
							disabled_ability:SetLevel(0)
						end
					end				
				else
					--print("->Ability is hidden or invalid")	
				end
			end
		end
	else
		print("! Not a Valid Entity !, there's currently ",#player.units,"units and",#player.structures,"structures in the table")
	end

	-- Fire update lumber costs UI
	--print("###Firing ability_values_force_check for "..unit:GetUnitName())
	FireGameEvent( 'ability_values_force_check', { player_ID = pID })
	
end

-- In addition and run just before CheckAbilityRequirements, when a building starts construction
-- this will swap to the correct rank of each research_ or remove it if the max rank has been detected
function CheckResearchRequirements( unit, player )
	if IsValidEntity(unit) then
		for abilitySlot=0,15 do
			local ability = unit:GetAbilityByIndex(abilitySlot)

			if ability then
				local ability_name = ability:GetAbilityName()

				if string.find(ability_name, "research_") then
					if PlayerHasResearch(player, ability_name) then -- Player has the initial research

						local max_research_rank = MaxResearchRank(ability_name)
						local current_research_rank = GetCurrentResearchRank( player, ability_name )

						if max_research_rank > 1 and current_research_rank < max_research_rank then
						
							local next_rank = tostring(current_research_rank + 1)
							local new_research_name = string.gsub(ability_name, tostring(current_research_rank) , next_rank)

							unit:AddAbility(new_research_name)
							unit:SwapAbilities(ability_name, new_research_name, false, true)
							unit:RemoveAbility(ability_name)

							local new_ability = unit:FindAbilityByName(new_research_name) 
							new_ability:SetLevel(new_ability:GetMaxLevel())
							print("Requirement available: ",new_ability:GetAbilityName())
						else
							-- Max Rank researched. Remove it
							ability:SetHidden(true)
							unit:RemoveAbility(ability_name)							
						end
					end
				end
			end
		end
	end
end

-- This function is called on every unit after ResearchComplete
function UpdateUnitUpgrades( unit, player, research_name )
	if not IsValidEntity(unit) then
		return
	end
	local unit_name = unit:GetUnitName()
	local upgrades = player.upgrades

	-- Research name is "(race)_research_(name)(rank)"
	-- The ability name is "(race)_(name)", so we need to  cut it accordingly
	
	-- First, remove "research_"  from the name
	local ability_name = string.gsub(research_name, "research_" , "")

	-- Then we cut the rank number and save it
	local ability_len = string.len(ability_name)
	local rank = string.sub(ability_name, ability_len , ability_len)
	if rank == "1" or rank == "2" or rank == "3" then
		rank = tonumber(rank)
		ability_name = string.sub(ability_name, 1 , ability_len - 1)
	end	

	-- Check the UnitUpgrades table, if unit_name can benefit from ability_name
	local unit_upgrades = GameRules.UnitUpgrades

	if unit_upgrades[ability_name] and unit_upgrades[ability_name][unit_name] then

		-- Handle upgrades that only upgrade the unit if it has a certain modifier
		if string.match(unit_upgrades[ability_name][unit_name], "modifier") then
			if not unit:HasModifier(unit_upgrades[ability_name][unit_name]) then
				print("UUU", unit_name.." doesnt have "..unit_upgrades[ability_name][unit_name])
				return
			end
		end

		print("UUU",unit_name.." - "..ability_name.." - rank "..rank)

		-- If its the first rank of the ability, simply add it
		-- If the unit already has a previous rank, remove it
		if rank > 1 then
			local old_rank = rank-1
			local old_ability_name = ability_name..old_rank
			local old_ability = unit:FindAbilityByName(old_ability_name)
			local new_ability_name = ability_name..rank

			-- Remove any of the modifiers before reapplying
			-- This is necessary because removing the ability doesn't remove the passive modifiers
			RemoveAssociatedModifiers(unit, old_ability_name, unit_upgrades[ability_name])

			unit:AddAbility(new_ability_name)
			unit:SwapAbilities(old_ability_name, new_ability_name, false, true)
			unit:RemoveAbility(old_ability_name)
			
			local new_ability = unit:FindAbilityByName(new_ability_name)
			new_ability:SetLevel(rank)
			
			print("UUU"," Rank "..rank.." of "..ability_name.." Reached")
		
		elseif rank == 1 then
			-- Learn the rank 1 ability
			local new_ability_name = ability_name..rank
			unit:AddAbility(new_ability_name)
			
			local new_ability = unit:FindAbilityByName(new_ability_name)
			new_ability:SetLevel(rank)
			print("UUU","First Rank of "..ability_name.." Reached")
		else
			print("UUU","Ability "..ability_name.." has no ranks, this shouldn't happen")
			return
		end

		-- Update cosmetics of the unit if possible
		local wearable_upgrade_type = unit_upgrades[ability_name].wearable_upgrade_type
		if wearable_upgrade_type then
			if wearable_upgrade_type == "weapon" then
				UpgradeWeaponWearables(unit, rank)
			elseif wearable_upgrade_type == "armor" then
				UpgradeArmorWearables(unit, rank)
			end	
		end
	end
end

-- Removes the modifiers associated to the ability name this unit
function RemoveAssociatedModifiers( unit, ability_name, table )
	local modifiers = table.modifiers

	if modifiers then
		for k,v in pairs(modifiers) do
			if unit:HasModifier(k) then
				unit:RemoveModifierByName(k)
			end
		end
	end
end


-- Read the wearables.kv, check the unit name, swap weapon to the next level
function UpgradeWeaponWearables(target, level)
	
	local wearable = target:FirstMoveChild()
	local unit_name = target:GetUnitName()
	print("UWW",unit_name,level)
	local wearables = GameRules.Wearables
	local unit_table = wearables[unit_name]
	if not unit_table then
		print("ERROR, this unit has no entry in the Wearables Weapon table")
		return
	end
	local weapon_table = unit_table.weapon

	local original_weapon = weapon_table[tostring(0)]
	local old_weapon = weapon_table[tostring((level)-1)]
	local new_weapon = weapon_table[tostring(level)]

	print("UWW",old_weapon,new_weapon)
	
	while wearable ~= nil do
		if wearable:GetClassname() == "dota_item_wearable" then
			print("UWW",wearable:GetModelName())

			-- Unit just spawned, it has the default weapon
			if original_weapon == wearable:GetModelName() then
				wearable:SetModel( new_weapon )
				print("UWW", "\nSuccessfully swap " .. original_weapon .. " with " .. new_weapon )
				break

			-- In this case, the unit is already on the field and might have an upgrade
			elseif old_weapon and old_weapon == wearable:GetModelName() then
				wearable:SetModel( new_weapon )
				print("UWW", "\nSuccessfully swap " .. old_weapon .. " with " .. new_weapon )
				break
			end
		end
		wearable = wearable:NextMovePeer()
	end
end

-- Read the wearables.kv, check the unit name, swap all armors to the next level
function UpgradeArmorWearables(target, level)
	
	local wearable = target:FirstMoveChild()
	local unit_name = target:GetUnitName()
	print("UAW",unit_name,level)
	local wearables = GameRules.Wearables
	local unit_table = wearables[unit_name]
	if unit_table then
		local armor_table = unit_table.armor

		print("Armor Table")
		for k,armor in pairs(armor_table) do
			print(k)
			--DeepPrintTable(armor)
		
			local original_armor = armor[tostring(0)]
			local old_armor = armor[tostring((level)-1)]
			local new_armor = armor[tostring(level)]
			
			while wearable ~= nil do
				if wearable:GetClassname() == "dota_item_wearable" then
					print("UAW",wearable:GetModelName())

					-- Unit just spawned, it has the default weapon
					if original_armor == wearable:GetModelName() then
						wearable:SetModel( new_armor )
						print("UAW", "\nSuccessfully swap " .. original_armor .. " with " .. new_armor )
						break

					-- In this case, the unit is already on the field and might have an upgrade
					elseif old_armor and old_armor == wearable:GetModelName() then
						wearable:SetModel( new_armor )
						print("UAW", "\nSuccessfully swap " .. old_armor .. " with " .. new_armor )
						break
					end
				end
				wearable = wearable:NextMovePeer()
			end
		end
	end
end