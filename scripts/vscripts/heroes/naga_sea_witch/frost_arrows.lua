--[[
	Author: Noya
	Date: 13.1.2015.
	Applies Creep or Hero duration depending on the target
]]
function FrostArrowsApply( event )
	-- Variables
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local hero_duration = ability:GetLevelSpecialValueFor( "slow_hero_duration" , ability:GetLevel() - 1  )
	local creep_duration = ability:GetLevelSpecialValueFor( "slow_creep_duration" , ability:GetLevel() - 1  )

	if target:IsRealHero() or target:IsIllusion() then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_frost_arrows_slow", { duration  = hero_duration})
	else
		ability:ApplyDataDrivenModifier(caster, target, "modifier_frost_arrows_slow", { duration  = creep_duration})
	end
end