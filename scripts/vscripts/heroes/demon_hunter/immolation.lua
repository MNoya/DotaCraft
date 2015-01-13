--[[
	Author: igo/Noya
	Date: 13.1.2015.
	Deals AoE damage over time while the ability maintain cost can be paid
]]
function warchasers_blade_berserker_immolation_function( event )
	-- Variables
	local caster = event.caster
	local ability = event.ability
	local abilityDamageType = ability:GetAbilityDamageType()
	local damage_per_second = 5 + 5 * ability:GetLevel()
	local manacost_per_second = ability:GetLevelSpecialValueFor("mana_cost_per_second", ability:GetLevel() - 1 )
	local targets = event.target_entities

	-- Check if the spell mana cost can be maintained
	if caster:GetMana() >= manacost_per_second then
		caster:SpendMana( manacost_per_second, event.ability)

		-- Deal damage to all targets passed
		for key, unit in pairs(targets) do
			ApplyDamage({
						victim = unit,
						attacker = caster,
						damage = damage_per_second,
						damage_type = abilityDamageType
						})
		end
	else
		ability:ToggleAbility()
	end
end