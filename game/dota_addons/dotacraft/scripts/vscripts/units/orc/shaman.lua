function Bloodlust(event)	
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local modelScale = 1 + ability:GetLevelSpecialValueFor('scaling_factor', 0)
	caster:EmitSound('Hero_OgreMagi.Bloodlust.Cast')
	target:EmitSound('Hero_OgreMagi.Bloodlust.Target')
	target:SetModelScale(modelScale)
	ability:ApplyDataDrivenModifier(caster, target, 'modifier_orc_bloodlust', nil) 
end

function BloodlustDelete(event)	
	local target = event.target
	local modelScale = 1
	target:SetModelScale(modelScale)
end