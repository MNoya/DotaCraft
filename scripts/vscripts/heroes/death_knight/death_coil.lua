
function death_coil_precast( event )
	if event.target == event.caster then
		event.caster:Interrupt() 
	end
end

function death_coil_cast( event )
	print("hello")
end

function death_coil_hit( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local damage = ability:GetLevelSpecialValueFor( "target_damage" , ability:GetLevel() - 1 )
	local heal = ability:GetLevelSpecialValueFor( "heal_amount" , ability:GetLevel() - 1 )
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL })
	else
		target:Heal( heal, caster)
	end
end
