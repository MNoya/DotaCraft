function AttackGround( event )
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]
	local start_time = caster:GetAttackAnimationPoint() -- Time to wait to fire the projectile
	local speed = caster:GetProjectileSpeed()
	local particle = "particles/econ/items/luna/luna_eternal_eclipse/luna_glaive_eternal_eclipse.vpcf"
	local minimum_range = ability:GetSpecialValueFor("minimum_range")

	if (point - caster:GetAbsOrigin()):Length() < minimum_range then
		SendErrorMessage(caster:GetPlayerOwnerID(), "#error_minimum_range")
		caster:Interrupt()
		return
	end

	ToggleOn(ability)

	-- Create a dummy to fake the attacks
	if IsValidEntity(ability.attack_ground_dummy) then ability.attack_ground_dummy:RemoveSelf() end
	ability.attack_ground_dummy = CreateUnitByName("dummy_unit", point, false, nil, nil, DOTA_TEAM_NEUTRALS)

	ability.attack_ground_timer = Timers:CreateTimer(function()
		caster:StartGesture(ACT_DOTA_ATTACK)
		ability.attack_ground_timer_animation = Timers:CreateTimer(start_time, function() 
			local projectileTable = {
				EffectName = particle,
				Ability = ability,
				Target = ability.attack_ground_dummy,
				Source = caster,
				bDodgeable = true,
				bProvidesVision = true,
				vSpawnOrigin = caster:GetAbsOrigin(),
				iMoveSpeed = 900,
				iVisionRadius = 100,
				iVisionTeamNumber = caster:GetTeamNumber(),
				iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
			}
			ProjectileManager:CreateTrackingProjectile( projectileTable )

		end)
		local time = 1 / caster:GetAttacksPerSecond()	
		return 	time
	end)

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_attacking_ground", {})
end

function AttackGroundDamage( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local position = target:GetAbsOrigin()
	local damage = caster:GetAttackDamage()
	local splash_radius = ability:GetSpecialValueFor("splash_radius")
	local AbilityDamageType = ability:GetAbilityDamageType()

	if caster:HasAbility("nightelf_vorpal_blades") then
		local damage_to_trees = caster:FindAbilityByName("nightelf_vorpal_blades"):GetSpecialValueFor("damage_to_trees")
		local trees = GridNav:GetAllTreesAroundPoint(position, 100, true)

		for _,tree in pairs(trees) do
			if tree:IsStanding() then
				tree.health = tree.health - damage_to_trees

				-- Hit tree particle
				local particleName = "particles/custom/tree_pine_01_destruction.vpcf"
				local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
				ParticleManager:SetParticleControl(particle, 0, tree:GetAbsOrigin())
			end
			if tree.health <= 0 then
				tree:CutDown(caster:GetPlayerOwnerID())
			end
		end
	end

	-- Hit ground particle
	ParticleManager:CreateParticle("particles/units/heroes/hero_magnataur/magnus_dust_hit.vpcf", PATTACH_ABSORIGIN, target)

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, splash_radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _,enemy in pairs(enemies) do
		ApplyDamage({ victim = enemy, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL })
	end
	
end

function StopAttackGround( event )
	local caster = event.caster
	local ability = event.ability

	if IsValidEntity(ability.attack_ground_dummy) then ability.attack_ground_dummy:RemoveSelf() end

	Timers:RemoveTimer(ability.attack_ground_timer)
	Timers:RemoveTimer(ability.attack_ground_timer_animation)

	ToggleOff(ability)

	caster:RemoveGesture(ACT_DOTA_ATTACK)

end

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
		-- Adjust by damage type
		damage = damage * GetDamageForAttackAndArmor( GetAttackType(caster), GetArmorType(target) )

		ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = AbilityDamageType })
		print("Vorpal Blade dealt "..damage.." to "..target:GetUnitName().." number ".. target:GetEntityIndex())

		ParticleManager:CreateParticle("particles/units/heroes/hero_magnataur/magnus_dust_hit.vpcf", PATTACH_ABSORIGIN, target)
	end
end