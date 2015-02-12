--[[
	Author: Noya
	Date: 11.02.2015.
	Creates a rally point flag for this unit, removing the old one if there was one
]]
function SetRallyPoint( event )
	local caster = event.caster
	local point = event.target_points[1]

	local flag_model = "models/particle/legion_duel_banner.vmdl"

	if caster.flag then
		caster.flag:RemoveSelf()
	end

	caster.flag = Entities:CreateByClassname("prop_dynamic")
	caster.flag:SetAbsOrigin(point)
	caster.flag:SetModel(flag_model)
	caster.flag:SetModelScale(0.7)
	DebugDrawLine(caster:GetAbsOrigin(), point, 255, 255, 255, false, 10)

	print(caster:GetUnitName().." sets rally point on ",point)
end

--[[
	Author: Noya
	Date: 11.02.2015.
	Queues a movement command for the spawned unit to the rally point
]]
function MoveToRallyPoint( event )
	local caster = event.caster
	local target = event.target

	if caster.flag then
		local position = caster.flag:GetAbsOrigin()
		Timers:CreateTimer(0.05, function() target:MoveToPosition(position) end)
		print(target:GetUnitName().." moving to position",position)
	end
end