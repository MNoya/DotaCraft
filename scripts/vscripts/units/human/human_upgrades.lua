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

-- This directly applies the current lvl 1/2/3, from the player upgrades table
-- Called on each different OnSpawn event
function ApplyForgedSwordsUpgrade( event )

	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades

	local level = 0
	if player.upgrades["human_research_forged_swords3"] then
		target:AddAbility("human_forged_swords3")
		local ability = target:FindAbilityByName("human_forged_swords3")
		level = 3
		ability:SetLevel(level)
	elseif player.upgrades["human_research_forged_swords2"] then
		target:AddAbility("human_forged_swords2")
		local ability = target:FindAbilityByName("human_forged_swords2")
		level = 2
		ability:SetLevel(level)
	elseif player.upgrades["human_research_forged_swords1"] then
		target:AddAbility("human_forged_swords1")
		local ability = target:FindAbilityByName("human_forged_swords1")
		level = 1
		ability:SetLevel(level)
	end

	if level ~= 0 then
		UpgradeWeaponWearables(target, level)
	end
end

function ApplyPlatingUpgrade( event )

	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades
	local level = 0

	if player.upgrades["human_research_plating3"] then
		target:AddAbility("human_plating3")
		local ability = target:FindAbilityByName("human_plating3")
		level = 3
		ability:SetLevel(level)
	elseif player.upgrades["human_research_plating2"] then
		target:AddAbility("human_plating2")
		local ability = target:FindAbilityByName("human_plating2")
		level = 2
		ability:SetLevel(level)
	elseif player.upgrades["human_research_plating1"] then
		target:AddAbility("human_plating1")
		local ability = target:FindAbilityByName("human_plating1")
		level = 1
		ability:SetLevel(level)
	end

	if level ~= 0 then
		UpgradeArmorWearables(target, level)
	end

end

function ApplyRangedWeaponsUpgrade( event )

	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades
	local level = 0

	if player.upgrades["human_research_ranged_weapons3"] then
		target:AddAbility("human_ranged_weapons3")
		local ability = target:FindAbilityByName("human_ranged_weapons3")
		level = 3
		ability:SetLevel(level)
	elseif player.upgrades["human_research_ranged_weapons2"] then
		target:AddAbility("human_ranged_weapons2")
		local ability = target:FindAbilityByName("human_ranged_weapons2")
		level = 2
		ability:SetLevel(level)
	elseif player.upgrades["human_research_ranged_weapons1"] then
		target:AddAbility("human_ranged_weapons1")
		local ability = target:FindAbilityByName("human_ranged_weapons1")
		level = 1
		ability:SetLevel(level)
	end

	if level ~= 0 then
		UpgradeWeaponWearables(target, level)
	end

end

function ApplyLeatherArmorUpgrade( event )

	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades
	local level = 0
	
	if player.upgrades["human_research_leather_armor3"] then
		target:AddAbility("human_leather_armor3")
		local ability = target:FindAbilityByName("human_leather_armor3")
		level = 3
		ability:SetLevel(level)
	elseif player.upgrades["human_research_leather_armor2"] then
		target:AddAbility("human_leather_armor2")
		local ability = target:FindAbilityByName("human_leather_armor2")
		level = 2
		ability:SetLevel(level)
	elseif player.upgrades["human_research_leather_armor1"] then
		target:AddAbility("human_leather_armor1")
		local ability = target:FindAbilityByName("human_leather_armor1")
		level = 1
		ability:SetLevel(level)
	end

	if level ~= 0 then
		UpgradeArmorWearables(target, level)
	end

end


-- Gives an inventory to this unit
function Backpack( event )
	local caster = event.caster

	caster:SetHasInventory(true)
end


-- Add Health through lua because MODIFIER_PROPERTY_HEALTH_BONUS doesn't work on npc_dota_creature zzz
function ApplyAnimalWarTraining( event )
	local caster = event.caster

	-- Wait 1 frame because the ownership hasn't been set yet
	Timers:CreateTimer(function() 
		local hero = caster:GetOwner()
		local player = hero:GetPlayerOwner()
		local upgrades = player.upgrades
		DeepPrintTable(player.upgrades)
		if player.upgrades["human_research_animal_war_training"] then
			local bonus_health = event.ability:GetLevelSpecialValueFor("bonus_health", (event.ability:GetLevel() - 1))

			local newHP = caster:GetMaxHealth() + bonus_health
			caster:SetMaxHealth(newHP)
			caster:SetHealth(caster:GetHealth() + bonus_health)
		end
	end)
end

-- Add Health and Mana through lua because Volvo
function ApplyPriestTraining( event )
	local caster = event.caster
	local hero = caster:GetOwner()
	local player = hero:GetPlayerOwner()

	local bonus_health = event.ability:GetLevelSpecialValueFor("bonus_health", (event.ability:GetLevel() - 1))
	local bonus_mana = event.ability:GetLevelSpecialValueFor("bonus_mana", (event.ability:GetLevel() - 1))

	local newHP = caster:GetMaxHealth() + bonus_health
	--local newMana = caster:GetMaxMana() + bonus_mana

	caster:SetMaxHealth(newHP)
	caster:SetHealth(caster:GetHealth() + bonus_health)

	-- There's no SetMaxMana................... no comments
	caster:CreatureLevelUp(1)
	caster:SetMana(caster:GetMana() + bonus_mana) -- The Mana Gain value is defined on the npc_units_custom file
end

function ApplySorceressTraining( event )
	local caster = event.caster
	local hero = caster:GetOwner()
	local player = hero:GetPlayerOwner()

	local bonus_health = event.ability:GetLevelSpecialValueFor("bonus_health", (event.ability:GetLevel() - 1))
	local bonus_mana = event.ability:GetLevelSpecialValueFor("bonus_mana", (event.ability:GetLevel() - 1))

	local newHP = caster:GetMaxHealth() + bonus_health
	--local newMana = caster:GetMaxMana() + bonus_mana

	caster:SetMaxHealth(newHP)
	caster:SetHealth(caster:GetHealth() + bonus_health)

	caster:CreatureLevelUp(1)
	caster:SetMana(caster:GetMana() + bonus_mana)
end

function TrainPriest( event )
	local caster = event.caster
	local hero = caster:GetOwner()
	local player = hero:GetPlayerOwner()
	local upgrades = player.upgrades

	local target = event.target
	if player.upgrades["human_research_priest_training2"] then
		target:AddAbility("human_priest_training2")
		local ability = target:FindAbilityByName("human_priest_training2")
		ability:SetLevel(2)
		target:CreatureLevelUp(1)
	elseif player.upgrades["human_research_priest_training1"] then
		target:AddAbility("human_priest_training1")
		local ability = target:FindAbilityByName("human_priest_training1")
		ability:SetLevel(1)
	end
end

function TrainSorceress( event )
	local caster = event.caster
	local hero = caster:GetOwner()
	local player = hero:GetPlayerOwner()
	local upgrades = player.upgrades

	local target = event.target
	if player.upgrades["human_research_sorceress_training2"] then
		target:AddAbility("human_sorceress_training2")
		local ability = target:FindAbilityByName("human_sorceress_training2")
		ability:SetLevel(2)
		target:CreatureLevelUp(1)
	elseif player.upgrades["human_research_sorceress_training1"] then
		target:AddAbility("human_sorceress_training1")
		local ability = target:FindAbilityByName("human_sorceress_training1")
		ability:SetLevel(1)
	end
end