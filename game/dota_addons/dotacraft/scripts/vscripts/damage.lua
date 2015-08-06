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
	if damagetype == DAMAGE_TYPE_NONE then
		local original_damage = filterTable["damage"] --Post reduction
		local autoattack_damage = attacker:GetAttackDamage() --Random new damage between max-min of the attacker

		local armor = victim:GetPhysicalArmorValue()
		local damage_reduction
		if armor >= 0 then
			damage_reduction = ((armor)*0.06) / (1+0.06*(armor))
		else
			damage_reduction = 2-0.94^(-armor) --Damage increase
		end

		local attack_type  = GetAttackType( attacker )
		local armor_type = GetArmorType( victim )
		local multiplier = GetDamageForAttackAndArmor(attack_type, armor_type)

		local damage = ( autoattack_damage - autoattack_damage * damage_reduction ) * multiplier

		-- Extra rules for certain ability modifiers
		-- modifier_defend (50% less damage from Piercing attacks)
		if victim:HasModifier("modifier_defend") and attack_type == "pierce" then
			print("Defend reduces this piercing attack to 50%")
			damage = damage * 0.5

		-- modifier_elunes_grace (Piercing attacks to 65%)
		elseif victim:HasModifier("modifier_elunes_grace") and attack_type == "pierce" then
			print("Elunes Grace reduces this piercing attack to 65%")
			damage = damage * 0.65
		end	

		--print("Damage ("..attack_type.." vs "..armor_type.." armor ["..math.floor(armor).."]): ("  .. autoattack_damage .. " reduced by "..damage_reduction..") * ".. multiplier.. " = " .. damage )
		
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

	return true
end


--[[
DAMAGE_TYPE_NONE		0
DAMAGE_TYPE_PHYSICAL	1	
DAMAGE_TYPE_MAGICAL		2	
DAMAGE_TYPE_PURE		4	
DAMAGE_TYPE_ALL			7	
DAMAGE_TYPE_HP_REMOVAL	8
]]
