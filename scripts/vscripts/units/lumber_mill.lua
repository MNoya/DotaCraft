-- Gives Health Percentage Increase to this building
function Masonry( event )
	local caster = event.caster
	local level = event.Level
	local healthBonusPercentage = event.ability:GetLevelSpecialValueFor("bonus_health_pct", Level - 1) * 0.01
	
	local oldHealthBonus = 0
	if level > 1 then
		oldHealthBonus = event.ability:GetLevelSpecialValueFor("bonus_health_pct", Level - 2) * 0.01
	end
	
	local maxHP = target:GetMaxHealth()
	local baseHP = maxHP / (1+oldHealthBonus)
	local newMaxHP = baseHP * (1+healthBonusPercentage)
	caster:SetMaxHealth(newMaxHP)
end