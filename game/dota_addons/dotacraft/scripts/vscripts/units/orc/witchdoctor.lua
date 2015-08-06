function SentryStart( event )
	local caster = event.caster
	local ability = event.ability
	local target_point = event.target_points[1]
	local duration = ability:GetSpecialValueFor('duration') 
	local sentry = CreateUnitByName('orc_sentry_ward_unit', target_point, true, caster, caster, caster:GetTeamNumber())
	sentry:AddNewModifier(sentry, nil, "modifier_kill", {duration = duration})
	sentry:AddNewModifier(sentry, nil, "modifier_invisible", {duration = .1})
	ability:ApplyDataDrivenModifier(sentry, sentry, 'modifier_orc_sentry_ward', nil)
end

function SentrySight( event )
	local caster = event.caster
	local ability = event.ability
	caster:AddNewModifier(caster, nil, "modifier_invisible", {duration = .1})
	local radius = ability:GetSpecialValueFor('radius') 
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(caster, ability, 'modifier_truesight', {duration = '0.5'}) 
	end
end