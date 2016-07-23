function AbolishMagic( event )
	local caster = event.caster
	local target = event.target

	if target:IsSummoned() then
		local damage_to_summons = event.ability:GetSpecialValueFor("damage_to_summons")
		ApplyDamage({victim = target, attacker = caster, damage = damage_to_summons, damage_type = DAMAGE_TYPE_PURE})
		ParticleManager:CreateParticle("particles/econ/items/enchantress/enchantress_lodestar/ench_death_lodestar_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	end

	local bRemovePositiveBuffs = false
	local bRemoveDebuffs = false
	
	-- Remove buffs on enemies or debuffs on allies
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		bRemovePositiveBuffs = true
	else
		bRemoveDebuffs = true
	end
	target:RemoveModifierByName("modifier_brewmaster_storm_cyclone")
	target:Purge(bRemovePositiveBuffs, bRemoveDebuffs, false, false, false)

	ParticleManager:CreateParticle("particles/econ/items/enchantress/enchantress_lodestar/ench_lodestar_transform.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
end

function AbolishMagicAutocast( event )
	local caster = event.caster
	local ability = event.ability
	local autocast_radius = ability:GetCastRange()
	local teamNumber = caster:GetTeamNumber()
	
	-- Get if the ability is on autocast mode and cast the ability on a target
	if ability:GetAutoCastState() and ability:IsFullyCastable() and not caster:IsMoving() then
		
		-- Find targets in radius
		local target
		local units = FindUnitsInRadius(teamNumber, caster:GetAbsOrigin(), nil, autocast_radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES+DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		for k,unit in pairs(units) do
			-- Autocast Abolish Magic on enemy summons
			local bEnemy = unit:GetTeamNumber() ~= teamNumber
			if unit:IsSummoned() and bEnemy then
				target = unit
			
			elseif not IsCustomBuilding(unit) and unit:HasPurgableModifiers(bEnemy) then
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