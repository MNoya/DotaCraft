--[[
	Author: Noya
	Adapted from march_of_the_machines on Spell Library
	Date: 29.01.2015.
	Gets the summoning location for the new unit
]]
function Stampede( event )
	-- Variables
	local caster = event.caster
	local ability = event.ability
	local casterLoc = caster:GetAbsOrigin()
	local point = caster.stampede_point
	local distance = ability:GetLevelSpecialValueFor( "distance", ability:GetLevel() - 1 )
	local spawn_radius = ability:GetLevelSpecialValueFor( "spawn_radius", ability:GetLevel() - 1 )
	local collision_radius = ability:GetLevelSpecialValueFor( "collision_radius", ability:GetLevel() - 1 )
	local projectile_speed = ability:GetLevelSpecialValueFor( "speed", ability:GetLevel() - 1 )
	local lizards_per_sec = ability:GetLevelSpecialValueFor ( "lizards_per_sec", ability:GetLevel() - 1 )
	local dummyModifierName = "modifier_stampede_dummy"

	-- Particle, delayed for animation purposes
	Timers:CreateTimer(0.3, function()
		local particleName = "particles/custom/beastmaster_primal_roar.vpcf"
		local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_cast4_primal_roar", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(particle, 1, point)
	end)

	-- Forward Vector
	forwardVec = caster:GetForwardVector():Normalized()
	
	-- Find middle point of the spawning line backwards
	local middlePoint = casterLoc - ( spawn_radius * forwardVec )
	
	-- Find perpendicular vector
	local v = middlePoint - casterLoc
	local dx = v.y
	local dy = -v.x
	local perpendicularVec = Vector( dx, dy, v.z )
	perpendicularVec = perpendicularVec:Normalized()
	
	-- Create dummy to store data in case of multiple instances are called
	local dummy = CreateUnitByName( "npc_dummy_blank", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber() )
	ability:ApplyDataDrivenModifier( caster, dummy, dummyModifierName, {} )
	dummy.lizards_num = 0
	
	-- Create timer to spawn projectile
	Timers:CreateTimer( function()
			-- Get random location for projectile
			local random_distance = RandomInt( -spawn_radius, spawn_radius )
			local spawn_location = middlePoint + perpendicularVec * random_distance
	
			local velocityVec = Vector( forwardVec.x, forwardVec.y, 0 )
			DebugDrawLine(middlePoint, middlePoint, 255, 0, 0, true, 1)


			-- Spawn projectiles
			local projectileTable = {
				Ability = ability,
				EffectName = "particles/custom/tinker_machine.vpcf",
				vSpawnOrigin = spawn_location,
				fDistance = distance,
				fStartRadius = collision_radius,
				fEndRadius = collision_radius,
				Source = caster,
				bHasFrontalCone = false,
				bReplaceExisting = false,
				bProvidesVision = false,
				iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
				iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_MECHANICAL + DOTA_UNIT_TARGET_BUILDING,
				vVelocity = velocityVec * projectile_speed
			}
			ProjectileManager:CreateLinearProjectile( projectileTable )
			
			-- Increment the counter
			dummy.lizards_num = dummy.lizards_num + 1
			
			-- Check if the number of lizards have been reached
			if dummy.lizards_num == lizards_per_sec then
				dummy:Destroy()
				return nil
			else
				return 1 / lizards_per_sec
			end
		end
	)
end

-- Particle Effect for cast
function StampedeCast( event )
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]

	-- Make the roar particle attack to a far point in front of the hero
	local distance = ability:GetLevelSpecialValueFor( "distance", ability:GetLevel() - 1 ) / 2
	local forwardVec = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
	local front_position = origin + forwardVec * distance

	local particleName = "particles/custom/beastmaster_primal_roar.vpcf"
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_cast4_primal_roar", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(particle, 1, front_position)

	-- Pass the point to the thinker later
	caster.stampede_point = front_position
end