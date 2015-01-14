--[[
	Author: Noya
	Date: 14.1.2015
	Finds the npc_spirit_of_vengeance in the map and kills them
]]
function KillVengeanceSpirits(event)
	local avatar = event.caster
	local kill_radius = 3000 -- This could be higher but might have performance issues

	local units = FindUnitsInRadius(avatar:GetTeamNumber(), avatar:GetAbsOrigin(), avatar, kill_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
						DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, true)

	for _,v in pairs(units) do
		if v:GetUnitName() == "npc_spirit_of_vengeance" then
			v:ForceKill(false)
		end
	end
end