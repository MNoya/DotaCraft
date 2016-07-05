function GrantTrueSight(keys)
	local caster = keys.caster
	local ability = keys.ability
	--caster:AddNewModifier(caster,ability, "modifier_truesight", {sight_range = keys.Radius})
	--caster:AddNewModifier(caster, ability, "modifier_item_ward_true_sight", {true_sight_range = keys.Radius}) 
	caster:AddNewModifier(caster, ability, "modifier_item_gem_of_true_sight", {radius=keys.Radius})
end

function RemoveTrueSight(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:RemoveModifierByName("modifier_item_gem_of_true_sight")
end