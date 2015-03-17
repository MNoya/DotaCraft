function StormHammerDamage( event )
	local caster = event.caster
	local target = event.target
	local damage = caster:GetAverageTrueAttackDamage()
	local ability = event.ability
	local AbilityDamageType = ability:GetAbilityDamageType()

	ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = AbilityDamageType })

end