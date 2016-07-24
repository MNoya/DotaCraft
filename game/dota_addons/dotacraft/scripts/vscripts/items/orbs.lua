function EquipOrb( event )
	print("EquipOrb")

	local caster = event.caster
	if caster:IsHero() then
		if not caster.original_attack then
			caster.original_attack = caster:GetAttacksEnabled()
		end
		caster:SetAttacksEnabled("ground, air")
	end
end

function UnequipOrb( event )
	print("UnequipOrb")

	local caster = event.caster
	if caster:IsHero() then
		print("Set Attacks Enabled to ",caster.original_attack)
		caster:SetAttacksEnabled(caster.original_attack)

		if caster.original_attack_type then
			caster:SetAttackCapability(caster.original_attack_type)
		end
	end
end

function OrbAirCheck( event )
	local attacker = event.attacker
	local target = event.target
	local target_type = GetMovementCapability(target)
	if not attacker.original_attack_type then
		attacker.original_attack_type = attacker:GetAttackCapability()
	end
	if target_type == "air" then
		attacker:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
	else
		attacker:SetAttackCapability(attacker.original_attack_type)
	end
end