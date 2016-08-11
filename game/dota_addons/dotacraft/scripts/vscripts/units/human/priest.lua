-- Handles AutoCast Logic
function HealAutocast( event )
	local caster = event.caster
	local ability = event.ability
	local autocast_radius = ability:GetCastRange()

	-- Get if the ability is on autocast mode and cast the ability on a valid target
	local lowestPercent = 100
	if ability:GetAutoCastState() and ability:IsFullyCastable() and not caster:IsMoving() then
		-- Find damaged targets in radius
		local target
		local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, autocast_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
		for k,unit in pairs(allies) do
			-- Target the lowest health ally
			if not IsCustomBuilding(unit) and not unit:IsMechanical() and not unit:IsWard() and unit:GetHealthPercent() < lowestPercent then
				target = unit
				lowestPercent = unit:GetHealthPercent()
			end
		end

		if target then
			caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())
		end
	end	
end

----------------------------------------------------------------

function InnerFireAutocast(event)
    local ability = event.ability
    event.caster.innerfireAbility = ability
end

function InnerFireAutocast_Attack( event )
    local caster = event.caster
    local attacker = event.attacker
    local unitName = caster:GetUnitName()
    local playerID = caster:GetPlayerOwnerID()

    if attacker:IsMagicImmune() or attacker:HasModifier("modifier_inner_fire") then return end

    -- Check all units and see if there's one valid cast the ability
    local units = Players:GetUnits(playerID)
    local radius = 500
    for _,v in pairs(units) do
        if IsValidEntity(v) and v.innerfireAbility then
            local ability = v.innerfireAbility

            -- Get if the ability is on autocast mode and cast the ability on the attacked target
            if ability:GetAutoCastState() and ability:IsFullyCastable() and not v:IsMoving() and v:GetRangeToUnit(attacker) <= radius then
                v:CastAbilityOnTarget(attacker, ability, playerID)
                return
            end
        end
    end
end

function InnerFireAutocast_Attacked( event )
    local caster = event.caster
    local target = event.target
    local playerID = caster:GetPlayerOwnerID()

    if target:IsMagicImmune() or target:HasModifier("modifier_inner_fire") then return end

    -- Check all units and see if there's one valid to cast the ability
    local units = Players:GetUnits(playerID)
    local radius = 600
    for _,v in pairs(units) do
        if IsValidEntity(v) and v.innerfireAbility then
            local ability = v.innerfireAbility

            -- Get if the ability is on autocast mode and cast the ability on the attacked target
            if ability:GetAutoCastState() and ability:IsFullyCastable() and not v:IsMoving() and v:GetRangeToUnit(target) <= radius then
                v:CastAbilityOnTarget(target, ability, playerID)
                return
            end
        end
    end
end

----------------------------------------------------------------

-- Dispel Magic removes buffs from enemy units, removes debuffs from allies, and deals damage to summoned units
-- Used on human_dispel_magic and pandaren_storm_dispel_magic
function DispelMagic( event )
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]
	local radius = ability:GetSpecialValueFor("radius")
	local damage_to_summons = ability:GetSpecialValueFor("damage_to_summons")
		
	-- Find targets in radius
	local targets = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES+DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
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
		target:QuickPurge(bRemovePositiveBuffs, bRemoveDebuffs)
	end

	Blight:Dispel(point)
end