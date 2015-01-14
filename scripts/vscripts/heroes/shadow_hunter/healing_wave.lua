--[[
	Author: Noya
	Date: 14.1.2015.
	Bounces from the main target to nearby targets in range. Avoids bouncing to full health units
]]
function HealingWave( event )
	-- Variables
	local hero = event.caster
	local target = event.target
	local ability = event.ability
	local bounces = ability:GetLevelSpecialValueFor("max_bounces", ability:GetLevel()-1)
	local healing = ability:GetLevelSpecialValueFor("healing", ability:GetLevel()-1)
	local decay = ability:GetSpecialValueFor("wave_decay_percent")  * 0.01
	local radius = ability:GetSpecialValueFor("bounce_range")

	-- main target first
	local particle = ParticleManager:CreateParticle("particles/custom/dazzle_shadow_wave.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin()) --origin
	ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin()) --destination

	local particle = ParticleManager:CreateParticle("particles/custom/dazzle_shadow_wave_copy.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin()) --origin
	ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin()) --destination

	if target:GetHealth() ~= target:GetMaxHealth()  then 
		target:Heal(healing, target) 
		PopupHealing(target,math.floor(healing))
	end

	local targetsHealed = {}
	target.healedByWave = true
	table.insert(targetsHealed,target)

	local dummy = nil
	local units = nil
	local jump_interval = 0.3

	bounces = bounces -1

	-- do bounces from target to new targets
	Timers:CreateTimer(DoUniqueString("HealingWave"), {
		endTime = jump_interval,
		callback = function()
	
			-- unit selection and counting
			local allies = FindUnitsInRadius(target:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 
												DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0, false)

			-- particle
			targetVec = target:GetAbsOrigin()
			targetVec.z = target:GetAbsOrigin().z + target:GetBoundingMaxs().z
			if dummy ~= nil then
				dummy:RemoveSelf()
			end
			dummy = CreateUnitByName("dummy_unit", targetVec, false, hero, hero, hero:GetTeam())

			-- select a target randomly from the table and heal. while loop makes sure the target doesn't select itself.			
			local possibleTargetsBounce = {}
			-- Add the 
			for _,v in pairs(allies) do
				-- if not healed and not on full health
				if not v.healedByWave and v:GetHealth() ~= v:GetMaxHealth() then
					table.insert(possibleTargetsBounce,v)
				end
			end

			target = possibleTargetsBounce[math.random(1,#possibleTargetsBounce)]
			if target then
				target.healedByWave = true
				table.insert(targetsHealed,target)		
			else
				-- clear the struck table and end
				for _,v in pairs(targetsHealed) do
			    	v.healedByWave = false
			    	v = nil
			    end
				return
			end

			local particle = ParticleManager:CreateParticle("particles/custom/dazzle_shadow_wave.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
			ParticleManager:SetParticleControl(particle,0,dummy:GetAbsOrigin()) --Vector(dummy:GetAbsOrigin().x,dummy:GetAbsOrigin().y,dummy:GetAbsOrigin().z + dummy:GetBoundingMaxs().z ))	-- origin
			local particle2 = ParticleManager:CreateParticle("particles/custom/dazzle_shadow_wave_copy.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
			ParticleManager:SetParticleControl(particle2,0,dummy:GetAbsOrigin()) --Vector(dummy:GetAbsOrigin().x,dummy:GetAbsOrigin().y,dummy:GetAbsOrigin().z + dummy:GetBoundingMaxs().z ))	-- origin

			-- heal and decay
			healing = healing - (healing*decay)
			target:Heal(healing, target) 
			PopupHealing(target,math.floor(healing))

			-- make the particle shoot to the target
			ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin()) --destination
			ParticleManager:SetParticleControl(particle2, 1, target:GetAbsOrigin()) --destination

			-- sound

			-- decrement remaining spell bounces
			bounces = bounces - 1

			-- fire the timer again if spell bounces remain
			if bounces > 0 then
				return jump_interval
			end
		end
	})
	
	Timers:CreateTimer(5,function() 
		-- double check
		for _,v in pairs(targetsHealed) do
		   	v.healedByWave = false
		   	v = nil
		end
	end)
end