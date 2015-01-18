--[[
	Author: Noya
	Date: 18.01.2015.
	Checks if the target has the modifier_drunken_haze to apply a burn modifier
]]
function BreathFire( event )
	-- Variables
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	if target:HasModifier("modifier_drunken_haze") then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_breath_fire_burn", {})
	end
end