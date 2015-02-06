--[[
	Author: Noya
	Date: 20.01.2015.
	Creates a dummy unit to apply the Volcano thinker modifier which does the waves
]]
function VolcanoStart( event )
	-- Variables
	local caster = event.caster
	local point = event.target_points[1]

	caster.volcano_dummy = CreateUnitByName("dummy_unit_vulnerable", point, false, caster, caster, caster:GetTeam())
	event.ability:ApplyDataDrivenModifier(caster, caster.volcano_dummy, "modifier_volcano_thinker", nil)
end

function VolcanoEnd( event )
	local caster = event.caster

	caster.volcano_dummy:RemoveSelf()
end