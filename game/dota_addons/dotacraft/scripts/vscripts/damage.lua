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

		local armor = victim:GetPhysicalArmorValue()
		local damage_reduction = ((armor)*0.06) / (1+0.06*(armor))

		--Remake the full damage to apply our custom handling
		local attack_damage = original_damage / (1 - damage_reduction)
		--print(original_damage,"=",attack_damage,"*",1-damage_reduction)

		local attack_type  = attacker:GetAttackType()
		local armor_type = victim:GetArmorType()
		local multiplier = attacker:GetAttackFactorAgainstTarget(victim)

		local damage = (attack_damage * (1 - damage_reduction)) * multiplier

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

	-- Revert damage from MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
    local inflictor = filterTable["entindex_inflictor_const"]
	if inflictor and attacker:IsHero() then
	    filterTable["damage"] = filterTable["damage"]/(1+((attacker:GetIntellect()/16)/100))
	end

	-- Cheat code host only
  	if GameRules.WhosYourDaddy then
  		local victimID = EntIndexToHScript(victim_index):GetPlayerOwnerID()
  		if victimID == 0 then
  			filterTable["damage"] = 0
  		end
  	end

	return true
end

function DamageBuilding(target, damage, ability, caster)
	local currentHP = target:GetHealth()
	local newHP = currentHP - damage

	-- If the HP would hit 0 with this damage, kill the unit
	if newHP <= 0 then
		target:Kill(ability, caster)
	else
		target:SetHealth(newHP)
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
