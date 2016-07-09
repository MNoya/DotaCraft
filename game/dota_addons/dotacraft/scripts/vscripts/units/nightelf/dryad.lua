function AbolishMagic( event )
	local caster = event.caster
	local target = event.target

	local bSummon = target:IsSummoned() or target:HasModifier("modifier_kill")
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

	ParticleManager:CreateParticle("particles/econ/items/enchantress/enchantress_lodestar/ench_lodestar_transform.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
end

function AbolishMagicAutocast( event )
	local caster = event.caster
	local ability = event.ability
	local autocast_radius = ability:GetCastRange()
	
	-- Get if the ability is on autocast mode and cast the ability on a target
	if ability:GetAutoCastState() and ability:IsFullyCastable() then
		
		-- Find targets in radius
		local target
		local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, autocast_radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for k,unit in pairs(units) do
			-- Autocast Abolish Magic on enemy summons
			if unit:IsSummoned() and unit:GetTeamNumber() ~= caster:GetTeamNumber() then
				target = unit
			
			elseif not IsCustomBuilding(unit) and UnitHasPurgableModifiers(unit,caster) then
				target = unit
				break
			end
		end

		if not target then
			return
		else 
			caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())
		end
	end
end

function UnitHasPurgableModifiers( unit, caster )
	local allModifiers = unit:FindAllModifiers()

	-- Only attempt to take buffs from enemies and debuffs from allies
	if unit:GetTeamNumber() ~= caster:GetTeamNumber() then
		for _,modifier in pairs(allModifiers) do
			if IsPurgableModifier( modifier ) and not IsDebuff(modifier) then
				return true
			end
		end
	else
		for _,modifier in pairs(allModifiers) do
			if IsPurgableModifier( modifier ) and IsDebuff(modifier) then
				return true
			end
		end
	end
	return false
end