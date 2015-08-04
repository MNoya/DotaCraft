function undead_absorb_mana(keys)
	local caster = keys.caster
	local target = keys.target
	local PlayerID = caster:GetPlayerOwnerID()

	if target:GetMana() == 0 or IsCustomBuilding(target) then	
		SendErrorMessage(PlayerID, "#error_target_has_no_mana")
		return
	else
		-- store target mana and set target to 0
		local target_mana = target:GetMana()		
		local mana_to_steal = caster:GetMaxMana() - caster:GetMana() 
		
		-- add mana to caster
		target:SetMana(target_mana - mana_to_steal)
		caster:SetMana(caster:GetMana() + target_mana)
	end
end

function undead_devour_magic(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	local RANGE = ability:GetSpecialValueFor("radius")
	local MANA_RESTORE = ability:GetSpecialValueFor("mana_restore")
	local HEALTH_RESTORE = ability:GetSpecialValueFor("health_restore")
	local SUMMON_DAMAGE = ability:GetSpecialValueFor("summoned_unit_damage")
	
	local target = {}
	local count = 1
	
	-- find all units within 300 range that are enemey
	local units = FindUnitsInRadius(caster:GetTeamNumber(), 
								keys.target_points[1], 
								nil, 
								RANGE, 
								DOTA_UNIT_TARGET_TEAM_BOTH + DOTA_UNIT_TARGET_TEAM_CUSTOM, 
								DOTA_UNIT_TARGET_ALL, 
								DOTA_UNIT_TARGET_FLAG_NONE, 
								FIND_CLOSEST, 
								false)
	
	-- add unit to table if meets requirements
	for k,unit in pairs(units) do
		if not IsCustomBuilding(unit) then
			target[count] = unit
			count = count + 1
		end
	end
	
	local RemovedSomething = false
	if target ~= nil then
		--print("target found")						
		for k,unit in pairs(target) do

			-- if unit is summoned
			if unit:IsSummoned() then
				-- check if sentinel owl
				if string.find(unit:GetUnitName(), "nightelf_sentinel_owl") then
					unit:ForceKill(false)
					return
				end
				
				unit:SetHealth(unit:GetHealth() - SUMMON_DAMAGE	)	
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_devour_magic_target", {duration=0.5})
				
				-- if he's dead no need to continue
				if not unit:IsAlive() then
					return
				end
			end
					
			-- find unit modifiers
			local modifiers = unit:FindAllModifiers()
			for k,mods in pairs(modifiers) do -- for all modifiers found
			
				-- exclusion flags
				--if string.find(mods:GetName(), "modifier_attack") or string.find(mods:GetName(), "modifier_armor") or string.find(mods:GetName(), "modifier_devour_magic_target") then
				
				print(IsPurgableModifier(mods))
				if IsPurgableModifier(mods) then
					-- remove if not attack/armor/aura modifier
					--print("purging modifier = "..mods:GetName())
					unit:RemoveModifierByName(mods:GetName())
					RemovedSomething = true -- set something was removed
					ability:ApplyDataDrivenModifier(caster, unit, "modifier_devour_magic_target", {duration=0.5})
				end
				
			end
			
			-- if something was removed
			if RemovedSomething then
				-- give mana and health if enemy team
				if unit:IsOpposingTeam(caster:GetTeam()) then
					caster:SetMana(caster:GetMana() + MANA_RESTORE)
					caster:SetHealth(caster:GetHealth() + HEALTH_RESTORE)
				end
			end
		
		end
		
		-- caster particle
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_devour_magic_caster", {duration=0.5})
	end
end