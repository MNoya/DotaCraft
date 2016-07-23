-- Handles AutoCast Logic
function HealAutocast( event )
	local caster = event.caster
	local ability = event.ability
	local autocast_radius = ability:GetSpecialValueFor("autocast_radius")

	-- Get if the ability is on autocast mode and cast the ability on a valid target
	local lowestPercent = 100
	if ability:GetAutoCastState() and ability:IsFullyCastable() and not caster:IsMoving() then
		-- Find damaged targets in radius
		local target
		local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, autocast_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
		for k,unit in pairs(allies) do
			-- Target the lowest health ally
			if not IsCustomBuilding(unit) and not unit:IsMechanical() and unit:GetHealthPercent() < lowestPercent then
				target = unit
				lowestPercent = unit:GetHealthPercent()
			end
		end

		if target then
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
	if ability:GetAutoCastState() and ability:IsFullyCastable() and not caster:IsMoving() then
		-- Find non buffed targets in radius
		local target
		local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, autocast_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
		for k,unit in pairs(allies) do
			if not IsCustomBuilding(unit) and not unit:HasModifier(modifier_name) then
				target = unit
				break
			end
		end

		if target then
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

-- Dispel Magic removes buffs from enemy units, removes debuffs from allies, and deals damage to summoned units
-- Used on human_dispel_magic and pandaren_storm_dispel_magic
function DispelMagic( event )
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]
	local radius = ability:GetSpecialValueFor("radius")
	local damage_to_summons = ability:GetSpecialValueFor("damage_to_summons")
		
	-- Find targets in radius
	local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES+DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	for k,target in pairs(targets) do
		if target:IsSummoned() then
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
	end

	Blight:Dispel(point)
end