function ApplyModifierUpgrade( event )
	
	local caster = event.caster
	local ability = event.ability
	local unit_name = caster:GetUnitName()
	local ability_name = ability:GetAbilityName()

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
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_siege_engine_damage", {})
		elseif unit_name == "human_mortar_team" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_mortar_team_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_bonus_damage", {})
		end

	end
end

function ApplyAnimalWarTraining( event )
	local caster = event.caster
	local bonus_health = event.ability:GetSpecialValueFor("bonus_health")
	caster:IncreaseMaxHealth(bonus_health)
end

-- When peasants spawn, adjust their gather ability level
function HarvestUpgrade( event )
	local peasant = event.target
	local playerID = peasant:GetPlayerOwnerID()
	local upgrades = Players:GetUpgradeTable(playerID)

	local level = Players:GetCurrentResearchRank(playerID, "human_research_lumber_harvesting1")
	local ability = peasant:GetGatherAbility():SetLevel(1+level)
end