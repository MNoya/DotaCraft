function ApplyConstructionEffect( event )
	local ability = event.ability
	local target = event.target

	local race = GetUnitRace(target)

	if race == "orc" then
		target.construction_particle = ParticleManager:CreateParticle("particles/custom/construction_dust.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	elseif race ~= "human" then
		ability:ApplyDataDrivenModifier(target, target, "modifier_construction_"..race, {})
	end
end

function RemoveConstructionEffect( event )
	local target = event.target

	local race = GetUnitRace(target)
	target:RemoveModifierByName("modifier_construction_"..race)

	if target.construction_particle then 
		ParticleManager:DestroyParticle(target.construction_particle, true)
		target.construction_particle = nil
	end	
end

function NightElfConstructionParticle( event )
	local target = event.target
	target.construction_particle = ParticleManager:CreateParticle("particles/custom/nightelf/lucent_beam_impact_shared_ti_5.vpcf", PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControl(target.construction_particle, 0, target:GetAbsOrigin())
end

function NightElfConstructionParticleEnd( event )
	local target = event.target
	if target and target.construction_particle then
		ParticleManager:DestroyParticle(target.construction_particle, true)
	end
end