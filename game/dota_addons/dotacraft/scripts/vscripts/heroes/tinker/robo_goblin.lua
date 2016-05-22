--[[
	Author: Noya
	Date: 04.02.2015.
	Swaps caster model and ability, gives a short period of invulnerability
	Also learns a modifier based on another ability upgrade
]]
function RoboGoblinStart( event )
	local caster = event.caster
	local model = event.model
	local ability = event.ability

	-- Saves the original model and attack capability
	if caster.caster_model == nil then 
		caster.caster_model = caster:GetModelName()
	end
	caster.caster_attack = caster:GetAttackCapability()

	-- Sets the new model
	caster:SetOriginalModel(model)

	caster:SetModelScale(2)

	-- Swap sub_ability
	local sub_ability_name = event.sub_ability_name
	local main_ability_name = ability:GetAbilityName()

	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
	print("Swapped "..main_ability_name.." with " ..sub_ability_name)

	-- Learn upgrades
	local upgrade_ability_name =  event.upgrade_ability_name
	local sub_modifier_name = event.sub_modifier_name
	local upgrade_ability = caster:FindAbilityByName(upgrade_ability_name)
	if upgrade_ability and upgrade_ability:GetLevel() > 0 then
		upgrade_ability:ApplyDataDrivenModifier(caster, caster, sub_modifier_name, {})
	end

end

-- Reverts back to the original model and attack type, swaps abilities, removes modifier passed
function RoboGoblinEnd( event )
	local caster = event.caster
	local ability = event.ability
	local modifier = event.remove_modifier_name
	local sub_modifier_name = event.sub_modifier_name

	caster:SetModel(caster.caster_model)
	caster:SetModelScale(1)
	caster:SetOriginalModel(caster.caster_model)
	print(caster.caster_model)

	-- Swap the sub_ability back to normal
	local main_ability_name = event.main_ability_name
	local sub_ability_name = ability:GetAbilityName()

	caster:SwapAbilities(sub_ability_name, main_ability_name, false, true)
	print("Swapped "..sub_ability_name.." with " ..main_ability_name)

	-- Remove modifiers
	caster:RemoveModifierByName(modifier)
	caster:RemoveModifierByName(sub_modifier_name)
end


--[[
	Author: Noya
	Date: 04.02.2015.
	Checks if the attacked target is a building and deals extra physical damage if so
]]
function DealSiegeDamage( event )
 	-- Variables
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local attack_damage = event.Damage
	local extra_dmg_to_buildings =  ability:GetLevelSpecialValueFor( "extra_dmg_to_buildings" , ability:GetLevel() - 1  )
	local damage = attack_damage * ( extra_dmg_to_buildings - 1)
	
	print("damage siege")
	if target.GetInvulnCount then
		print(damage)
		ApplyDamage({ victim = target, attacker = caster, damage = damage, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL })
	end

 end 