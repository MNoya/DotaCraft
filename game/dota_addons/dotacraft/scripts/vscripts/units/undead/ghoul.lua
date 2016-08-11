function CannibalizeStart(event)
	local caster = event.caster
	local ability = event.ability
	local playerID = caster:GetPlayerOwnerID()
	local radius = ability:GetSpecialValueFor("search_radius")
	local health_per_second = event.ability:GetSpecialValueFor("health_per_second")
	local corpse = Corpses:FindClosestInRadius(playerID, caster:GetAbsOrigin(), radius)
	if corpse then
		if corpse.meat_wagon then -- If the corpse is inside a meat wagon, order to drop it
			corpse.meat_wagon:ThrowCorpse()
		end

		corpse.being_eaten = true -- Only one corpse per ghoul
		corpse.moving_to_cannibalize = true -- Flag removed on reaching the corpse, to know when it has been used
		ToggleOn(ability)
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_cannibalize_properties",  {})						
		caster:MoveToPosition(corpse:GetAbsOrigin())

		if ability.movingTimer then Timers:RemoveTimer(ability.movingTimer) end
		ability.movingTimer = Timers:CreateTimer(0.03, function()
			if not IsValidEntity(caster) or not caster:IsAlive() then return end
			if not IsValidEntity(corpse) then -- If the corpse becomes invalid, cast again
				caster:CastAbilityNoTarget(ability,playerID)
				return
			end
			
			local distance = caster:GetRangeToUnit(corpse)
			if distance >= 150 then
				caster:MoveToPosition(corpse:GetAbsOrigin())
			else
				ability.corpse = corpse
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_cannibalize", {})
				caster:Stop()
				Eating(event)
				return
			end
			
			return 0.25
		end)
	end
end

function Eating(event)
	local caster = event.caster
	local ability = event.ability
	local corpse = ability.corpse
		
	-- set corpse flags
	if not corpse.eat_duration then
		corpse.moving_to_cannibalize = nil
		corpse.eat_duration = ability:GetSpecialValueFor("duration")
		corpse:StopExpiration()
	end

	caster:StartGesture(ACT_DOTA_ATTACK)
	ability:SetChanneling(true)
	ability.eatingTimer = Timers:CreateTimer(1, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return end
		if not IsValidEntity(corpse) then
			CannibalizeEnd(event)
			return
		end
		
		if corpse.eat_duration > 0 then -- if the volume is not equal to 0 then remove a second
			corpse.eat_duration = corpse.eat_duration - 1
		end
		
		caster:StartGesture(ACT_DOTA_ATTACK)
		
		local particle
		Timers:CreateTimer(0.2, function()
			if IsValidEntity(corpse) then
				particle = ParticleManager:CreateParticle("particles/items2_fx/soul_ring_blood.vpcf", 2, corpse) 
				ParticleManager:SetParticleControl(particle, 0, corpse:GetAbsOrigin() - Vector(0,0,70))
			end
		end)
		
		Timers:CreateTimer(0.9, function() if IsValidEntity(corpse) then ParticleManager:DestroyParticle(particle, true) end end)
		
		-- Check if the corpse has seconds left or if the caster is already on full health
		if caster:GetMaxHealth() == caster:GetHealth() or corpse.eat_duration <= 0 then
			CannibalizeEnd(event)
			return
		end
		return 1
	end)
end

-- Called OnOrder, this stops the current cannibalize instantly, removing the body if it was already being eaten
function CannibalizeEnd(event)
	local caster = event.caster
	local ability = event.ability
	local order = event.event_ability
	
	if order and order:GetAbilityName() == "undead_cannibalize" then
		return
	else
		if ability:IsChanneling() then
			ability:SetChanneling(false)
		end
		caster:RemoveModifierByName("modifier_cannibalize")
		caster:RemoveModifierByName("modifier_cannibalize_properties")
	end
	
	-- stop animation and toggle off ability
	ToggleOff(ability)
	caster:RemoveGesture(ACT_DOTA_ATTACK)
	
	-- remove timers if found
	if ability.movingTimer then Timers:RemoveTimer(ability.movingTimer) end
	if ability.eatingTimer then Timers:RemoveTimer(ability.eatingTimer) end
	
	local corpse = ability.corpse
	if corpse and IsValidEntity(corpse) and not corpse.moving_to_cannibalize then
		corpse:RemoveCorpse()
	end
end