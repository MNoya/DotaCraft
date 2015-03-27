function StormHammer( event )
	local caster = event.caster
	local target = event.target
	local targets = event.target_entities
	local ability = event.ability

	print("Storm Hammer Launched")

	print(#targets)
	local next_target = targets[1]
	if next_target == caster then
		next_target = targets[2]
	end

	if next_target then
		print(next_target:GetUnitName())
		local projTable = {
			EffectName = "particles/units/heroes/hero_zuus/zuus_base_attack.vpcf",
			Ability = ability,
			Target = next_target,
			Source = target,
			bDodgeable = true,
			bProvidesVision = false,
			vSpawnOrigin = target:GetAbsOrigin(),
			iMoveSpeed = 900,
			iVisionRadius = 0,
			iVisionTeamNumber = caster:GetTeamNumber(),
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
		}
		ProjectileManager:CreateTrackingProjectile( projTable )
	end
end


function StormHammerDamage( event )
	print("Storm Hammer Damage")
	local caster = event.caster
	local target = event.target
	local damage = caster:GetAverageTrueAttackDamage()
	local ability = event.ability
	local AbilityDamageType = ability:GetAbilityDamageType()

	ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = AbilityDamageType })

end