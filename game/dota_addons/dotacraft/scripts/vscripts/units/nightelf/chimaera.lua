function CorrosiveBreathAttack( event )
	local chimaera = event.caster
	local target = event.target
	local ability = event.ability

	if IsCustomBuilding(target) then
		chimaera:RemoveModifierByName("modifier_corrosive_breath_adjustment")
		chimaera:SetRangedProjectileName("particles/units/heroes/hero_venomancer/venomancer_base_attack.vpcf")
	else
		ability:ApplyDataDrivenModifier(chimaera, chimaera, "modifier_corrosive_breath_adjustment", {})
		chimaera:SetRangedProjectileName("particles/units/heroes/hero_razor/razor_base_attack.vpcf")
	end
end

function CorrosiveBreathDamage( event )
	local chimaera = event.caster
	local target = event.target
	local autoattack_damage = event.Damage --Magic attacks deal 35% to Fortified so this skill should greatly increase the damage output to buildings

	if IsCustomBuilding(target) then
		local damage = event.ability:GetSpecialValueFor("siege_damage")
		local armor_type = GetArmorType(target)
		local multiplier = GetDamageForAttackAndArmor("siege", armor_type)
		damage = damage * multiplier

		ApplyDamage({ victim = target, attacker = chimaera, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL, ability = event.ability})
	else
		chimaera:RemoveModifierByName("modifier_corrosive_breath_adjustment")
	end
end

-- Jakiro attack animation seems screwed for units, so another one it has to be faked on every attack
function ChimaeraAttack( event )
	local chimaera = event.caster
	local target = event.target

	chimaera:StartGesture(ACT_DOTA_CAST_ABILITY_2)
end