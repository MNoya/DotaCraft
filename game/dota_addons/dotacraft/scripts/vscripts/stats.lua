-- Custom Stat Values
HP_PER_STR = 25
HP_REGEN_PER_STR = 0.05
MANA_PER_INT = 15
MANA_REGEN_PER_INT = 0.05
ARMOR_PER_AGI = 0.3
ATKSPD_PER_AGI = 2
MAX_MOVE_SPEED = 400

-- Default Dota Values
DEFAULT_HP_PER_STR = 19
DEFAULT_HP_REGEN_PER_STR = 0.03
DEFAULT_MANA_PER_INT = 13
DEFAULT_MANA_REGEN_PER_INT = 0.04
DEFAULT_ARMOR_PER_AGI = 0.14
DEFAULT_ATKSPD_PER_AGI = 1

THINK_INTERVAL = 0.25

function dotacraft:ModifyStatBonuses(unit)
	local hero = unit
	local applier = CreateItem("item_stat_modifier", nil, nil)

	local hp_adjustment = HP_PER_STR - DEFAULT_HP_PER_STR
	local hp_regen_adjustment = HP_REGEN_PER_STR - DEFAULT_HP_REGEN_PER_STR
	local mana_adjustment = MANA_PER_INT - DEFAULT_MANA_PER_INT
	local mana_regen_adjustment = MANA_REGEN_PER_INT - DEFAULT_MANA_REGEN_PER_INT
	local armor_adjustment = ARMOR_PER_AGI - DEFAULT_ARMOR_PER_AGI
	local attackspeed_adjustment = ATKSPD_PER_AGI - DEFAULT_ATKSPD_PER_AGI

	print("Modifying Stats Bonus of hero "..hero:GetUnitName())

	Timers:CreateTimer(function()

		if not IsValidEntity(hero) then
			return
		end

		-- Initialize value tracking
		if not hero.custom_stats then
			hero.custom_stats = true
			hero.strength = 0
			hero.agility = 0
			hero.intellect = 0
			hero.movespeed = 0
		end

		-- Get player attribute values
		local strength = hero:GetStrength()
		local agility = hero:GetAgility()
		local intellect = hero:GetIntellect()
		local movespeed = hero:GetIdealSpeed()
		
		-- Adjustments

		-- STR
		if strength ~= hero.strength then
			
			-- HP Bonus
			if not hero:HasModifier("modifier_health_bonus") then
				applier:ApplyDataDrivenModifier(hero, hero, "modifier_health_bonus", {})
			end

			local health_stacks = strength * hp_adjustment
			hero:SetModifierStackCount("modifier_health_bonus", hero, health_stacks)

			-- HP Regen Bonus
			if not hero:HasModifier("modifier_health_regen_constant") then
				applier:ApplyDataDrivenModifier(hero, hero, "modifier_health_regen_constant", {})
			end

			local health_regen_stacks = strength * hp_regen_adjustment * 100
			hero:SetModifierStackCount("modifier_health_regen_constant", hero, health_regen_stacks)
		end

		-- AGI
		if agility ~= hero.agility then
			
			-- Base Armor Bonus
			local armor = agility * armor_adjustment
			hero:SetPhysicalArmorBaseValue(armor)

			-- Attack Speed Bonus
			if not hero:HasModifier("modifier_attackspeed_bonus_constant") then
				applier:ApplyDataDrivenModifier(hero, hero, "modifier_attackspeed_bonus_constant", {})
			end

			local attackspeed_stacks = agility * attackspeed_adjustment
			hero:SetModifierStackCount("modifier_attackspeed_bonus_constant", hero, attackspeed_stacks)
		end

		-- INT
		if intellect ~= hero.intellect then
			
			-- Mana Bonus
			if not hero:HasModifier("modifier_mana_bonus") then
				applier:ApplyDataDrivenModifier(hero, hero, "modifier_mana_bonus", {})
			end

			local mana_stacks = intellect * mana_adjustment
			hero:SetModifierStackCount("modifier_mana_bonus", hero, mana_stacks)

			-- Mana Regen Bonus
			if not hero:HasModifier("modifier_base_mana_regen") then
				applier:ApplyDataDrivenModifier(hero, hero, "modifier_base_mana_regen", {})
			end

			local mana_regen_stacks = intellect * mana_regen_adjustment * 100
			hero:SetModifierStackCount("modifier_base_mana_regen", hero, mana_regen_stacks)
		end

		-- MS limit
		if movespeed >= MAX_MOVE_SPEED then
			applier:ApplyDataDrivenModifier(hero, hero, "modifier_movespeed_max", {duration=THINK_INTERVAL-1/30})
		end

		-- Update the stored values for next timer cycle
		hero.strength = strength
		hero.agility = agility
		hero.intellect = intellect
		hero.movespeed = movespeed

		hero:CalculateStatBonus()

		return THINK_INTERVAL
	end)
end