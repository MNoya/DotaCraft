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
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_siege_engine_damage", {})
		elseif unit_name == "human_mortar_team" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_mortar_team_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_bonus_damage", {})
		end

	end
end

-- Add Health through lua because MODIFIER_PROPERTY_HEALTH_BONUS doesn't work on npc_dota_creature zzz
function ApplyAnimalWarTraining( event )
	local caster = event.caster

	-- Wait 1 frame because the ownership hasn't been set yet
	Timers:CreateTimer(function() 
		local hero = caster:GetOwner()
		local playerID = hero:GetPlayerOwnerID()
		local upgrades = Players:GetUpgradeTable(playerID)
		if upgrades["human_research_animal_war_training"] then
			local bonus_health = event.ability:GetLevelSpecialValueFor("bonus_health", (event.ability:GetLevel() - 1))

			local newHP = caster:GetMaxHealth() + bonus_health
			caster:SetMaxHealth(newHP)
			caster:SetHealth(caster:GetHealth() + bonus_health)
		end
	end)
end

function TrainPriest( event )
	local caster = event.caster
	local hero = caster:GetOwner()
	local playerID = hero:GetPlayerOwnerID()
	local upgrades = Players:GetUpgradeTable(playerID)

	local target = event.target
	if upgrades["human_research_priest_training2"] then
		target:AddAbility("human_priest_training2")
		local ability = target:FindAbilityByName("human_priest_training2")
		ability:SetLevel(2)
		target:CreatureLevelUp(1)
	elseif upgrades["human_research_priest_training1"] then
		target:AddAbility("human_priest_training1")
		local ability = target:FindAbilityByName("human_priest_training1")
		ability:SetLevel(1)
	end
end

function TrainSorceress( event )
	local caster = event.caster
	local hero = caster:GetOwner()
	local playerID = hero:GetPlayerOwnerID()
	local upgrades = Players:GetUpgradeTable(playerID)

	local target = event.target
	if upgrades["human_research_sorceress_training2"] then
		target:AddAbility("human_sorceress_training2")
		local ability = target:FindAbilityByName("human_sorceress_training2")
		ability:SetLevel(2)
		target:CreatureLevelUp(1)
	elseif upgrades["human_research_sorceress_training1"] then
		target:AddAbility("human_sorceress_training1")
		local ability = target:FindAbilityByName("human_sorceress_training1")
		ability:SetLevel(1)
	end
end