require('units/undead/meat_wagon')
function cannibalize(keys)
	local caster = keys.caster
	local ability = keys.ability
	local RADIUS = ability:GetSpecialValueFor("search_radius")
	-- find all dota creatures within radius
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), RADIUS)
	
	for k,corpse in pairs(targets) do
		local abilitylevel = ability:GetLevel()
		local spawnlocation = corpse:GetAbsOrigin()
		
		-- if corpse is on the floor
		if not corpse.being_eaten then
			-- if body on floor
			if corpse.corpse_expiration ~= nil then	
				--print("actual corpse found")
				corpse.being_eaten = true
				
				keys.ability.corpse = corpse
				ToggleOn(keys.ability)
				
				keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_cannibalize_properties",  nil)
									
				search_cannibalize(keys)
				return
			end
			
			-- if meatwagon and has stacks
			if corpse:GetUnitName() == "undead_meat_wagon" and corpse:GetModifierStackCount("modifier_corpses", corpse) > 0 and caster:GetPlayerOwnerID() == corpse:GetPlayerOwnerID() then	
				local StackCount = corpse:GetModifierStackCount("modifier_corpses", corpse)
				if  StackCount > 0 then
					--print("meatwagon found")
					
					-- save corpse in keys so that it can be used to remove stackcount and generate body
					keys.ability.corpse = corpse
					
					-- save new corpse in keys
					keys.ability.corpse = drop_single_corpse(keys)
							
					-- toggle and cast eat
					ToggleOn(keys.ability)
					
					keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_cannibalize_properties",  nil)
					
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
	--print("moving to food")
	
	keys.ability.MoveToFood = Timers:CreateTimer(caster:GetEntityIndex().."_cannibalizing", {
	callback = function()
	if not IsValidEntity(corpse) and not IsValidEntity(caster) then
		return
	end
		
		local casterposition = Vector(caster:GetAbsOrigin().x, caster:GetAbsOrigin().y)
		local corpseposition = Vector(corpse:GetAbsOrigin().x, corpse:GetAbsOrigin().y)

		--local distance = UnitPosition - GoalPosition
		local CalcDistance = (corpseposition - casterposition):Length2D()

		if CalcDistance >= 150 then
			caster:MoveToPosition(corpse:GetAbsOrigin())
		elseif CalcDistance < 150 then
			--print("close enough to eat corpse")
						
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
	local caster = keys.caster
	
	local HEALTH_GAIN = keys.ability:GetSpecialValueFor("health_per_second")
	
	-- set corpse flags
	corpse.volumeLeft = 33
	corpse.corpse_expiration = nil
	
	ability.eatingTimer = Timers:CreateTimer(1, function()
		--print(corpse.volumeLeft)
		if not IsValidEntity(corpse) and not IsValidEntity(caster) then
			return
		end
		
		if corpse.volumeLeft ~= 0 then -- if the volume is not equal to 0 then remove a second
			corpse.volumeLeft = corpse.volumeLeft - 1
		else -- if 0 or full hp
			stop_cannibalize(keys)
			return
		end
		
		caster:SetHealth(caster:GetHealth() + HEALTH_GAIN)
		caster:StartGesture(ACT_DOTA_ATTACK)
		
		local particle
		Timers:CreateTimer(0.2, function()
			if IsValidEntity(corpse) then
				particle = ParticleManager:CreateParticle("particles/items2_fx/soul_ring_blood.vpcf", 2, corpse) 
				ParticleManager:SetParticleControl(particle, 0, corpse:GetAbsOrigin() - Vector(0,0,70))
			end
		end)
		
		Timers:CreateTimer(0.9, function() if IsValidEntity(corpse) then ParticleManager:DestroyParticle(particle, true) end end)
		
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
	--print("On Order")
	if not IsValidEntity(keys.ability.corpse) then
		return
	end
	
	local ability = keys.ability
	local corpse = keys.ability.corpse
	local count = keys.ability.corpse.count
	local caster = keys.caster
	local StackCount = corpse:GetModifierStackCount("modifier_corpses", corpse)
	
	-- stop animation, and toggle off ability
	caster:Stop()
	caster:RemoveGesture(ACT_DOTA_ATTACK)
	if keys.ability:GetToggleState() then
		ToggleOff(keys.ability)
	end
	
	-- remove timers if found
	if ability.MoveToFood ~= nil then
		--print("[GHOUL STOP TIMER] moving to food")
		Timers:RemoveTimer(ability.MoveToFood)
	end
	
	if ability.eatingTimer ~= nil then
		--print("[GHOUL STOP TIMER] stop eating")
		Timers:RemoveTimer(ability.eatingTimer)	
	end
	
	-- remove modifiers if found
	if caster:FindModifierByName("modifier_cannibalize") then
		caster:RemoveModifierByName("modifier_cannibalize")
	end
	if caster:FindModifierByName("modifier_cannibalize_properties") then
		caster:RemoveModifierByName("modifier_cannibalize_properties")
	end
	
	if corpse.volumeLeft == nil or corpse.volumeLeft == 33 then
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

end

function frenzy ( keys )
	local caster = keys.caster
	local base_attack_time = caster:GetBaseAttackTime()
	local attack_speed_bonus = keys.ability:GetSpecialValueFor("attack_speed_bonus")

	caster:SetBaseAttackTime(base_attack_time - attack_speed_bonus)
end