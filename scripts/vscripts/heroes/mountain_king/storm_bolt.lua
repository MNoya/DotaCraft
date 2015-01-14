--[[
	Author: Noya
	Date: 13.1.2015.
	Applies Creep or Hero duration depending on the target
]]
function StormBoltApply( event )
	-- Variables
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local hero_duration = ability:GetLevelSpecialValueFor( "stun_hero_duration" , ability:GetLevel() - 1  )
	local creep_duration = ability:GetLevelSpecialValueFor( "stun_creep_duration" , ability:GetLevel() - 1  )

	if target:IsRealHero() or target:IsIllusion() then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_storm_bolt", { duration  = hero_duration})
	else
		ability:ApplyDataDrivenModifier(caster, target, "modifier_storm_bolt", { duration  = creep_duration})
	end
end