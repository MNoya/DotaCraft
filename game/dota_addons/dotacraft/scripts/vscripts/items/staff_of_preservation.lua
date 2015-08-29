function Teleport( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	if target == caster then
		SendErrorMessage(caster:GetPlayerID(), "error_cant_target_self")
		ability:EndCooldown()
	elseif target:GetPlayerOwner() ~= caster:GetPlayerOwner() then
		SendErrorMessage(caster:GetPlayerID(), "error_cant_target_friendly")
		ability:EndCooldown()
	else
		local city_center = FindHighestLevelCityCenter(target)
		caster:EmitSound("Hero_Chen.TeleportOut")
		ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_test_of_faith.vpcf", PATTACH_ABSORIGIN, target)
		FindClearSpaceForUnit(target, city_center:GetAbsOrigin(), true)
	end
end