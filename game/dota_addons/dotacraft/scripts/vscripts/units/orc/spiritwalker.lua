function EtherStart( event )
	local caster = event.caster
	local ability = event.ability
	if caster:FindModifierByNameAndCaster('modifier_etheral_form', caster) then
		caster:RemoveModifierByNameAndCaster('modifier_etheral_form', caster)
		local cooldown = ability:GetSpecialValueFor('cooldown')
		ability:StartCooldown(cooldown)
	else
		caster:EmitSound('Hero_Pugna.Decrepify')
		local delay = ability:GetSpecialValueFor('delay')
		Timers:CreateTimer(delay, function ()
			ability:ApplyDataDrivenModifier(caster, caster, 'modifier_etheral_form', {})
		end
		)
	end
end

function DispelMagic( event )
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]
	local radius = ability:GetSpecialValueFor("radius")
		
	-- Find targets in radius
	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for k,unit in pairs(units) do
		event.target = unit
		Dispel(event)
	end

	RemoveBlight(point, radius)
end

function Dispel( event )
	local caster = event.caster
	local target = event.target

	local bSummon = target:IsDominated() or target:HasModifier("modifier_kill")
	if bSummon then
		local damage_to_summons = event.ability:GetSpecialValueFor("damage_to_summons")
		ApplyDamage({victim = target, attacker = caster, damage = damage_to_summons, damage_type = DAMAGE_TYPE_PURE})
		ParticleManager:CreateParticle("particles/econ/items/enchantress/enchantress_lodestar/ench_death_lodestar_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	end

	local bRemovePositiveBuffs = false
	local bRemoveDebuffs = false
	local bFrameOnly = false
	local bRemoveStuns = false
	local bRemoveExceptions = false

	-- Remove buffs on enemies or debuffs on allies
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		bRemovePositiveBuffs = true
	else
		bRemoveDebuffs = true
	end

	target:Purge(bRemovePositiveBuffs, bRemoveDebuffs, bFrameOnly, bRemoveStuns, bRemoveExceptions)
end