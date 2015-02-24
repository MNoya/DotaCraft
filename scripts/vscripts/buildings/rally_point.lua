--[[
	Author: Noya
	Date: 11.02.2015.
	Creates a rally point flag for this unit, removing the old one if there was one
]]
function SetRallyPoint( event )
	local caster = event.caster
	local origin = caster:GetOrigin()
	print(origin)

	-- Ignore pure-research buildings
	if caster:GetUnitName() == "human_lumber_mill" or caster:GetUnitName() == "human_blacksmith" then
		return
	end
	
	-- Need to wait one frame for the building to be properly positioned
	Timers:CreateTimer(0.03, function()

		-- If there's an old flag, remove
		if caster.flag then
			caster.flag:RemoveSelf()
		end

		-- Make a new one
		caster.flag = Entities:CreateByClassname("prop_dynamic")

		-- Find vector towards 0,0,0 for the initial rally point
		origin = caster:GetOrigin()
		local forwardVec = Vector(0,0,0) - origin
		forwardVec = forwardVec:Normalized()

		local point = origin
		if not event.target_points then
			-- For the initial rally point, get point away from the building looking towards (0,0,0)
			point = origin + forwardVec * 220
			DebugDrawCircle(point, Vector(255,255,255), 255, 10, false, 10)
			DebugDrawCircle(point, Vector(255,255,255), 255, 20, false, 10)

			-- Keep track of this position so that every unit is autospawned there (avoids going around the)
			caster.initial_spawn_position = point

			-- Add item ability to change rally point
			local item = CreateItem("item_rally", caster, caster)
			caster:AddItem(item)

		else
			point = event.target_points[1]
			--caster.flag = nil
		end

		local flag_model = "models/particle/legion_duel_banner.vmdl"

		caster.flag:SetAbsOrigin(point)
		caster.flag:SetModel(flag_model)
		caster.flag:SetModelScale(0.7)
		caster.flag:SetForwardVector(forwardVec)

		DebugDrawLine(caster:GetAbsOrigin(), point, 255, 255, 255, false, 10)

		print(caster:GetUnitName().." sets rally point on ",point)
	end)
end

-- Queues a movement command for the spawned unit to the rally point
-- Also adds the unit to the players army and looks for upgrades
function MoveToRallyPoint( event )
	local caster = event.caster
	local target = event.target

	if caster.flag then
		local position = caster.flag:GetAbsOrigin()
		Timers:CreateTimer(0.05, function() target:MoveToPosition(position) end)
		print(target:GetUnitName().." moving to position",position)
	end

	local player = caster:GetPlayerOwner()
	local hero = player:GetAssignedHero()
	target:SetOwner(hero)
	table.insert(player.units, target)
	CheckAbilityRequirements(target, player)
end

function GetInitialRallyPoint( event )
	local caster = event.caster
	local initial_spawn_position = caster.initial_spawn_position

	local result = {}
	if initial_spawn_position then
		table.insert(result,initial_spawn_position)
	else
		print("Fail, no initial rally point, this shouldn't happen")
	end

	return result
end


function DetectRightClick( event )
	local point = event.target_points[1]

	print("####",point)
end