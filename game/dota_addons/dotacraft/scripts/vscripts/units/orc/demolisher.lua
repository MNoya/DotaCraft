function BurningOil( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local duration = ability:GetSpecialValueFor("duration")
	caster.burning_oil_dummy = CreateUnitByName("dummy_unit", target:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, caster.burning_oil_dummy, "modifier_burning_oil_thinker", {duration=duration})
	Timers:CreateTimer(duration, function()
		UTIL_Remove(caster.burning_oil_dummy)
	end)
end