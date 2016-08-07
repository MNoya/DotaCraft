function EssenceAutocast( keys )
	local caster = keys.caster
	local mana_ability = caster:FindAbilityByName("undead_spirit_touch")
	local heal_ability = caster:FindAbilityByName("undead_essence_of_blight")
	AbilityState = 0 -- set initial state to essence_of_blight(since it's the starting autocast)
	
	-- check that ability is not on cooldown
	if heal_ability:GetCooldownTimeRemaining() == 0 then
	
		-- toggle ability off if the other is true and vice versa
		if heal_ability:GetAutoCastState() and mana_ability:GetAutoCastState() and AbilityState == 0 then -- toggle on mana, toggle off health
			-- toggle off health
			heal_ability:ToggleAutoCast()
			-- set ability to mana
			keys.ability = mana_ability
			-- set state for next toggle
			AbilityState = 1 
		elseif heal_ability:GetAutoCastState() and mana_ability:GetAutoCastState() and AbilityState == 1 then  -- toggle on health, toggle off mana
			-- toggle off mana
			mana_ability:ToggleAutoCast()
			-- set ability to heal 
			keys.ability = heal_ability
			-- set state for next toggle
			AbilityState = 0 
		end
		
		-- cast only if autocast is on for any of the two abilities
		if heal_ability:GetAutoCastState() or mana_ability:GetAutoCastState() then
			caster:SetMana(caster:GetMana() - 2)
			undead_essence_of_blight(keys)
		end
	end
end

function undead_essence_of_blight(keys)
	local ability = keys.ability
	local caster = keys.caster
	local AUTOCAST_RANGE = ability:GetSpecialValueFor("radius")
	local MAX_TARGETS = ability:GetSpecialValueFor("max_unit")
	local caster_mana_refund = caster:GetMana() + 2
	
	local MODIFIER_NAME
	local index
	local RESTORE_AMOUNT
	local partnerability 
	
	-- set values depending on ability
	if ability:GetAbilityName() == "undead_essence_of_blight" then
		index = 0 -- set state
		RESTORE_AMOUNT = ability:GetSpecialValueFor("health_restore")
		MODIFIER_NAME = "modifier_blight_heal_target"
		partnerability = caster:FindAbilityByName("undead_spirit_touch")
	else
		index = 1 -- set state
		RESTORE_AMOUNT = ability:GetSpecialValueFor("mana_restore")
		MODIFIER_NAME = "modifier_spirit_touch_target"
		partnerability = caster:FindAbilityByName("undead_essence_of_blight")
	end
	
	local DURATION = ability:GetSpecialValueFor("duration")	
	local MANA_PER_UNIT = ability:GetSpecialValueFor("mana_per_unit_healed")
	
	local target = {}
	local count = 1	
	
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
	
	-- start shared cooldown
	ability:StartCooldown(DURATION)
	partnerability:StartCooldown(DURATION)
		
	-- store all valid targets(up to 5) into the target table
	for k,unit in pairs(units) do
		if not unit:HasModifier(MODIFIER_NAME) and not IsCustomBuilding(unit) and not unit:IsMechanical() and not unit:IsWard() and unit ~= caster then	
		
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
		
		-- take away mana
		Timers:CreateTimer(function() caster:SetMana(caster:GetMana() - manacost) end)		
		
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
		
	else -- refund mana & remove cooldown
		Timers:CreateTimer(function() 
			if IsValidEntity(caster) and caster:IsAlive() then
				caster:SetMana(caster_mana_refund)
			end
		end)
		ability:EndCooldown()
		partnerability:EndCooldown()		
	end
	
end

function morph_into_destroyer(keys)
	local caster = keys.caster
	local playerID = caster:GetPlayerOwnerID()
	local player = PlayerResource:GetPlayer(playerID)
	StartAnimation(caster, {duration=5, activity=ACT_DOTA_SPAWN, rate=1.1, translate="loadout"})
	local fv = caster:GetForwardVector()

	Timers:CreateTimer(1.1, function() -- wait	
		local CreatedUnit = CreateUnitByName("undead_destroyer", caster:GetAbsOrigin(), true, player:GetAssignedHero(),  player:GetAssignedHero(), caster:GetTeamNumber())
		CreatedUnit:SetControllableByPlayer(playerID, true)
		CreatedUnit:SetForwardVector(fv)
		
		caster.no_corpse = true
		Players:AddUnit(playerID, CreatedUnit)
		
		ParticleManager:CreateParticle("particles/siege_fx/siege_bad_death_01.vpcf", 0, CreatedUnit)
		PlayerResource:AddToSelection(playerID, CreatedUnit)
		caster:RemoveSelf()
	end)
end


-- Attaches a catapult
function Model( event )
	local caster = event.caster
	local ability = event.ability

	--models/creeps/lane_creeps/creep_bad_siege/creep_bad_siege.vmdl
	
	local statue = CreateUnitByName("undead_obsidian_statue_dummy", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, statue, "modifier_disable_statue", {})

	local attach = caster:ScriptLookupAttachment("attach_hitloc")
	local origin = caster:GetAttachmentOrigin(attach)
	local fv = caster:GetForwardVector()

	statue:SetAbsOrigin(Vector(origin.x, origin.y, origin.z-130))
	statue:SetParent(caster, "attach_hitloc")
	statue:SetAngles(0,0,0)

end