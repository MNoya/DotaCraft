function ApplyModifierUpgrade( event )
	
	local caster = event.caster
	local ability = event.ability
	local unit_name = caster:GetUnitName()
	local ability_name = ability:GetAbilityName()

	print("Applying "..ability_name.." to "..unit_name)

	-- Unholy Strength
	if string.find(ability_name,"melee_weapons") then
		if unit_name == "orc_tauren" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_tauren_damage", {})
		elseif unit_name == "orc_raider" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_raider_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_grunt_damage", {})
		end

	-- Creature Attack
	elseif string.find(ability_name,"ranged_weapons") then
		if unit_name == "orc_demolisher" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_demolisher_damage", {})
		elseif unit_name == "orc_troll_batrider" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_batrider_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_bonus_damage", {})
		end
	end
end


function ReinforcedDefenses( event )
	local building = event.caster
	SetArmorType(building, "fortified")
end