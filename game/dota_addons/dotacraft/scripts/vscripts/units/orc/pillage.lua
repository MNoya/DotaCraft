function Pillage(event)
	local target = event.target
	local caster = event.caster
	local damage = event.attack_damage
	local pillage_ratio = event.ability:GetSpecialValueFor("pillage_ratio")
	local particleName = "particles/units/heroes/hero_alchemist/alchemist_lasthit_coins.vpcf"
	
	if not IsCustomBuilding(target) then
		return
	end

	if caster.pillaged_gold == nil then
		caster.pillaged_gold = 0
	end

	local damage = event.attack_damage
	local unitName = caster:GetUnitName()

	if unitName == 'orc_raider' then
		damage = damage * 1.5
	else
		damage = damage * 0.7
	end

	local armor = target:GetPhysicalArmorValue()

	damage = damage * (1 - 0.06 * armor / (1 + 0.06 * math.abs(armor)))

	local pillage = (damage/target:GetMaxHealth()) * event.pillage_ratio * GetGoldCost(target)
	caster.pillaged_gold = caster.pillaged_gold + pillage
	local effective_gold = math.floor(caster.pillaged_gold)

	if effective_gold > 0 then
		caster:GetPlayerOwner():GetAssignedHero():ModifyGold(effective_gold, false, 0)
		local particle = ParticleManager:CreateParticle( particleName, PATTACH_OVERHEAD_FOLLOW, caster )
		ParticleManager:SetParticleControl( particle, 0, caster:GetAbsOrigin() )
		ParticleManager:SetParticleControl( particle, 1, caster:GetAbsOrigin() )
		PopupGoldGain(caster, effective_gold)
		caster.pillaged_gold = caster.pillaged_gold - effective_gold
	end
end