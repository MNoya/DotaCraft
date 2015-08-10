function ApplyModifierUpgrade( event )
	
	local caster = event.caster
	local ability = event.ability
	local unit_name = caster:GetUnitName()
	local ability_name = ability:GetAbilityName()

	print("Applying "..ability_name.." to "..unit_name)

	-- Unholy Strength
	if string.find(ability_name,"unholy_strength") then
		if unit_name == "undead_meat_wagon" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_meat_wagon_damage", {})
		elseif unit_name == "undead_abomination" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_abomination_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_bonus_damage", {})
		end

	-- Creature Attack
	elseif string.find(ability_name,"creature_attack") then
		if unit_name == "undead_frost_wyrm" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_frost_wyrm_damage", {})
		elseif unit_name == "undead_gargoyle" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_destroyer_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_bonus_damage", {})
		end
	end
end

-- Swaps wearables on Skeleton Warriors and Mages
function SkeletalLongevity( event )
	local caster = event.caster
	local unitName = caster:GetUnitName()

	if unitName == "undead_skeleton_warrior" then

		Timers:CreateTimer(0.5, function()
			local cape = Entities:CreateByClassname("prop_dynamic")
			caster.cape = cape
			cape:SetModel("models/items/wraith_king/regalia_of_the_bonelord_cape.vmdl")
			cape:SetModelScale(0.6)

			local attach = caster:ScriptLookupAttachment("attach_hitloc")
			local origin = caster:GetAttachmentOrigin(attach)
			local fv = caster:GetForwardVector()
			origin = origin + fv * 18

			cape:SetAbsOrigin(Vector(origin.x, origin.y, origin.z-70))
			cape:SetParent(caster, "attach_hitloc")

		end)

	elseif unitName == "undead_skeletal_mage" then
		SwapWearable(caster, "models/heroes/pugna/pugna_head.vmdl", "models/items/pugna/ashborn_horns/ashborn_horns.vmdl")
	end
end