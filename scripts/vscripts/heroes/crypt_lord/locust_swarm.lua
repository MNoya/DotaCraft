--[[<func_door> I think thats just what happens when you send them back and forth with momentum involved
<Noya> its a elipse with random points and random "width"
<BMD> spirits have 3 states, target_acquired, returning, and idle
<BMD> exactly func_door
<BMD> there's no elliptical calculation here
<BMD> just an application of acceleration according to the state given
<func_door> because the spirits have to return to the caster between each "attack"
<BMD> with a maximum velocity
<BMD> yeah
<BMD> spirits acquire a random valid target within 700 range
<Noya> and actually if you look at them, its not even 0.03 frames lol
<Noya> its very choppy
<BMD> if they are in idle state
<func_door> yeah I've noticed the spirits can be pretty choppy
<Noya> their "turn-rate" is awful in idle
<BMD> and they then enter target_acquired
<BMD> and get an acceleration towards that targetg
<BMD> which adjusts in direction to keep it towards them
<BMD> but not in magnitude
<BMD> that rotates them out of their current idling trajectory
<Noya> when the spell starts, if there are no targets, the spirits try to go to the max range possible
<BMD> once they connect with the target, or it dies or gets out of range
<BMD> they reacquire a target
<BMD> though if they connect then they go into returning
<BMD> where they aim for a random point within about 200 ish of DP
<BMD> once reaching it they reenter idle
<BMD> and idle behavior is just acquisition seeking plus randomized point selection and acceleration around DP
<Noya> yeah it select points, then circles between them
<Noya> some spirits just circle over the same path many times
<BMD> yep
<BMD> they'
<BMD> they're likely given a point series relative to DP's position
<BMD> that they run throuhg
<BMD> but really idling doesn't matter that much, it's mainly just making sure the ghosts don't get lost while idling
<BMD> so they keep up with DP and disappear/respawn when she goes over 2000 away
<BMD> otherwise they can just jiggle around her like idiots
<BMD> but acquired target and returning are more important, though also more simple it seems
<Noya> wait is there actually AI tied to the hero autoattack?
<Noya> I don't seem to notice it
<Noya> i have a single enemy, cast exorcism, target an attack to it
<Noya> meh I guess there is, but as its just 700 range it doesn't matter
<Noya> need more targets
<BMD> yeah if they're outside the autoacquisition range they prioritize the right clicked target it sees
<BMD> seems
<BMD> and there are some things that they won't attack if you don't
<BMD> like healing wards, observer wards, etc
<Noya> there's modifier_death_prophet_exorcism _start_spirit_duration and _start_time
<Noya> the start_time is probaby the spawning, as they dont spawn all at the same time
<Noya> and yes they totally focus the right clicked target
<BMD> yeah each spirit spawns .1 seconds apart supposedly
<Noya> but still keep the physics momentum of attack-return
<BMD> yep
<Noya> locust swarm wc3 its 0.2
<BMD> i don't believe they reacquire
<BMD> like if you have two targets and they auto select 1
<BMD> and you right click the other
<BMD> i think they have to finish their attack
<BMD> or lose it to death/out of range
<BMD> oh i guess there's a 4th state which is return_to_die or whatever
<BMD> when it times out
<BMD> the spirit has to go right back and heal up DP]]

--[[
	Author: Noya
	Date: 25.01.2015.
	Spawns locusts swarms
]]
function LocustSwarmStart( event )
	local caster = event.caster
	local ability = event.ability
	local playerID = caster:GetPlayerID()
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
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
			Timers:CreateTimer(20, function() if unit and IsValidEntity(unit) then unit:RemoveSelf() end end)
		end)
	end
end

-- Movement logic for each locust
-- Spirits have 3 states: target_acquired, returning and idle
function LocustSwarmPhysics( event )
	local caster = event.caster
	local unit = event.target
	local ability = event.ability
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
	local locusts_speed = ability:GetLevelSpecialValueFor( "locusts_speed", ability:GetLevel() - 1 )

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
	unit.state = "idle"

	-- This is to skip frames
	local frameCount = 0

	-- This is set to repeat on each frame
	unit:OnPhysicsFrame(function(unit)

		-- Skip frames for the state check
		frameCount = (frameCount + 1) % 3

		-- Current positions
		local source = caster:GetAbsOrigin()
		local current_position = unit:GetAbsOrigin()
		DebugDrawCircle(current_position, Vector(255,0,0), 0, 5, true, 10)

		local point = current_position

		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), source, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, 
										  DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		-- Get a Point for idling and mark it
		if unit.state == "idle" then
			point = source + RandomVector(RandomInt(radius/2, radius))
			DebugDrawCircle(point, Vector(0,0,255), 0, 10, true, duration)
			unit.state = "target_acquired"
		end

		if unit.state == "target_acquired" then
			if frameCount == 0 then
				-- Get the direction
				local diff = point - unit:GetAbsOrigin()
		        diff.z = 0
		        local direction = diff:Normalized()

				-- Calculate the angle difference
				local angle_difference = math.abs(RotationDelta(VectorToAngles(unit:GetPhysicsVelocity():Normalized()), VectorToAngles(direction)).y)
				
				-- Set the new velocity
				if angle_difference > 0 then
					local newVel = RotatePosition(Vector(0,0,0), QAngle(0,15,0), unit:GetPhysicsVelocity())
					unit:SetPhysicsVelocity(newVel)
				else		
					local newVel = RotatePosition(Vector(0,0,0), QAngle(0,-15,0), unit:GetPhysicsVelocity())
					unit:SetPhysicsVelocity(newVel)
				end
			end
		end

		-- Stop if set the state to end and reached the caster
		if unit.state == "end" then

		    -- Retarget acceleration vector
		    local distance = source - current_position
		    local direction = distance:Normalized()
		    unit:SetPhysicsAcceleration(direction * 500)
		      
		    -- Stop if reached the unit
		    if distance:Length() < 100 then
		        unit:SetPhysicsAcceleration(Vector(0,0,0))
		        unit:SetPhysicsVelocity(Vector(0,0,0))
		        unit:OnPhysicsFrame(nil)
		        unit:RemoveSelf()
		        print(distance:Length(),"removed")
		    end
        end
    end)

end

-- 4th state is returning to the caster to end the ability
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

