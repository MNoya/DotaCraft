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
	local locusts = 1--ability:GetLevelSpecialValueFor( "locusts", ability:GetLevel() - 1 )
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
			Timers:CreateTimer(duration+20, function() if unit and IsValidEntity(unit) then unit:RemoveSelf() end end)
		end)
	end
end

-- Movement logic for each locust
-- Units have 4 main states: 
	-- acquiring: transition after completing one target-return cycle.
	-- target_acquired: tracking an enemy to collide and deal damage to it
	-- returning: After colliding with an enemy, move back to the casters location
	-- idle: When no enemy is found, just go to a random point
function LocustSwarmPhysics( event )
	local caster = event.caster
	local unit = event.target
	local ability = event.ability
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
	local locusts_speed = ability:GetLevelSpecialValueFor( "locusts_speed", ability:GetLevel() - 1 )
	local locust_damage = ability:GetLevelSpecialValueFor( "locust_damage", ability:GetLevel() - 1 )
	local locust_heal_threshold = ability:GetLevelSpecialValueFor( "locust_heal_threshold", ability:GetLevel() - 1 )
	local abilityDamageType = ability:GetAbilityDamageType()
	local abilityTargetType = ability:GetAbilityTargetType()

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

	-- Initial default state
	unit.state = "acquiring"

	-- This is to skip frames
	local frameCount = 0

	-- Store the damage done
	unit.damage_done = 0

	-- Color Debugging for points and paths. Turn it false later!
	local Debug = true
	local pathColor = Vector(255,255,255) -- White to draw 
	local targetColor = Vector(255,0,0) -- Red for enemy targets
	local idleColor = Vector(0,255,0) -- Green for moving to idling points
	local returnColor = Vector(0,0,255) --
	local endColor = Vector(0,0,0) -- Back when returning to the caster to end
	local draw_duration = 3

	-- Find one target point at random which will be used for the first acquisition.
	point = caster:GetAbsOrigin() + RandomVector(RandomInt(radius/2, radius))

	-- This is set to repeat on each frame
	unit:OnPhysicsFrame(function(unit)

		-- Skip frames for the state check
		frameCount = (frameCount + 1) % 3

		-- Current positions
		local source = caster:GetAbsOrigin()
		local current_position = unit:GetAbsOrigin()

		-- Print the path on Debug mode
		if Debug then DebugDrawCircle(current_position, pathColor, 0, 2, true, draw_duration) end

		local enemies = nil
		local target_enemy = nil

		-- TARGETING
		-- If the unit doesn't have a target locked, find enemies near the caster
		if unit.state == "acquiring" then
			enemies = FindUnitsInRadius(caster:GetTeamNumber(), source, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, 
										  abilityTargetType, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			print(abilityTargetType)

			-- Select one enemy if we found one
			if (#enemies) > 0 then
				target_enemy = enemies[RandomInt(1, #enemies)]
			end

			-- Keep track of it
			if target_enemy then
				unit.state = "target_acquired"
				unit.current_target = target_enemy
				print("Target acquired ->",unit.current_target:GetUnitName())
			
			-- If no enemies, set the unit to idle.
			else
				unit.state = "idle"
				unit.current_target = nil
				print("No Target found, idling")
				
				-- It will go to a random position and then return, to acquire a new target on the next loop
				-- As we are sure this point won't be moved, we don't need to update it on each frame, just once every cycle.
				point = caster:GetAbsOrigin() + RandomVector(RandomInt(radius/2, radius))

				-- Mark this point. The duration has to be longer, becase this isn't updated on each frame
				if Debug then DebugDrawCircle(point, idleColor, 100, 25, true, draw_duration*5) end
			end
		end
		
		-- We need this somewhere:
		--if dist > 2000 then setabsorigin(caster absorigbin); state = idle end
		--in acquisition it's if dist > 1200 then state = returning

		-- MOVEMENT
		if frameCount == 0 then

			-- Update the point
			-- if target_acquired, the point is the target's current position
			if unit.state == "target_acquired" then
				point = unit.current_target:GetAbsOrigin()
				if Debug then DebugDrawCircle(point, targetColor, 100, 25, true, draw_duration) end

			-- if returning, the point is the caster's current position
			elseif unit.state == "returning" then
				point = source
				if Debug then DebugDrawCircle(point, returnColor, 100, 25, true, draw_duration) end
			
			-- if set the state to end, the point is also the caster position, but the units won't acquire new targets after colliding.
			elseif unit.state == "end" then
				point = source
				DebugDrawCircle(point, endColor, 100, 25, true, 2)			   
	        end

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
		end

		-- COLLISION
		-- Check if enemy near enough + unit attack target to acquire target
		-- Switch state and dump out on acquire
		local dist = (point - current_position):Length()
		local collision = dist < 50

		-- If the unit collided with target position, change the state accordingly
		if collision then

			-- If the state is idle, it reached the desired random point.
			-- Here we allow reacquiring a target
			if unit.state == "idle" then
				unit.state = "acquiring"
				print("Attempting to acquire a new target")
			
			-- If the state was to follow a target enemy, it means the unit can perform an attack. 
			-- Do physical damage here, and increase heal counter. 
			-- Also set to come back to the caster if the locust_heal_threshold has been dealt
			elseif unit.state == "target_acquired" then

				-- Fire Sound on the target unit
				unit.current_target:EmitSound("Hero_Weaver.SwarmAttach"	)

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
					print(locust_damage, damageReduction, damagePostReduction)

					unit.damage_done = unit.damage_done + damagePostReduction	
				end

				-- Send the unit back to return, or keep attacking new targets
				if unit.damage_done >= locust_heal_threshold then
					unit.state = "returning"
					print("Returning to caster after dealing ",unit.damage_done)
				else
					unit.state = "acquiring"
					print("Locust attacked but still needs more damage to return back to the caster: ",unit.damage_done)
				end

			-- If it was a collision on a return (meaning it reached the caster), change to acquiring so it finds a new target
			-- Also heal the caster on each return of a locust
			elseif unit.state == "returning" then
				unit.state = "acquiring"

				caster:Heal(locust_heal_threshold, ability)
				print("Healed")

				-- Reset the damage done
				unit.damage_done = 0
			
			-- Last collision ends the unit
			elseif unit.state == "end" then
				unit:SetPhysicsVelocity(Vector(0,0,0))
		        unit:OnPhysicsFrame(nil)
		        unit:RemoveSelf()
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

