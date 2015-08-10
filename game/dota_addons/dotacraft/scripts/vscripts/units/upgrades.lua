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

		if cosmetic_type then
			UpgradeWearables(target, level, cosmetic_type)
		end
	end
end

-- ManaGain and HPGain values are defined in the npc_units_custom file
function ApplyTraining( event )
	local caster = event.caster
	local ability = event.ability
	local hero = caster:GetOwner()
	local player = hero:GetPlayerOwner()
	local training_level = ability:GetLevel()
	local levels = event.LevelUp - caster:GetLevel()

	local bonus_health = event.ability:GetSpecialValueFor("bonus_health")
	local bonus_mana = event.ability:GetSpecialValueFor("bonus_mana")

	caster:SetHealth(caster:GetHealth() + bonus_health)
	caster:CreatureLevelUp(levels)
	caster:SetMana(caster:GetMana() + bonus_mana)

	UpgradeWearables(caster, training_level, "training")
end