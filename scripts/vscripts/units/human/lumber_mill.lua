-- Gives Health Percentage Increase to this building
function Masonry( event )
	local caster = event.caster
	local ability = event.ability
	local level = event.Level
	local healthBonusPercentage = event.ability:GetLevelSpecialValueFor("bonus_health_pct", level - 1) * 0.01
	
	local oldHealthBonus = 0
	if level > 1 then
		oldHealthBonus = event.ability:GetLevelSpecialValueFor("bonus_health_pct", level - 2) * 0.01
	end
	
	local missingHP = caster:GetHealthDeficit()
	local maxHP = caster:GetMaxHealth()
	local baseHP = maxHP / (1+oldHealthBonus)
	local newMaxHP = baseHP * (1+healthBonusPercentage)
	caster:SetMaxHealth(newMaxHP)
	caster:SetHealth(newMaxHP - missingHP)

	-- Special case for the scout tower which gains 1 extra armor each level
	if caster:GetUnitName() == "human_scout_tower" then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_human_masonry_light_armor", {})
	end

	-- Set ability hidden
	ability:SetHidden(true)
end