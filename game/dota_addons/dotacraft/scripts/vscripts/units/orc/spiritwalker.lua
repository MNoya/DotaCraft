function EtherStart( event )
	local caster = event.caster
	local ability = event.ability
	caster:EmitSound('Hero_Pugna.Decrepify')
	ability:ApplyDataDrivenModifier(caster, caster, 'modifier_ethereal_form', {})
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
	caster:RemoveModifierByNameAndCaster('modifier_ethereal_form', caster)
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
	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for k,unit in pairs(units) do
		local bSummon = unit:IsDominated() or unit:HasModifier("modifier_kill")
		if bSummon then
			local damage_to_summons = event.ability:GetSpecialValueFor("damage_to_summons")
			ApplyDamage({victim = unit, attacker = caster, damage = damage_to_summons, damage_type = DAMAGE_TYPE_PURE})
			ParticleManager:CreateParticle("particles/econ/items/enchantress/enchantress_lodestar/ench_death_lodestar_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
		end

		-- This ability removes both positive and negative buffs from units.
		local bRemovePositiveBuffs = true
		local bRemoveDebuffs = true
		local bFrameOnly = false
		local bRemoveStuns = false
		local bRemoveExceptions = false

		unit:Purge(bRemovePositiveBuffs, bRemoveDebuffs, bFrameOnly, bRemoveStuns, bRemoveExceptions)
	end

	RemoveBlight(point, radius)
end

function SpiritLinkStart( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local radius = ability:GetSpecialValueFor('radius')

	ability:ApplyDataDrivenModifier(caster, target, 'modifier_spirit_link', {})
	local units = 1
	local max = ability:GetSpecialValueFor('max_unit')
	local allies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	caster.linked = {}
	local anyunit = false
	while units < max do
		for k,ally in pairs(allies) do
			if units < max and ally ~= caster and (not ally:FindModifierByName('modifier_spirit_link') or anyunit) then
				ability:ApplyDataDrivenModifier(caster, ally, 'modifier_spirit_link', {})
				units = units + 1
			end
		end
		anyunit = true
	end
end

-- IsValidAlive(unit) USE THIS on OnTakeDamge <<<<<<<<<<

function RemoveLinkedUnit( event )
	local linked_units = event.caster.linked
	local unit = event.target
	local i = getIndex(linked_units, unit)
	if i ~= -1 then
		table.remove(linked_units, i)
	else
		print("Invalid index")
	end
end

function AddLinkedUnit( event )
	local linked_units = event.caster.linked
	local unit = event.target
	table.insert(linked_units, unit)
end