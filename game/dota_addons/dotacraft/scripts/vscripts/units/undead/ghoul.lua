function cannibalize(keys)
	local caster = keys.caster
	local ability = keys.ability
	local RADIUS = ability:GetSpecialValueFor("radius")
	
	-- find all dota creatures within radius
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), RADIUS)
	
	for k,corpse in pairs(targets) do
		local abilitylevel = ability:GetLevel()
		local spawnlocation = corpse:GetAbsOrigin()
		
		-- if corpse is on the floor
		if not corpse.being_eaten then
			-- if body on floor
			if corpse.corpse_expiration ~= nil then	
				print("actual corpse found")
				corpse.meatwagon = false
				corpse.being_eaten = true
				
				keys.ability.corpse = corpse
				ToggleOn(keys.ability)
				
				search_cannibalize(keys)
				return
			end
			
			-- if meatwagon and has stacks
			if corpse:GetUnitName() == "undead_meat_wagon" and corpse:GetModifierStackCount("modifier_corpses", corpse) > 0 and caster:GetPlayerOwnerID() == corpse:GetPlayerOwnerID() then	
				local StackCount = corpse:GetModifierStackCount("modifier_corpses", corpse)
				if  StackCount > 0 then
					-- set meatwagon flag, and save the current stackcount that's being eaten
					print("meatwagon found")
					if not corpse.being_eaten then
						corpse.being_eaten = {}
					end
					
					corpse.meatwagon = true
					corpse.count = StackCount
					corpse.being_eaten[StackCount] = true
					
					-- save corpse
					keys.ability.corpse = corpse
					
					-- toggle and cast eat
					ToggleOn(keys.ability)
					search_cannibalize(keys)
					return
				end		
			end
		end
		
	end
	
end

-- count will be set to 0 if it's a corpse, otherwise it will correlate to the StackCount
-- IsRealCorpse is to determine whether it's a catapult or actual body on the floor
-- corpse target is stored on caster under caster.corpseTarget
function search_cannibalize(keys)
	local corpse = keys.ability.corpse
	local caster = keys.caster
	print("moving to food")
	caster.MoveToFood = Timers:CreateTimer(caster:GetEntityIndex().."_cannibalizing", {
	callback = function()
	
		local casterposition = Vector(caster:GetAbsOrigin().x, caster:GetAbsOrigin().y)
		local corpseposition = Vector(corpse:GetAbsOrigin().x, corpse:GetAbsOrigin().y)

		--local distance = UnitPosition - GoalPosition
		local CalcDistance = (corpseposition - casterposition):Length2D()
		print(CalcDistance)

		if CalcDistance >= 150 then
			caster:MoveToPosition(corpse:GetAbsOrigin())
		elseif CalcDistance < 150 then
			print("close enough to eat corpse")
			caster:Stop()
			keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_cannibalize",  nil)
			eating(keys)
			return
		end
		
		return 0.25
	end})
end

function eating (keys)
	local ability = keys.ability
	local corpse = keys.ability.corpse
	local count = keys.ability.corpse.count
	local caster = keys.caster
	
	local HEALTH_GAIN = keys.ability:GetSpecialValueFor("health_per_second")
	
	if corpse.meatwagon then
		corpse.volumeLeft[count] = 33
	else
		corpse.volumeLeft = 33
		corpse.corpse_expiration = nil
	end
	
	caster.eatingTimer = Timers:CreateTimer(1, function()
		print(corpse.volumeLeft)
		if corpse.volumeLeft ~= 0 then -- if the volume is not equal to 0 then remove a second
			corpse.volumeLeft = corpse.volumeLeft - 1
		else -- if 0 then body should be removed
			stop_cannibalize(keys)
			return
		end
		
		caster:SetHealth(caster:GetHealth() + HEALTH_GAIN)
		
		caster:StartGesture(ACT_DOTA_ATTACK)
		local particle
		Timers:CreateTimer(0.2, function() particle = ParticleManager:CreateParticle("particles/items2_fx/soul_ring_blood.vpcf", 1, corpse) end)
		Timers:CreateTimer(0.9, function() ParticleManager:DestroyParticle(particle, true) end)
		
		--if full hp
		if caster:GetMaxHealth() == caster:GetHealth() or not IsValidEntity(corpse) then
			stop_cannibalize(keys)
			return
		end
			
		return 1
	end)
	
end

-- called if units orders, this stops the current cannibalize instantly, or leaves the body if
function stop_cannibalize(keys)
	if not IsValidEntity(keys.ability.corpse) then
		return
	end
	
	local ability = keys.ability
	local corpse = keys.ability.corpse
	local count = keys.ability.corpse.count
	local caster = keys.caster
	local StackCount = corpse:GetModifierStackCount("modifier_corpses", corpse)
	
	caster:Stop()
	
	caster:RemoveModifierByName("modifier_cannibalize")
	
	if corpse.volumeLeft == nil then
		corpse.being_eaten = false
	else
		-- if the corpse is not equal to nil then it's a meat wagon
		if not corpse.meatwagon then
			corpse.no_corpse = true
			corpse:RemoveSelf()
		else
			corpse:SetModifierStackCount("modifier_corpses", corpse, StackCount - 1)
			corpse.volumeLeft[count] = nil
		end
	end

	Timers:RemoveTimer(caster.MoveToFood)
	Timers:RemoveTimer(caster.eatingTimer)

	ToggleOff(keys.ability)

	caster:RemoveGesture(ACT_DOTA_ATTACK)
end