function undead_essence_of_blight( keys )
	local target = keys.target
	local caster = keys.caster
	local ability = keys.ability
	local LastState = 0
	
	Timers:CreateTimer(function()
	
	-- kill timer if unit dies
		if not IsValidEntity(caster) then 
			return
		end
		
		-- check that ability is not on cooldown
		if ability:GetCooldownTimeRemaining() == 0 then
		
			-- toggle ability off if the other is true
			if caster:FindAbilityByName("undead_essence_of_blight"):GetAutoCastState() and caster:FindAbilityByName("undead_spirit_touch"):GetAutoCastState() and LastState == 0 then			
				LastState = 1
				caster:FindAbilityByName("undead_essence_of_blight"):ToggleAutoCast()
			elseif caster:FindAbilityByName("undead_essence_of_blight"):GetAutoCastState() and caster:FindAbilityByName("undead_spirit_touch"):GetAutoCastState() and LastState == 1 then 
				LastState = 0
				caster:FindAbilityByName("undead_spirit_touch"):ToggleAutoCast()
			end
			
			undead_essence_of_blight_autocast(keys)
		end
		
		return 0.1
	end)	
end


function undead_essence_of_blight_autocast(keys)
	local ability = keys.ability
	local caster = keys.caster
	local AUTOCAST_RANGE = ability:GetSpecialValueFor("radius")
	local MAX_TARGETS = ability:GetSpecialValueFor("max_unit")
	
	local MODIFIER_NAME = nil	
	local index = nil
	local RESTORE_AMOUNT = nil
	
	-- set values depending on ability
	if ability:GetAbilityName() == "undead_essence_of_blight" then
		index = 0 -- set state
		RESTORE_AMOUNT = ability:GetSpecialValueFor("health_restore")
		MODIFIER_NAME = "modifier_blight_heal_target"
	else
		index = 1 -- set state
		RESTORE_AMOUNT = ability:GetSpecialValueFor("mana_restore")
		MODIFIER_NAME = "modifier_spirit_touch_target"
	end
	
	local DURATION = ability:GetSpecialValueFor("duration")	
	local MANA_PER_UNIT = ability:GetSpecialValueFor("mana_per_unit_healed")
	
	local target = {}
	local count = 1
	
	-- if the ability is not toggled, don't proceed any further
	if not ability:GetAutoCastState() then	
		return		
	end
	
	-- find all units within range that are ALLY
	local units = FindUnitsInRadius(caster:GetTeamNumber(), 
								caster:GetAbsOrigin(), 
								nil, 
								AUTOCAST_RANGE, 
								DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
								DOTA_UNIT_TARGET_ALL, 
								DOTA_UNIT_TARGET_FLAG_NONE, 
								FIND_CLOSEST, 
								false)
	
	-- store all valid targets(up to 5) into the target table
	for k,unit in pairs(units) do
		if not unit:HasModifier(MODIFIER_NAME) and not IsCustomBuilding(unit) and unit ~= caster then	
		
			if #target < MAX_TARGETS then -- if not the same as max target then
				if index == 0 and unit:GetHealth() ~= unit:GetMaxHealth() then -- if state 0 and unit is not max health
						target[count] = unit
						count = count + 1
				elseif index == 1 and unit:GetMana() ~= unit:GetMaxMana() then -- if state 1 and unit is not max mana				
						target[count] = unit
						count = count + 1
				end
			end
			
		end
	end

			-- remove caster modifier
	if caster:FindModifierByName("modifier_blight_heal_caster") ~= nil then
		caster:RemoveModifierByName("modifier_blight_heal_caster")
	else
		caster:RemoveModifierByName("modifier_spirit_touch_caster")
	end	
	
	-- if a target is found
	if #target ~= 0 then
		--print("target found")	
		
		-- add caster modifier
		if caster:FindModifierByName("modifier_blight_heal_caster") ~= nil then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_blight_heal_caster", nil)
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_spirit_touch_caster", nil)
		end
		
		local manacost = nil
		
		-- calculate manacost based on #target * 2.. 5 > == 10mana
		if #target < 5 then
			manacost = #target * MANA_PER_UNIT
		else	
			manacost = 10
		end
		
		-- return if the caster doesn't have enough mana
		if caster:GetMana() < manacost then
			return
		end
			
		-- start cooldown & take away mana
		Timers:CreateTimer(function() caster:SetMana(caster:GetMana() - manacost) end)
		ability:StartCooldown(DURATION)
		
		-- apply modifier for visual effect + give health to unit
		for k,unit in pairs(target) do		
			if index == 0 then -- if state 0
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_blight_heal_target", {duration=DURATION})
				unit:SetHealth(unit:GetHealth() + RESTORE_AMOUNT)
			elseif index == 1 then -- if state 1
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_spirit_touch_target", {duration=DURATION})
				unit:SetMana(unit:GetMana() + RESTORE_AMOUNT)
			end		
		end
	end
	
end

-- Automatically toggled on
function ToggleOnAutocast( event )
	local caster = event.caster
	local ability = event.ability

	ability:ToggleAutoCast()
end