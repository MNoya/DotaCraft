function dotacraft:FilterDamage( filterTable )
	--for k, v in pairs( filterTable ) do
	--	print("Damage: " .. k .. " " .. tostring(v) )
	--end
	local victim_index = filterTable["entindex_victim_const"]
	local attacker_index = filterTable["entindex_attacker_const"]
	if not victim_index or not attacker_index then
		return true
	end

	local victim = EntIndexToHScript( victim_index )
	local attacker = EntIndexToHScript( attacker_index )
	local damagetype = filterTable["damagetype_const"]

	-- Physical attack damage filtering
	if damagetype == DAMAGE_TYPE_PHYSICAL then
		local original_damage = filterTable["damage"] --Post reduction
		local inflictor = filterTable["entindex_inflictor_const"]

		local armor = victim:GetPhysicalArmorValue()
		local damage_reduction = ((armor)*0.06) / (1+0.06*(armor))

		-- If there is an inflictor, the damage came from an ability
		local attack_damage
		if inflictor then
			--Remake the full damage to apply our custom handling
			attack_damage = original_damage / ( 1 - damage_reduction )
			--print(original_damage,"=",attack_damage,"*",1-damage_reduction)
		else
			attack_damage = attacker:GetAttackDamage()
		end
	
		-- Adjust if the damage comes from splash
		if victim.damage_from_splash then
			attack_damage = victim.damage_from_splash
			victim.damage_from_splash = nil
		elseif HasSplashAttack(attacker) then
			SplashAttack(attack_damage, attacker, victim)
		end

		local attack_type  = GetAttackType( attacker )
		local armor_type = GetArmorType( victim )
		local multiplier = GetDamageForAttackAndArmor(attack_type, armor_type)

		local damage = ( attack_damage * (1 - damage_reduction)) * multiplier

		-- Extra rules for certain ability modifiers
		-- modifier_defend (50% less damage from Piercing attacks)
		if victim:HasModifier("modifier_defend") and attack_type == "pierce" then
			print("Defend reduces this piercing attack to 50%")
			damage = damage * 0.5

		-- modifier_elunes_grace (Piercing attacks to 65%)
		elseif victim:HasModifier("modifier_elunes_grace") and attack_type == "pierce" then
			print("Elunes Grace reduces this piercing attack to 65%")
			damage = damage * 0.65
		
		-- modifier_possession_caster (All attacks to 166%)
		elseif victim:HasModifier("modifier_possession_caster") then
			damage = damage * 1.66
		end

		--print("Damage ("..attack_type.." vs "..armor_type.." armor ["..math.floor(armor).."]): ("  .. attack_damage .. " * "..1-damage_reduction..") * ".. multiplier.. " = " .. damage )
		
		-- Reassign the new damage
		filterTable["damage"] = damage
	
	-- Magic damage filtering
	elseif damagetype == DAMAGE_TYPE_MAGICAL then
		local inflictor = filterTable["entindex_inflictor_const"]
		local damage = filterTable["damage"] --Pre reduction

		-- Extra rules for certain ability modifiers
		-- modifier-anti_magic_shell (Absorbs 300 magic damage)
		if victim:HasModifier("modifier_anti_magic_shell") then
			local absorbed = 0
			local absorbed_already = victim.anti_magic_shell_absorbed

			if damage+absorbed_already < 300 then
				absorbed = damage
				victim.anti_magic_shell_absorbed = absorbed_already + damage
			else
				-- Absorb up to the limit and end
				absorbed = 300 - absorbed_already
				victim:RemoveModifierByName("modifier_anti_magic_shell")
				victim.anti_magic_shell_absorbed = nil
			end

			if victim.anti_magic_shell_absorbed then
				print("Anti-Magic Shell Absorbed "..absorbed.." damage from an instace of "..damage.." ("..victim.anti_magic_shell_absorbed.." so far)")
			else
				print("Anti-Magic Shell Absorbed "..absorbed.." damage from an instace of "..damage.." and ended")
			end
			damage = damage - absorbed
		end	

		if damage ~= filterTable["damage"] then
			print("Magic Damage reduced: was ".. filterTable["damage"].." - dealt "..damage )
		end
		
		-- Reassign the new damage
		filterTable["damage"] = damage

	end

	-- Cheat code host only
  	if GameRules.WhosYourDaddy then
  		local victimID = EntIndexToHScript(victim_index):GetPlayerOwnerID()
  		if victimID == 0 then
  			filterTable["damage"] = 0
  		end
  	end

    filterTable["damage"] = 0

	return true
end

function SplashAttack( attack_damage, attacker, victim )
	local target = victim
	local medium_radius = GetMediumSplashRadius(attacker)
    local medium_damage = attack_damage * GetMediumSplashDamage(attacker)

    local small_radius = GetSmallSplashRadius(attacker)
    local small_damage = attack_damage * GetSmallSplashDamage(attacker)

    --print("Attacked for "..attack_damage.." - Splashing "..medium_damage.." damage in "..medium_radius.." (medium radius) and "..small_damage.." in "..small_radius.." (small radius)")

    local targets_medium_radius = FindAllUnitsInRadius(target, medium_radius)
    --DebugDrawCircle(target:GetAbsOrigin(), Vector(255,0,0), 100, medium_radius, true, 3)
    for _,v in pairs(targets_medium_radius) do
        if v ~= attacker and v ~= target then
        	v.damage_from_splash = medium_damage
            ApplyDamage({ victim = v, attacker = attacker, damage = medium_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
        end
    end

    local targets_small_radius = FindAllUnitsInRadius(target, small_radius)
    --DebugDrawCircle(target:GetAbsOrigin(), Vector(255,0,0), 100, small_radius, true, 3)
    for _,v in pairs(targets_small_radius) do
        if v ~= attacker and v ~= target then
        	v.damage_from_splash = medium_damage
            ApplyDamage({ victim = v, attacker = attacker, damage = small_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
        end
    end
end


DAMAGE_TYPES = {
    [0] = "DAMAGE_TYPE_NONE",
    [1] = "DAMAGE_TYPE_PHYSICAL",
    [2] = "DAMAGE_TYPE_MAGICAL",
    [4] = "DAMAGE_TYPE_PURE",
    [7] = "DAMAGE_TYPE_ALL",
    [8] = "DAMAGE_TYPE_HP_REMOVAL",
}
