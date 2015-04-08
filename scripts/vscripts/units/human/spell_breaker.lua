--[[Mana drain and damage part of Mana Break
	Author: Pizzalol
	Date: 16.12.2014.
	NOTE: Currently works on magic immune enemies, can be fixed by checking for magic immunity before draining mana and dealing damage]]
function ManaBreak( keys )
	local target = keys.target
	local caster = keys.caster
	local ability = keys.ability
	local manaBurn = ability:GetLevelSpecialValueFor("mana_per_hit", (ability:GetLevel() - 1))
	local manaDamage = ability:GetLevelSpecialValueFor("damage_per_burn", (ability:GetLevel() - 1))

	local damageTable = {}
	damageTable.attacker = caster
	damageTable.victim = target
	damageTable.damage_type = ability:GetAbilityDamageType()
	damageTable.ability = ability
	damageTable.damage_flags = DOTA_UNIT_TARGET_FLAG_NONE -- Doesnt seem to work?

	-- Checking the mana of the target and calculating the damage
	if(target:GetMana() >= manaBurn) then
		damageTable.damage = manaBurn * manaDamage
		target:ReduceMana(manaBurn)
	else
		damageTable.damage = target:GetMana() * manaDamage
		target:ReduceMana(manaBurn)
	end

	ApplyDamage(damageTable)
end


--[[
	Transfer buff/debuffs to ally/enemy
	Author: Noya
	Date: April 2, 2015.
]]
function SpellSteal( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local transfer_modifier = ""
	local radius = 600
	local modCount = target:GetModifierCount()

	local modifier_type
	local team_type
	if target:GetTeamNumber() == caster:GetTeamNumber() then
		-- Cast on friendly unit. Remove the first negative debuff and apply it to a random enemy unit
		modifier_type = "negative"
		team_type = DOTA_UNIT_TARGET_TEAM_ENEMY
	else
		-- Cast on enemy unit. Remove the first positive debuff and apply it to a random friendly unit
		modifier_type = "positive"
		team_type = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	end

	-- Go through all the modifiers checking the first purgable, of the selected type
	for i = 0, modCount do
		local modifier_name = target:GetModifierNameByIndex(i)
		if ModifierCanBePurged(modifier_name, modifier_type) then
			target:RemoveModifierByName(modifier_name)
			transfer_modifier = modifier_name
			break
		end
	end

	print("Modifier to transfer: "..transfer_modifier)
	if transfer_modifier ~= "" then

		-- Find units and apply
		local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, 
						team_type, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		if units then
			local random_target = units[RandomInt(1, #units)]
			if IsValidEntity(random_target) then

				-- Get the ability name and duration directly from the modifier table
				local modifier_table = GameRules.Modifiers
				local modifier = modifier_table[transfer_modifier]
				DeepPrintTable(modifier)
				local ability_name = modifier.Ability
				local modifier_duration = modifier.Duration
				print(ability_name, modifier_duration)

				-- Add the ability to a dummy unit, used to apply the modifier
				local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
				dummy:SetOwner(caster:GetOwner()) -- This should be the hero
				dummy:AddAbility(ability_name)

				local new_ability = dummy:FindAbilityByName(ability_name)
				if new_ability then
					new_ability:SetLevel(new_ability:GetMaxLevel())
					new_ability:ApplyDataDrivenModifier(caster, random_target, transfer_modifier, { duration = modifier_duration })
					print("Spell Steal applies "..transfer_modifier.." on "..random_target:GetUnitName().." for "..modifier_duration.." seconds")
				else
					print("ERROR, Ability name "..ability_name.." not found")
				end		
			end
		end
	end
end


-- Check if the custom modifier exists in the table of purgable modifiers, and the buff/debuff type
function ModifierCanBePurged( modifier_name, modifier_type)
	local modifier_table = GameRules.Modifiers
	local modifier = modifier_table[modifier_name]

	if modifier and modifier.Ability then
		print("modifier values:", modifier.Ability, modifier.IsDebuff, modifier.IsBuff)
		if modifier_type == "negative" then
			if modifier.IsDebuff and modifier.IsDebuff == 1 then
				print("ModifierCanBePurged (debuff) "..modifier.Ability)
				return true
			end
		elseif modifier_type == "positive" then
			if modifier.IsBuff and modifier.IsBuff == 1 then
				print("ModifierCanBePurged (buff) "..modifier.Ability)
				return true
			end
		end
	end
	return false
end

-- Denies cast on units that arent summons and check if the unit has enough mana cost to dominate it
function ControlMagicCheck( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local pID = caster:GetPlayerID()
	
	if not target:IsSummoned() then
		caster:Interrupt()
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Need to target a Summoned Unit!" } )
	else
		local targetHP = target:GetHealth()
		local casterMana = caster:GetMana()
		local mana_control_rate = ability:GetLevelSpecialValueFor("mana_control_rate", ability:GetLevel() - 1 )
		local mana_cost = targetHP*mana_control_rate
		if manaCost > casterMana then
			caster:Interrupt()
			FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Not enough mana to control this unit, need "..mana_cost } )
		end
	end
end

-- Takes control of the target
function ControlMagic( event )
	local caster = event.caster
	local target = event.target

	-- Change ownership
	print("Control Magic")
	target:Stop()
    target:SetTeam( caster:GetTeamNumber() )
    target:SetOwner(caster)
    target:SetControllableByPlayer( caster:GetPlayerOwnerID(), true )
    target:RespawnUnit()
    target:SetHealth(target:GetHealth())
end