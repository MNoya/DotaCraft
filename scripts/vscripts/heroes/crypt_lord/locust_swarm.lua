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
	local locusts = ability:GetLevelSpecialValueFor( "locusts", ability:GetLevel() - 1 )
	local delay_between_locusts = ability:GetLevelSpecialValueFor( "delay_between_locusts", ability:GetLevel() - 1 )
	local locusts_speed = ability:GetLevelSpecialValueFor( "locusts_speed", ability:GetLevel() - 1 )
	local unit_name = "npc_crypt_lord_locust"

	-- Initialize the table to keep track of all locusts
	caster.swarm = {}

	for i=1,locusts do
		Timers:CreateTimer(i * delay_between_locusts, function()
			local locust = CreateUnitByName(unit_name, caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
			--locust:SetControllableByPlayer(playerID, true)

			-- Make the locust a physics unit
			Physics:Unit(locust)

			locust:PreventDI(true)
    		locust:SetAutoUnstuck(false)
    		locust:SetNavCollisionType(PHYSICS_NAV_NOTHING)
    		locust:FollowNavMesh(false)
    		locust:SetPhysicsVelocityMax(500)

			-- Add the spawned unit to the table
			table.insert(caster.swarm, locust)
		end)
	end
end


function LocustSwarmEnd( event )
	local caster = event.caster
	local targets = caster.swarm

	for _,unit in pairs(targets) do		
	   	if unit and IsValidEntity(unit) then
    	  	unit:MoveToNPC(caster)
    	end
	end
end