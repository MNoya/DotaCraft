function Teleport( event )
	local caster = event.caster
	local target = event.target
	local point = event.target_points[1]

	-- If no target handle, it was ground targeted
	-- If self-targeted, find the greatest town hall level of the player
	if target == nil or target==caster then
		target = FindHighestLevelCityCenter(caster)
	end

	if not IsCityCenter(target) then
		SendErrorMessage(caster:GetPlayerID(), "error_must_target_town_hall")
		caster:Stop()
	else
		-- Start teleport
		local ability = event.ability
		local teleport_delay = ability:GetSpecialValueFor("teleport_delay")
		local radius = ability:GetSpecialValueFor("radius")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_scroll_of_town_portal_caster", {duration=teleport_delay})

		caster:EmitSound("Hero_KeeperOfTheLight.Recall.Cast")

		local color = dotacraft:ColorForPlayer( caster:GetPlayerID() )

		local particle_caster = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(particle_caster, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle_caster, 1, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle_caster, 2, color)
		ParticleManager:SetParticleControl(particle_caster, 4, caster:GetAbsOrigin())
		local particle_target = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN, target)
		ParticleManager:SetParticleControl(particle_target, 0, target:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle_target, 1, target:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle_target, 2, color)
		ParticleManager:SetParticleControl(particle_target, 4, target:GetAbsOrigin())

		Timers:CreateTimer(teleport_delay, function()

			-- Teleport self-owned army in radius
			local player = caster:GetPlayerOwner()
			local team = caster:GetTeamNumber()
			local position = caster:GetAbsOrigin()
			local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
			local targets = FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, 0, FIND_ANY_ORDER, false)

			for _,unit in pairs(targets) do
				if not IsCustomBuilding(unit) and unit:GetPlayerOwner() == player then
		     		FindClearSpaceForUnit(unit, target:GetAbsOrigin(), true)
		     		unit:Stop()
		     	end
		    end

		    FindClearSpaceForUnit(caster, target:GetAbsOrigin(), true)

		    caster:StopSound("Hero_KeeperOfTheLight.Recall.Cast")

		    ParticleManager:DestroyParticle(particle_caster, false)
		    ParticleManager:DestroyParticle(particle_target, false)

		    -- Spend the item
		    ability:RemoveSelf()
		end)
	end	
end