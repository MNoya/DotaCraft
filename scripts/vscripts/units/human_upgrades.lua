
function ApplyModifierUpgrade( event )
	
	local caster = event.caster
	local ability = event.ability
	local unit_name = caster:GetUnitName()
	local ability_name = ability:GetAbilityName()

	print("Applying "..ability_name.." to "..unit_name)

	-- Forged Swords
	-- Militia, Footmen and SpellBreakers get +2
	-- Knights get +3 damage
	-- Gryphons get +6
	if string.find(ability_name,"forged_swords") then
		if unit_name == "human_gryphon_rider" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_gryphon_rider_damage", {})
		elseif unit_name == "human_knight" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_knight_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_bonus_damage", {})
		end

	-- Ranged Weapons
	-- Riflemen and Flying Machine get +2 (actually 1.5 and 2.5 but w/e)
	-- Siege Engines get +6
	-- Mortar Teams get +7
	elseif string.find(ability_name,"ranged_weapons") then

		if unit_name == "human_siege_engine" then
			ability:ApplyDataDrivenModifier(caster, caster, "siege_engine_damage", {})
		elseif unit_name == "human_mortar_team" then
			ability:ApplyDataDrivenModifier(caster, caster, "mortar_team_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_bonus_damage", {})
		end

	end
end

-- This directly applies the current lvl 1/2/3, from the player upgrades table
-- Called on each different OnSpawn event
function ApplyForgedSwordsUpgrade( event )

	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades

	if player.upgrades["human_research_forged_swords3"] then
		target:AddAbility("human_forged_swords3")
		local ability = target:FindAbilityByName("human_forged_swords3")
		ability:SetLevel(3)
	elseif player.upgrades["human_research_forged_swords2"] then
		target:AddAbility("human_forged_swords2")
		local ability = target:FindAbilityByName("human_forged_swords2")
		ability:SetLevel(2)
	elseif player.upgrades["human_research_forged_swords1"] then
		target:AddAbility("human_forged_swords1")
		local ability = target:FindAbilityByName("human_forged_swords1")
		ability:SetLevel(1)
	end
end

function ApplyPlatingUpgrade( event )

	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades

	if player.upgrades["human_research_plating3"] then
		target:AddAbility("human_plating3")
		local ability = target:FindAbilityByName("human_plating3")
		ability:SetLevel(3)
	elseif player.upgrades["human_research_plating2"] then
		target:AddAbility("human_plating2")
		local ability = target:FindAbilityByName("human_plating2")
		ability:SetLevel(2)
	elseif player.upgrades["human_research_plating1"] then
		target:AddAbility("human_plating1")
		local ability = target:FindAbilityByName("human_plating1")
		ability:SetLevel(1)
	end

end

function ApplyRangedWeaponsUpgrade( event )

	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades

	if player.upgrades["human_research_ranged_weapons3"] then
		target:AddAbility("human_ranged_weapons3")
		local ability = target:FindAbilityByName("human_ranged_weapons3")
		ability:SetLevel(3)
	elseif player.upgrades["human_research_ranged_weapons2"] then
		target:AddAbility("human_ranged_weapons2")
		local ability = target:FindAbilityByName("human_ranged_weapons2")
		ability:SetLevel(2)
	elseif player.upgrades["human_research_ranged_weapons1"] then
		target:AddAbility("human_ranged_weapons1")
		local ability = target:FindAbilityByName("human_ranged_weapons1")
		ability:SetLevel(1)
	end

end

function ApplyLeatherArmorUpgrade( event )

	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades

	if player.upgrades["human_research_leather_armor3"] then
		target:AddAbility("human_leather_armor3")
		local ability = target:FindAbilityByName("human_leather_armor3")
		ability:SetLevel(3)
	elseif player.upgrades["human_research_leather_armor2"] then
		target:AddAbility("human_leather_armor2")
		local ability = target:FindAbilityByName("human_leather_armor2")
		ability:SetLevel(2)
	elseif player.upgrades["human_research_leather_armor1"] then
		target:AddAbility("human_leather_armor1")
		local ability = target:FindAbilityByName("human_leather_armor1")
		ability:SetLevel(1)
	end

end

