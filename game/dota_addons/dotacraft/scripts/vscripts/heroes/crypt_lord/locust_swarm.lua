--[[
	Author: Noya, BMD
	Date: 25.01.2015.
	Spawns locusts swarms
]]
function LocustSwarmStart( event )
	local caster = event.caster
	local ability = event.ability
	local playerID = caster:GetPlayerID()
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
	local locusts = ability:GetLevelSpecialValueFor( "locusts", ability:GetLevel() - 1 )
	local delay_between_locusts = ability:GetLevelSpecialValueFor( "delay_between_locusts", ability:GetLevel() - 1 )
	local unit_name = "npc_crypt_lord_locust"

	-- Initialize the table to keep track of all locusts
	caster.swarm = {}
	print("Spawning "..locusts.." locusts")
	for i=1,locusts do
		Timers:CreateTimer(i * delay_between_locusts, function()
			local unit = CreateUnitByName(unit_name, caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
			--unit:SetControllableByPlayer(playerID, true)

			-- The modifier takes care of the logic and particles of each unit
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_locust", {})
			
			-- Add the spawned unit to the table
			table.insert(caster.swarm, unit)

			-- Double check to kill the units, remove this later
			Timers:CreateTimer(duration+10, function() if unit and IsValidEntity(unit) then unit:RemoveSelf() end end)
		end)
	end
end

-- Movement logic for each locust
-- Units have 4 states: 
	-- acquiring: transition after completing one target-return cycle.
	-- target_acquired: tracking an enemy or point to collide
	-- returning: After colliding with an enemy, move back to the casters location
	-- end: moving back to the caster to be destroyed
function LocustSwarmPhysics( event )
	local caster = event.caster
	local unit = event.target
	local ability = event.ability
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
	local locusts_speed = ability:GetLevelSpecialValueFor( "locusts_speed", ability:GetLevel() - 1 )
	local locust_damage = ability:GetLevelSpecialValueFor( "locust_damage", ability:GetLevel() - 1 )
	local locust_heal_threshold = ability:GetLevelSpecialValueFor( "locust_heal_threshold", ability:GetLevel() - 1 )
	local max_locusts_on_target = ability:GetLevelSpecialValueFor( "max_locusts_on_target", ability:GetLevel() - 1 )
	local max_distance = ability:GetLevelSpecialValueFor( "max_distance", ability:GetLevel() - 1 )
	local give_up_distance = ability:GetLevelSpecialValueFor( "give_up_distance", ability:GetLevel() - 1 )
	local abilityDamageType = ability:GetAbilityDamageType()
	local abilityTargetType = ability:GetAbilityTargetType()
	local particleName = "particles/units/heroes/hero_weaver/weaver_base_attack_explosion.vpcf"
	local particleNameHeal = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_start_sparks_b.vpcf"

	-- Make the locust a physics unit
	Physics:Unit(unit)

	-- General properties
	unit:PreventDI(true)
	unit:SetAutoUnstuck(false)
	unit:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	unit:FollowNavMesh(false)
	unit:SetPhysicsVelocityMax(locusts_speed)
	unit:SetPhysicsVelocity(locusts_speed * RandomVector(1))
	unit:SetPhysicsFriction(0)
	unit:Hibernate(false)
	unit:SetGroundBehavior(PHYSICS_GROUND_LOCK)

	-- Initial default state
	unit.state = "acquiring"

	-- This is to skip frames
	local frameCount = 0

	-- Store the damage done
	unit.damage_done = 0

	-- Color Debugging for points and paths. Turn it false later!
	local Debug = false
	local pathColor = Vector(255,255,255) -- White to draw path
	local targetColor = Vector(255,0,0) -- Red for enemy targets
	local idleColor = Vector(0,255,0) -- Green for moving to idling points
	local returnColor = Vector(0,0,255) -- Blue for the return
	local endColor = Vector(0,0,0) -- Back when returning to the caster to end
	local draw_duration = 3

	-- Find one target point at random which will be used for the first acquisition.
	local point = caster:GetAbsOrigin() + RandomVector(RandomInt(radius/2, radius))

	-- This is set to repeat on each frame
	unit:OnPhysicsFrame(function(unit)

		-- Current positions
		local source = caster:GetAbsOrigin()
		local current_position = unit:GetAbsOrigin()

		-- Print the path on Debug mode
		if Debug then DebugDrawCircle(current_position, pathColor, 0, 2, true, draw_duration) end

		local enemies = nil

		-- Use this if skipping frames is needed (--if frameCount == 0 then..)
		frameCount = (frameCount + 1) % 3

		-- Movement and Collision detection are state independent

		-- MOVEMENT	
		-- Get the direction
		local diff = point - unit:GetAbsOrigin()
        diff.z = 0
        local direction = diff:Normalized()

		-- Calculate the angle difference
		local angle_difference = RotationDelta(VectorToAngles(unit:GetPhysicsVelocity():Normalized()), VectorToAngles(direction)).y
		
		-- Set the new velocity
		if math.abs(angle_difference) < 5 then
			-- CLAMP
			local newVel = unit:GetPhysicsVelocity():Length() * direction
			unit:SetPhysicsVelocity(newVel)
		elseif angle_difference > 0 then
			local newVel = RotatePosition(Vector(0,0,0), QAngle(0,10,0), unit:GetPhysicsVelocity())
			unit:SetPhysicsVelocity(newVel)
		else		
			local newVel = RotatePosition(Vector(0,0,0), QAngle(0,-10,0), unit:GetPhysicsVelocity())
			unit:SetPhysicsVelocity(newVel)
		end

		-- COLLISION CHECK
		local distance = (point - current_position):Length()
		local collision = distance < 50

		-- MAX DISTANCE CHECK
		local distance_to_caster = (source - current_position):Length()
		if distance > max_distance then 
			unit:SetAbsOrigin(source)
			unit.state = "acquiring" 
		end

		-- STATE DEPENDENT LOGIC
		-- Damage, Healing and Targeting are state dependent.
		-- Update the point in all frames

		-- Acquiring...
		-- Acquiring -> Target Acquired (enemy or idle point)
		-- Target Acquired... if collision -> Acquiring or Return
		-- Return... if collision -> Acquiring

		-- Acquiring finds new targets and changes state to target_acquired with a current_target if it finds enemies or nil and a random point if there are no enemies
		if unit.state == "acquiring" then

			-- If the unit doesn't have a target locked, find enemies near the caster
			enemies = FindUnitsInRadius(caster:GetTeamNumber(), source, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, 
										  abilityTargetType, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

			-- Check the possible enemies, assigning a new one
			local target_enemy = nil
			for _,enemy in pairs(enemies) do

				-- If the enemy this time is different than the last unit.current_target, select it
				-- Also check how many units are locked on this target, if its already max_locusts_on_target, ignore it
				if not enemy.locusts_locked then 
					enemy.locusts_locked = 0 
				end

				if enemy ~= unit.current_target and enemy.locusts_locked < max_locusts_on_target and not target_enemy then
					target_enemy = enemy
					enemy.locusts_locked = enemy.locusts_locked + 1
				end
			end
			
			-- Keep track of it, set the state to target_acquired
			if target_enemy then
				unit.state = "target_acquired"
				unit.current_target = target_enemy
				point = unit.current_target:GetAbsOrigin()
				print("Acquiring -> Enemy Target acquired: "..unit.current_target:GetUnitName())
			
			-- If no enemies, set the unit to collide with a random point.
			else
				unit.state = "target_acquired"
				unit.current_target = nil
				point = source + RandomVector(RandomInt(radius/2, radius))
				print("Acquiring -> Random Point Target acquired")
				if Debug then DebugDrawCircle(point, idleColor, 100, 25, true, draw_duration) end
			end

		-- If the state was to follow a target enemy, it means the unit can perform an attack. 		
		elseif unit.state == "target_acquired" then

			-- Update the point of the target's current position
			if unit.current_target then
				point = unit.current_target:GetAbsOrigin()
				if Debug then DebugDrawCircle(point, targetColor, 100, 25, true, draw_duration) end
			end

			-- Give up on the target if the distance goes over the give_up_distance
			if distance_to_caster > give_up_distance then
				unit.state = "acquiring"
				print("Gave up on the target, acquiring a new target.")

				-- Decrease the locusts_locked counter
				unit.current_target.locusts_locked = unit.current_target.locusts_locked - 1				
			end

			-- Do physical damage here, and increase heal counter. 
			-- Also set to come back to the caster if the locust_heal_threshold has been dealt
			if collision then

				-- If the target was an enemy and not a point, the unit collided with it
				if unit.current_target ~= nil then
					
					-- Damage, units will still try to collide with attack immune targets but the damage wont be applied
					if not unit.current_target:IsAttackImmune() then
						local damage_table = {}

						damage_table.victim = unit.current_target
						damage_table.attacker = caster					
						damage_table.damage_type = abilityDamageType
						damage_table.damage = locust_damage

						ApplyDamage(damage_table)

						-- Calculate how much physical damage was dealt
						local targetArmor = unit.current_target:GetPhysicalArmorValue()
						local damageReduction = ((0.06 * targetArmor) / (1 + 0.06 * targetArmor))
						local damagePostReduction = locust_damage * (1 - damageReduction)
						--print(locust_damage, damageReduction, damagePostReduction)

						unit.damage_done = unit.damage_done + damagePostReduction

						-- Damage particle
						local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, unit.current_target)
						ParticleManager:SetParticleControl(particle, 0, unit.current_target:GetAbsOrigin())
						ParticleManager:SetParticleControlEnt(particle, 3, unit.current_target, PATTACH_POINT_FOLLOW, "attach_hitloc", unit.current_target:GetAbsOrigin(), true)

						-- Fire Sound on the target unit
						unit.current_target:EmitSound("Hero_Weaver.SwarmAttach")
						
						-- Decrease the locusts_locked counter
						unit.current_target.locusts_locked = unit.current_target.locusts_locked - 1
					end

					-- Send the unit back to return, or keep attacking new targets
					if unit.damage_done >= locust_heal_threshold then
						unit.state = "returning"
						point = source
						print("Returning to caster after dealing ",unit.damage_done)
					else
						unit.state = "acquiring"
						print("Attacked but still needs more damage to return: ",unit.damage_done)
					end

				-- In other case, its a point, reacquire target
				else
					unit.state = "acquiring"
					print("Attempting to acquire a new target")
				end
			end

		-- If it was a collision on a return (meaning it reached the caster), change to acquiring so it finds a new target
		-- Also heal the caster on each return of a locust
		elseif unit.state == "returning" then
			
			-- Update the point to the caster's current position
			point = source
			if Debug then DebugDrawCircle(point, returnColor, 100, 25, true, draw_duration) end

			if collision then 
				unit.state = "acquiring"

				caster:Heal(locust_heal_threshold, ability)
				print("Healed")

				-- Heal particle
				local particle = ParticleManager:CreateParticle(particleNameHeal, PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())

				-- Reset the damage done
				unit.damage_done = 0
			end	

		-- if set the state to end, the point is also the caster position, but the units will be removed on collision
		elseif unit.state == "end" then
			point = source
			if Debug then DebugDrawCircle(point, endColor, 100, 25, true, 2) end

			-- Last collision ends the unit
			if collision then 
				unit:SetPhysicsVelocity(Vector(0,0,0))
	        	unit:OnPhysicsFrame(nil)
	        	unit:RemoveSelf()

	        	-- Double check to reset all locusts_locked counters when the ability ends
				enemies = FindUnitsInRadius(caster:GetTeamNumber(), source, nil, max_distance, DOTA_UNIT_TARGET_TEAM_ENEMY, 
										  abilityTargetType, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				
				for _,v in pairs(enemies) do
					v.locusts_locked = 0
				end
	        end
	    end
    end)
end

-- Change the state to end when the modifier is removed
function LocustSwarmEnd( event )
	local caster = event.caster
	local targets = caster.swarm
	print("LocustSwarmEnd")
	for _,unit in pairs(targets) do		
	   	if unit and IsValidEntity(unit) then
    	  	unit.state = "end"
    	end
	end
end

-- Kill all units when the owner dies
function LocustSwarmDeath( event )
	local caster = event.caster
	local targets = caster.swarm
	local particleName = "particles/units/heroes/hero_weaver/weaver_base_attack_explosion.vpcf"

	print("LocustSwarmDeath")
	for _,unit in pairs(targets) do		
	   	if unit and IsValidEntity(unit) then
    	  	unit:SetPhysicsVelocity(Vector(0,0,0))
	        unit:OnPhysicsFrame(nil)

	        -- Explosion particle
			local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, unit)
			ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
			ParticleManager:SetParticleControlEnt(particle, 3, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)

			-- Kill
			unit.no_corpse = true
	        unit:ForceKill(false)
    	end
	end
end