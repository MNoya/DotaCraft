function EtherStart( event )
	local caster = event.caster
	local ability = event.ability
	caster:EmitSound('Hero_Pugna.Decrepify')
	ability:ApplyDataDrivenModifier(caster, caster, 'modifier_ethereal', {})
	local cooldown = ability:GetCooldown(0)
	ability:StartCooldown(cooldown)
	local another = caster:FindAbilityByName('orc_corporeal_form')
	another:StartCooldown(cooldown)
	ability:SetHidden(true)
	another:SetHidden(false)
end

function EtherEnd( event )
	local caster = event.caster
	local ability = event.ability
	caster:RemoveModifierByNameAndCaster('modifier_ethereal', caster)
	local another = caster:FindAbilityByName('orc_ethereal_form')
	ability:SetHidden(true)
	another:SetHidden(false)
end

function Disenchant( event )
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]
	local radius = ability:GetSpecialValueFor("radius")
		
	-- Find targets in radius
	local units = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES+DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	for k,unit in pairs(units) do
		local bSummon = unit:IsSummoned() or unit:HasModifier("modifier_kill")
		if bSummon then
			local damage_to_summons = event.ability:GetSpecialValueFor("damage_to_summons")
			ApplyDamage({victim = unit, attacker = caster, damage = damage_to_summons, damage_type = DAMAGE_TYPE_PURE})
			ParticleManager:CreateParticle("particles/econ/items/enchantress/enchantress_lodestar/ench_death_lodestar_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
		end

		-- This ability removes both positive and negative buffs from units.
		local bRemovePositiveBuffs = true
		local bRemoveDebuffs = true
		unit:Purge(bRemovePositiveBuffs, bRemoveDebuffs, false, false, false)
	end

	RemoveBlight(point, radius)
end

function SpiritLinkStart( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local radius = ability:GetSpecialValueFor('radius')

	local units = 1
	local max = ability:GetSpecialValueFor('max_unit')
	local allies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	if caster.linked == nil then
		caster.linked = {}
	end
	ability:ApplyDataDrivenModifier(caster, target, 'modifier_spirit_link', {})
	local anyunit = false
	while units < max do
		for k,ally in pairs(allies) do
			if units < max and (not ally:FindModifierByName('modifier_spirit_link') or anyunit or ally ~= caster) then
				ability:ApplyDataDrivenModifier(caster, ally, 'modifier_spirit_link', {})
				units = units + 1
			end
		end
		anyunit = true
	end
end

function RemoveLinkedUnit( event )
	local unit = event.target
	if IsValidEntity(unit) then
		-- print('=======================')
		local i = getIndex(event.caster.linked, unit:GetEntityIndex())
		if i ~= -1 then
			table.remove(event.caster.linked, i)
			-- print('Unit removed from table')
		else
			-- print("Invalid index")
		end
		-- print('=======================')
	end
end

function AddLinkedUnit( event )
	local unit = event.target
	table.insert(event.caster.linked, unit:GetEntityIndex())
end

function LinkDamage( event )
	local attacker = event.attacker
	local target = event.unit
	local damage = event.Damage
	local ability = event.ability
	local factor = ability:GetSpecialValueFor('distribution_factor') 

	if IsValidAlive(target) then
		target:Heal(damage * factor, attacker)
	end

	local j = TableFindKey(event.caster.linked, target:GetEntityIndex())
	local k = TableCount(event.caster.linked)

	-- DeepPrintTable(event.caster.linked)
	if not j then j = -1 end
	-- print('=======================')
	-- print('Damage on main target: ' .. damage * factor)
	-- print('Index of main target: ' .. j)
	-- print('Table general count: ' .. k)
	-- print('=======================')
	if k-1 > 0 then
		local dist_damage = (damage * factor) / (k-1)
		for i=1,k do
			if i ~= j then
				if event.caster.linked[i] then
					local linked = EntIndexToHScript(event.caster.linked[i])
					if IsValidAlive(linked) then
						local new_health = linked:GetHealth() - dist_damage
						if new_health < 1 then
							new_health = 1
							linked:RemoveModifierByName('modifier_spirit_link')
						end
						linked:SetHealth(new_health)
						-- print('=======================')
						-- print('Damage on linked unit: ' .. dist_damage)
						-- print('Index of linked unit: ' .. i)
						-- print('=======================')
					end
				end
			end
		end
	end
end

-- Resurrects units near the caster, using the corpse mechanic.
function AncestralSpirit( event )
	local caster = event.caster
	local ability = event.ability
	local player = event.caster:GetPlayerOwnerID()
	local team = event.caster:GetTeamNumber()
	local radius = ability:GetCastRange()
	local health_factor = ability:GetSpecialValueFor('life_restored')
	local mana_factor = ability:GetSpecialValueFor('mana_restored')

	-- Find all corpse entities in the radius and start the counter of units resurrected.
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), radius)

	-- Go through the units
	for _, unit in pairs(targets) do
		-- The corpse has a unit_name associated.
		if unit.unit_name == 'orc_tauren' then
			local resurected = CreateUnitByName(unit.unit_name, unit:GetAbsOrigin(), true, caster, caster, team)
			resurected:SetControllableByPlayer(player, true)
			resurected:SetHealth(resurected:GetMaxHealth() * health_factor)
			resurected:SetMana(resurected:GetMaxMana() * mana_factor)
			-- Leave no corpses
			resurected.no_corpse = true
			unit:RemoveSelf()
			break
		end
	end
end

-- Denies casting if no tauren corpses near, with a message
function AncestralSpiritPrecast( event )
	local ability = event.ability
	local caster = event.caster
	local radius = ability:GetCastRange()
	local corpse = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), radius)
	for k, v in pairs(corpse) do
		print(k,v)
		if v.unit_name == 'orc_tauren' then
			return
		end
	end

	event.caster:Interrupt()
	SendErrorMessage(pID, "#error_no_usable_corpses")
end