function Teleport( event )
	local caster = event.caster
	local target = event.target
	if target == caster then
		SendErrorMessage(caster:GetPlayerID(), "error_cant_target_self")
	else
		local city_center = FindHighestLevelCityCenter(target)
		ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_test_of_faith.vpcf", PATTACH_ABSORIGIN, target)
		FindClearSpaceForUnit(target, city_center:GetAbsOrigin(), true)
	end
end

function HealCheck( event )
	local target = event.target
	if target:GetHealthDeficit() == 0 then
		target:RemoveModifierByName("modifier_staff_of_sanctuary_heal")
	end
end