-- Deal medium damage to units in radius, ignore the main target of the attack which was already damaged
function MortarSplashMedium( event )
	local caster = event.caster
	local target = event.target
	local targets = event.target_entities
	local attack_damage = caster:GetAverageTrueAttackDamage()

	-- Units in the medium-radius will also be damaged by another 1/4 instance
	local medium_damage = attack_damage * 0.25
	for _,enemy in pairs(targets) do
		if enemy ~= target then
			ApplyDamage({ victim = enemy, attacker = caster, damage = medium_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
		end
	end
end

-- Deal small damage to units in radius, ignore the main target of the attack which was already damaged
function MortarSplashSmall( event )
	local caster = event.caster
	local target = event.target
	local targets = event.target_entities
	local attack_damage = caster:GetAverageTrueAttackDamage()

	local small_damage = attack_damage * 0.25
	for _,enemy in pairs(targets) do
		if enemy ~= target then
			ApplyDamage({ victim = enemy, attacker = caster, damage = small_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
		end
	end
end

-- Deal extra damage to  Unarmored and Medium armor units in AoE
function FragmentationShard( event )
	local caster = event.caster
	local target = event.target
	local targets = event.target_entities
	local extra_damage = caster:GetAverageTrueAttackDamage() -- Double damage to unarmored/medium armored units

	for _,enemy in pairs(targets) do
		-- Check the target armor type directly from the KV file (+volvo pls)
		local unit_name = enemy:GetUnitName()
		local target_info = GameRules.UnitKV[unit_name]
		local armor_type = target_info.CombatClassDefend

		if armor_type == "DOTA_COMBAT_CLASS_DEFEND_BASIC" or armor_type == "DOTA_COMBAT_CLASS_DEFEND_WEAK" then
			-- Do extra damage to this unit
			ApplyDamage({ victim = enemy, attacker = caster, damage = extra_damage, damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES})
		end
	end
end