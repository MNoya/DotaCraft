--[[
	Author: Noya
	Date: 20.01.2015.
	Creates a dummy unit to apply the Volcano thinker modifier which does the waves
]]
function VolcanoStart( event )
	-- Variables
	local caster = event.caster
	local point = event.target_points[1]

	caster.volcano_dummy = CreateUnitByName("firelord_volcano", point, false, caster, caster, caster:GetTeam())
	event.ability:ApplyDataDrivenModifier(caster, caster.volcano_dummy, "modifier_volcano_thinker", nil)
end

function VolcanoEnd( event )
	local caster = event.caster

	caster.volcano_dummy:RemoveSelf()
	caster:StopSound("Hero_EmberSpirit.FlameGuard.Loop")
end

-- Apply modifier knockback to all units except the caster.
function VolcanoKnockback( event )
	local caster = event.caster
	local targets = event.target_entities
	print(#targets)
	local ability = event.ability
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )

	local knockbackModifierTable =
	{
		should_stun = 0,
		knockback_duration = 0.5,
		duration = 0.5,
		knockback_distance = radius/2,
		knockback_height = 20,
		center_x = caster:GetAbsOrigin().x,
		center_y = caster:GetAbsOrigin().y,
		center_z = caster:GetAbsOrigin().z
	}

	for _,unit in pairs(targets) do
		if unit ~= caster then
			print("1")
			unit:AddNewModifier( caster, nil, "modifier_knockback", knockbackModifierTable )
		end
	end			
end


-- Apply damage and stun to all units but the caster
function VolcanoWave( event )
	local caster = event.caster
	local targets = event.target_entities
	print(#targets)
	local ability = event.ability
	local wave_damage = ability:GetLevelSpecialValueFor( "wave_damage", ability:GetLevel() - 1 )
	local stun_duration = ability:GetLevelSpecialValueFor( "stun_duration", ability:GetLevel() - 1 )
	local abilityDamageType = ability:GetAbilityDamageType()


	for _,unit in pairs(targets) do
		if unit ~= caster then
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_volcano_stun", {duration = stun_duration})
			ApplyDamage({ victim = unit, attacker = caster, damage = wave_damage, damage_type = abilityDamageType })
		end
	end			
end