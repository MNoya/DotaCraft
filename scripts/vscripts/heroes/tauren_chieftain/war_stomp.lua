--[[
	Author: Noya
	Date: 13.1.2015.
	Applies Creep or Hero duration to targets in a radius depending on unit type
]]
function WarStompApply( event )
	-- Variables
	local caster = event.caster
	local targets = event.target_entities
	local ability = event.ability
	local hero_duration = ability:GetLevelSpecialValueFor( "stun_hero_duration" , ability:GetLevel() - 1  )
	local creep_duration = ability:GetLevelSpecialValueFor( "stun_creep_duration" , ability:GetLevel() - 1  )

	for _,target in pairs(targets) do
		if target:IsRealHero() or target:IsIllusion() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_war_stomp", { duration  = hero_duration})
		else
			ability:ApplyDataDrivenModifier(caster, target, "modifier_war_stomp", { duration  = creep_duration})
		end
	end
end

