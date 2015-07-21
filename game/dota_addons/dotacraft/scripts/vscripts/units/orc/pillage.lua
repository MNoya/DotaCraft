function Pillage(event)
	local target = event.target
	local caster = event.caster

	if not IsCustomBuilding(target) then
		return
	end

	if caster.pillaged_gold == nil then
		caster.pillaged_gold = 0
	end

	local pillage = (event.attack_damage/target:GetMaxHealth()) * event.pillage_ratio * GetGoldCost(target)
	caster.pillaged_gold = caster.pillaged_gold + pillage
	local effective_gold = math.floor(caster.pillaged_gold)

	if effective_gold > 0 then
		caster:GetPlayerOwner():GetAssignedHero():ModifyGold(effective_gold, false, 0)
		PopupGoldGain(caster, effective_gold)
		caster.pillaged_gold = caster.pillaged_gold - effective_gold
	end
end