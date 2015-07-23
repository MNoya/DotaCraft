function Bloodlust(event)	
	local target = event.target
	local ability = event.ability
	local modelScale = 1 + ability:GetLevelSpecialValueFor('scaling_factor', 0)
	target:SetModelScale(modelScale)
	ability:ApplyDataDrivenModifier(caster, target, 'modifier_orc_bloodlust', nil) 
end