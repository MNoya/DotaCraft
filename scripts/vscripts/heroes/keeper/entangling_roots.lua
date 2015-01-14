--[[
	Author: Noya
	Date: 13.1.2015.
	Applies Creep or Hero duration depending on the target
]]
function EntanglingRootsCheck( event )
	-- Variables
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local hero_duration = ability:GetLevelSpecialValueFor( "hero_duration" , ability:GetLevel() - 1  )
	local creep_duration = ability:GetLevelSpecialValueFor( "creep_duration" , ability:GetLevel() - 1  )

	if target:IsRealHero() or target:IsIllusion() then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_entangling_roots", { duration  = hero_duration})
	else
		ability:ApplyDataDrivenModifier(caster, target, "modifier_entangling_roots", { duration  = creep_duration})
	end
end