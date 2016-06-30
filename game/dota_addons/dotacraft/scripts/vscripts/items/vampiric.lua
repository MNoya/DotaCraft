function LifestealApply( event )
	local attacker = event.attacker
	local target = event.target
	local ability = event.ability

	local isBuilding = target:FindAbilityByName("ability_building")
	if not isBuilding == nil and not target:IsMechanical() then
		ability:ApplyDataDrivenModifier(attacker, attacker, "modifier_vampiric_aura_lifesteal", {duration = 0.03})
	end
end