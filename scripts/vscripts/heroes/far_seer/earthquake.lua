--[[
	Author: Noya
	Date: 26.01.2015.
	Creates a dummy unit to apply the Earthquake thinker modifier which does the waves
]]
function EarthquakeStart( event )
	-- Variables
	local caster = event.caster
	local point = event.target_points[1]

	caster.earthquake_dummy = CreateUnitByName("dummy_unit_vulnerable", point, false, caster, caster, caster:GetTeam())
	event.ability:ApplyDataDrivenModifier(caster, caster.earthquake_dummy, "modifier_earthquake_thinker", nil)
end

function EarthquakeEnd( event )
	local caster = event.caster

	caster.earthquake_dummy:RemoveSelf()
end