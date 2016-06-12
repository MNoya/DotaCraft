--[[
	Author: Noya
	Date: 14.1.2015.
	Deals AoE damage over time while the ability maintain cost can be paid
]]
function Immolation( event )
	-- Variables
	if true then return true end
	local caster = event.caster
	local ability = event.ability
	local abilityDamageType = ability:GetAbilityDamageType()
	local damage_per_second = ability:GetLevelSpecialValueFor("damage_per_second", ability:GetLevel() - 1 )
	local manacost_per_second = ability:GetLevelSpecialValueFor("mana_cost_per_second", ability:GetLevel() - 1 )
	local targets = event.target_entities

	-- Check if the spell mana cost can be maintained
	if caster:GetMana() >= manacost_per_second then
		caster:SpendMana( manacost_per_second, ability)

		-- Deal damage to all targets passed
		for _,v in pairs(targets) do
			ApplyDamage({ victim = v, attacker = caster, damage = damage_per_second, damage_type = abilityDamageType })
		end
	else
		ability:ToggleAbility()
	end
end