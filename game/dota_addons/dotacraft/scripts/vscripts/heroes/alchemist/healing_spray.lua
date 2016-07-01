--[[
	Author: Noya
	Date: 25.01.2015.
	Creates a dummy unit to apply the HealingSpray thinker modifier which does the waves
]]
function HealingSprayStart( event )
	local caster = event.caster
	local point = event.target_points[1]
	local ability = event.ability

	caster.healing_spray_dummy = CreateUnitByName("dummy_unit_vulnerable", point, false, caster, caster, caster:GetTeam())
	event.ability:ApplyDataDrivenModifier(caster, caster.healing_spray_dummy, "modifier_healing_spray_thinker", nil)
end


function HealingSprayWave( event )
	local caster = event.caster
	local point = event.target:GetAbsOrigin()

	local particleName = "particles/custom/alchemist_acid_spray_cast.vpcf"
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(particle, 1, point)
	ParticleManager:SetParticleControl(particle, 15, Vector(255,255,0))
	ParticleManager:SetParticleControl(particle, 16, Vector(255,255,0))

	local ability = event.ability
	local radius = ability:GetLevelSpecialValueFor("radius",ability:GetLevel()-1)
	local heal = ability:GetLevelSpecialValueFor("wave_heal",ability:GetLevel()-1)
	local allies = FindAllUnitsInRadius(caster, radius, point)
	for _,target in pairs(allies) do
		if not IsCustomBuilding(target) and not target:IsMechanical() then
			local heal = math.min(heal, target:GetHealthDeficit())
			if heal > 0 then
				target:Heal(heal,ability)
				PopupHealing(target, heal)
			end
		end
	end
end

function HealingSprayEnd( event )
	local caster = event.caster

	caster.healing_spray_dummy:RemoveSelf()
end