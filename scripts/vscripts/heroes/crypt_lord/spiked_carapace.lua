--[[
	Author: Noya
	Date: 17.1.2015.
	OnAttacked, register the attacker and the initial HP of the target
	OnTakeDamage, which is checked after the attack, does the damage by comparing the initial HP to the current health after the damage is dealt
]]
function SpikedCarapace( event )
	local attacker = event.attacker
	if not attacker:IsRangedAttacker() then
		event.target.attacker = event.attacker:GetEntityIndex()
		event.target.initial_hp = event.target:GetHealth()
	end
end

function SpikedCarapaceDamage( event )
	local unit = event.unit
	local attacker = EntIndexToHScript(event.unit.attacker)
	local ability = event.ability
	local abilityDamageType = ability:GetAbilityDamageType()
	local melee_damage_return = ability:GetLevelSpecialValueFor("melee_damage_return", ability:GetLevel() - 1)

	-- Calculate the damage and apply
	local damage_taken = unit.initial_hp - unit:GetHealth()
	local return_damage = damage_taken * 0.01 * melee_damage_return
			
	ApplyDamage({ victim = attacker, attacker = unit, damage = return_damage, damage_type = abilityDamageType })
	print(damage_taken,return_damage)
	
end