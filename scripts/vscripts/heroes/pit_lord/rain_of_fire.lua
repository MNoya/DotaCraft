--[[
	Author: Noya
	Date: 20.01.2015.
	Creates a dummy unit to apply the Rain of Fire thinker modifier which does the waves
]]
function RainOfFireStart( event )
	-- Variables
	local caster = event.caster
	local point = event.target_points[1]

	caster.fire_storm_dummy = CreateUnitByName("dummy_unit_vulnerable", point, false, caster, caster, caster:GetTeam())
	event.ability:ApplyDataDrivenModifier(caster, caster.fire_storm_dummy, "modifier_rain_of_fire_thinker", nil)
end

function RainOfFireEnd( event )
	local caster = event.caster

	caster.fire_storm_dummy:RemoveSelf()
end