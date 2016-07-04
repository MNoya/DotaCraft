function CorrosiveBreathAttack( event )
	local chimaera = event.caster
	local target = event.target
	local ability = event.ability

	if IsCustomBuilding(target) then
		chimaera:RemoveModifierByName("modifier_corrosive_breath_adjustment")
		chimaera:SetRangedProjectileName("particles/units/heroes/hero_venomancer/venomancer_base_attack.vpcf")
		if chimaera:GetAttackType() ~= "siege" then
			chimaera:SetAttackType("siege")
			chimaera:SetBaseDamageMin(ability:GetSpecialValueFor("siege_damage")-5)
			chimaera:SetBaseDamageMax(ability:GetSpecialValueFor("siege_damage")+5)
		end
	else
		ability:ApplyDataDrivenModifier(chimaera, chimaera, "modifier_corrosive_breath_adjustment", {})
		chimaera:SetRangedProjectileName("particles/units/heroes/hero_razor/razor_base_attack.vpcf")
		if chimaera:GetAttackType() ~= "magic" then
			chimaera:SetAttackType("magic")
			chimaera:SetBaseDamageMin(chimaera:GetKeyValue("AttackDamageMin"))
			chimaera:SetBaseDamageMin(chimaera:GetKeyValue("AttackDamageMax"))
		end
	end
end

function CorrosiveBreathDamage( event )
	local chimaera = event.caster
	local target = event.target

	if not IsCustomBuilding(target) then
		chimaera:RemoveModifierByName("modifier_corrosive_breath_adjustment")
	end
end

-- Jakiro attack animation seems screwed for units, so another one it has to be faked on every attack
function ChimaeraAttack( event )
	local chimaera = event.caster
	local target = event.target

	chimaera:StartGesture(ACT_DOTA_CAST_ABILITY_2)
end