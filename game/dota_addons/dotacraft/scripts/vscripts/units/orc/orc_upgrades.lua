function ApplyModifierUpgrade( event )
	
	local caster = event.caster
	local ability = event.ability
	local unit_name = caster:GetUnitName()
	local ability_name = ability:GetAbilityName()

	print("Applying "..ability_name.." to "..unit_name)

	-- Unholy Strength
	if string.find(ability_name,"melee_weapons") then
		if unit_name == "orc_tauren" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_tauren_damage", {})
		elseif unit_name == "orc_raider" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_raider_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_grunt_damage", {})
		end

	-- Creature Attack
	elseif string.find(ability_name,"ranged_weapons") then
		if unit_name == "orc_demolisher" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_demolisher_damage", {})
		elseif unit_name == "orc_troll_batrider" then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_batrider_damage", {})
		else
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_bonus_damage", {})
		end
	end
end


-- Puts War Drums at level 2 if the player has the research
function ApplyWarDrumsUpgrade( event )
	local caster = event.caster
	local target = event.target
	local playerID = caster:GetPlayerOwnerID()
	local upgrades = Players:GetUpgradeTable(playerID)
	
	if upgrades["orc_research_improved_war_drums"] then
		caster:RemoveModifierByName("modifier_war_drums_aura")
		
		-- Find all units nearby and remove the buff to re-apply
		local allies_nearby = FindAlliesInRadius(caster, 900)
		for _,ally in pairs(allies_nearby) do
			if ally:HasModifier("modifier_war_drums") then
				ally:RemoveModifierByName("modifier_war_drums")
			end
		end

		local ability = target:FindAbilityByName("orc_war_drums")
		ability:UpgradeAbility(true)
	end
end

-- Upgrade all Kodo Beasts
function UpgradeWarDrums( event )
	local caster = event.caster
	local playerID = caster:GetPlayerOwnerID()
	local playerUnits = Players:GetUnits(playerID)

	for _,unit in pairs(playerUnits) do
		if IsValidEntity(unit) and unit:HasAbility("orc_war_drums") then
			unit:RemoveModifierByName("modifier_war_drums_aura")

			-- Find all units nearby and remove the buff to re-apply
			local allies_nearby = FindAlliesInRadius(unit, 900)
			for _,ally in pairs(allies_nearby) do
				if ally:HasModifier("modifier_war_drums") then
					ally:RemoveModifierByName("modifier_war_drums")
				end
			end

			local ability = unit:FindAbilityByName("orc_war_drums")
			ability:UpgradeAbility(true)
		end
	end
end

function ReinforcedDefenses( event )
	local building = event.caster
	SetArmorType(building, "fortified")
end