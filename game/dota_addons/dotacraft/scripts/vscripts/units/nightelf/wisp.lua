function Detonate( event )
	local caster = event.caster
	if caster:HasModifier("modifier_builder_hidden") then caster:Interrupt() return end
	local point = event.target_points[1]
	local ability = event.ability
	local radius = ability:GetSpecialValueFor("radius")
	local mana_drained = ability:GetSpecialValueFor("mana_drained")
	local damage_to_summons = ability:GetSpecialValueFor("damage_to_summons")

	local units = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for k,unit in pairs(units) do
		-- Damage summons
		if unit:IsSummoned() and unit:GetTeamNumber() ~= caster:GetTeamNumber() then
			ApplyDamage({ victim = unit, attacker = caster, damage = damage_to_summons, damage_type = DAMAGE_TYPE_PURE, ability = ability}) 
		end

		local bRemovePositiveBuffs = false
		local bRemoveDebuffs = false

		-- Remove buffs on enemies or debuffs on allies
		if unit:GetTeamNumber() ~= caster:GetTeamNumber() then
			bRemovePositiveBuffs = true
			-- Mana Drain (no damage)
			if unit:GetMana() > 0 then
				unit:SetMana(unit:GetMana() - mana_drained)
			end
		else
			bRemoveDebuffs = true
		end

		unit:Purge(bRemovePositiveBuffs, bRemoveDebuffs, false, false, false)
	end
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_brewmaster/brewmaster_dispel_magic.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, point)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0,0 ))

	local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_guardian_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle2, 0, point)

	local particle3 = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_death.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle3, 0, point)

	Blight:Dispel(point)

	caster:EmitSound("Hero_Wisp.TeleportOut")
	caster:ForceKill(true)
	caster:AddNoDraw()
	caster.no_corpse = true
end