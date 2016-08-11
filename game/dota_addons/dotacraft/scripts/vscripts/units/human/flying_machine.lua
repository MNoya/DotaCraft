-- Removes the ground attack restriction
function UnlockGroundAttack( event )
	local caster = event.caster
	caster:SetAttacksEnabled("ground, air")
end

-- Launches projectiles at units in radius of the main target
function FireFlakCannons( event )
	local caster = event.caster
	local ability = event.ability
	local target = event.target -- The target of the attack
	local position = target:GetAbsOrigin()
	caster.flak_cannon_target = target -- Keep track of the main target
	
	local medium_damage_radius = event.MediumRadius
	local enemies_medium = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, medium_damage_radius, 
						   DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	
	for _,enemy in pairs(enemies_medium) do
		if enemy:HasFlyMovementCapability() and enemy ~= target then
			local projTable = {
				EffectName = "particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_base_attack.vpcf",
				Ability = ability,
				Target = enemy,
				Source = caster,
				bDodgeable = true,
				bProvidesVision = false,
				vSpawnOrigin = caster:GetAbsOrigin(),
				iMoveSpeed = 2000,
				iVisionRadius = 0,
				iVisionTeamNumber = caster:GetTeamNumber(),
				iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
			}
			ProjectileManager:CreateTrackingProjectile( projTable )
		end
	end
end

-- Deals damage based on the distance from the main target
function FlakCannonDamage( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local medium_damage_radius = ability:GetSpecialValueFor("medium_damage_radius")
	local small_damage_radius = ability:GetSpecialValueFor("small_damage_radius")

	-- Get the distance and adjust the damage
	local flak_cannon_target = caster.flak_cannon_target
	local distance = (target:GetAbsOrigin() - flak_cannon_target:GetAbsOrigin()):Length()

	local flak_damage = caster:GetAverageTrueAttackDamage()
	if distance < medium_damage_radius then
		flak_damage = flak_damage / 2
	else
		flak_damage = flak_damage / 4
	end

	ApplyDamage({ victim = target, attacker = caster, damage = flak_damage, damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES}) 
end