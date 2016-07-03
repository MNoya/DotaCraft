-- Handles AutoCast Logic
function HealAutocast( event )
	local caster = event.caster
	local ability = event.ability
	local autocast_radius = ability:GetSpecialValueFor("autocast_radius")

	-- Get if the ability is on autocast mode and cast the ability on a valid target
	local highestDeficit = 0
	if ability:GetAutoCastState() and ability:IsFullyCastable() then
		-- Find damaged targets in radius
		local target
		local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, autocast_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
		for k,unit in pairs(allies) do
			-- Target the lowest health ally
			if not IsCustomBuilding(unit) and not unit:IsMechanical() and unit:GetHealthDeficit() > highestDeficit then
				target = unit
				highestDeficit = unit:GetHealthDeficit()
			end
		end

		if not target then
			return
		else
			caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())
		end
	end	
end

function InnerFireAutocast( event )
	local caster = event.caster
	local ability = event.ability
	local autocast_radius = ability:GetSpecialValueFor("autocast_radius")
	local modifier_name = "modifier_inner_fire"
	
	-- Get if the ability is on autocast mode and cast the ability on a target that doesn't have the modifier
	if ability:GetAutoCastState() and ability:IsFullyCastable() then
		-- Find non buffed targets in radius
		local target
		local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, autocast_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
		for k,unit in pairs(allies) do
			if not IsCustomBuilding(unit) and unit:HasModifier(modifier_name) then
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

-- Automatically toggled on
function ToggleOnAutocast( event )
	local caster = event.caster
	local ability = event.ability

	ability:ToggleAutoCast()
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