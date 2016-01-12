function VorpalBlade( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local spill_range = ability:GetSpecialValueFor("spill_range")
	ability.initial_target = target

	local projectileTable = {
        Ability = ability,
        EffectName = "particles/custom/nightelf/glaive_thrower_linear.vpcf",
        vSpawnOrigin = target:GetAbsOrigin(),
        fDistance = spill_range,
        fStartRadius = 50,
        fEndRadius = 150,
        fExpireTime = GameRules:GetGameTime() + 5,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        bProvidesVision = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	}

    local speed = caster:GetProjectileSpeed()/2

    local point = target:GetAbsOrigin()
    point.z = 0
    local pos = caster:GetAbsOrigin()
    pos.z = 0
    local diff = point - pos
    projectileTable.vVelocity = diff:Normalized() * speed

	ProjectileManager:CreateLinearProjectile( projectileTable )
	print("Vorpal Blade Launched from "..target:GetUnitName().." number "..target:GetEntityIndex())
end

function VorpalBladeDamage( event )
	local caster = event.caster
	local target = event.target
	local damage = caster:GetAttackDamage()
	local ability = event.ability
	local AbilityDamageType = ability:GetAbilityDamageType()
	
	-- Don't damage the main target of the attack
	if ability.initial_target ~= target then
		ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = AbilityDamageType })

		ParticleManager:CreateParticle("particles/units/heroes/hero_magnataur/magnus_dust_hit.vpcf", PATTACH_ABSORIGIN, target)
	end
end