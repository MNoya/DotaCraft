function ApplyModifierUpgrade( event )
	
	local caster = event.caster
	local ability = event.ability
	local unit_name = caster:GetUnitName()
	local ability_name = ability:GetAbilityName()

	print("Applying "..ability_name.." to "..unit_name)

	-- Strength of the Moon
	if string.find(ability_name,"strength_of_the_moon") then
		if unit_name == "nightelf_glaive_thrower" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_glaive_thrower_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_bonus_damage", {})
		end

	-- Strength of the Wild
	elseif string.find(ability_name,"strength_of_the_wild") then
		if unit_name == "nightelf_mountain_giant" or unit_name ==  "nightelf_druid_of_the_claw" or unit_name ==  "nightelf_druid_of_the_talon" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_druids_mountain_giant_damage", {})
		elseif unit_name == "nightelf_chimaera" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_chimaera_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_bonus_damage", {})
		end

	end
end

-- This directly applies the current lvl 1/2/3, from the player upgrades table
function ApplyMultiRankUpgrade( event )
	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades
	local research_name = event.ResearchName
	local ability_name = string.gsub(research_name, "research_" , "")
	local cosmetic_type = event.WearableType
	local level = 0

	if player.upgrades[research_name.."3"] then
		level = 3		
	elseif player.upgrades[research_name.."2"] then
		level = 2		
	elseif player.upgrades[research_name.."1"] then
		level = 1
	end

	if level ~= 0 then
		target:AddAbility(ability_name..level)
		local ability = target:FindAbilityByName(ability_name..level)
		ability:SetLevel(level)

		if cosmetic_type == "weapon" then
			UpgradeWeaponWearables(target, level)
		elseif cosmetic_type == "armor" then
			UpgradeArmorWearables(target, level)
		end
	end
end

-- Druid of the Claw/Talon spawn
-- ManaGain and HPGain values are defined in the npc_units_custom file
function ApplyDruidTraining( event )
	local caster = event.caster
	local hero = caster:GetOwner()
	local player = hero:GetPlayerOwner()
	local levels = event.LevelUp - caster:GetLevel()

	local bonus_health = event.ability:GetSpecialValueFor("bonus_health")
	local bonus_mana = event.ability:GetSpecialValueFor("bonus_mana")

	local newHP = caster:GetMaxHealth() + bonus_health

	caster:SetHealth(caster:GetHealth() + bonus_health)

	caster:CreatureLevelUp(levels)
	caster:SetMana(caster:GetMana() + bonus_mana)
end

-- Swaps the Huntress' moon glaive ability to the upgraded version
function ApplyMoonGlaiveUpgrade( event )
	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades
	
	if player.upgrades["nightelf_research_upgraded_moon_glaive"] then
		target:RemoveModifierByName("modifier_luna_moon_glaive")
		target:AddAbility("nightelf_upgraded_moon_glaive")
		target:SwapAbilities("nightelf_upgraded_moon_glaive", "nightelf_moon_glaive", true, false)
		target:RemoveAbility("nightelf_moon_glaive")
		target:FindAbilityByName("nightelf_upgraded_moon_glaive"):SetLevel(1)
	end
end

-- Upgrade all Huntresses
function UpgradeMoonGlaives( event )
	local caster = event.caster
	local player = caster:GetPlayerOwner()
	local units = player.units

	for _,unit in pairs(units) do
		if IsValidEntity(unit) and unit:HasAbility("nightelf_moon_glaive") then
			unit:RemoveModifierByName("modifier_luna_moon_glaive")
			unit:AddAbility("nightelf_upgraded_moon_glaive")
			unit:SwapAbilities("nightelf_upgraded_moon_glaive", "nightelf_moon_glaive", true, false)
			unit:RemoveAbility("nightelf_moon_glaive")
			unit:FindAbilityByName("nightelf_upgraded_moon_glaive"):SetLevel(1)
		end
	end
end

-- Upgrade all transformed Druids of the Claw
function UpgradeMarkOfTheClaw( event )
	local caster = event.caster
	local player = caster:GetPlayerOwner()
	local units = player.units

	for _,unit in pairs(units) do
		if IsValidEntity(unit) and unit:HasModifier("modifier_bear_form") then
			local ability = unit:FindAbilityByName("nightelf_roar")
			ability:SetLevel(1)
			ability:SetHidden(false)
		end
	end
end

-- Upgrade all transformed Druids of the Talon
function UpgradeMarkOfTheTalon( event )
	local caster = event.caster
	local player = caster:GetPlayerOwner()
	local units = player.units

	for _,unit in pairs(units) do
		if IsValidEntity(unit) and unit:HasModifier("modifier_crow_form") then
			local ability = unit:FindAbilityByName("nightelf_faerie_fire")
			ability:SetLevel(1)
			ability:SetHidden(false)
		end
	end
end

-- Upgrade all Mountain Giants with Resistant Skin by replacing them
function UpgradeResistantSkin( event )
	local caster = event.caster
	local player = caster:GetPlayerOwner()
	local units = player.units

	for _,unit in pairs(units) do
		if IsValidEntity(unit) and unit:GetUnitName() == "nightelf_mountain_giant" then
			local hp = unit:GetHealth()
			local new_giant = CreateUnitByName("nightelf_mountain_giant_resistant_skin", unit:GetAbsOrigin(), false, unit:GetOwner(), unit:GetPlayerOwner(), unit:GetTeamNumber())
			new_giant:SetControllableByPlayer(unit:GetPlayerOwnerID(), true)
			new_giant:SetOwner(unit:GetOwner())
			new_giant:SetHealth(hp)
			new_giant:SetForwardVector(unit:GetForwardVector())
			unit:RemoveSelf()
		end
	end
end