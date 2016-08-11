-- Handles the autocast logic
function BloodlustAutocast(event)
    local ability = event.ability
    ability:ToggleAutoCast()
    event.caster.bloodlustAbility = ability
end

function BloodlustAutocast_Attack(event)
    local caster = event.caster
    local attacker = event.attacker
    local unitName = caster:GetUnitName()
    local playerID = caster:GetPlayerOwnerID()

    if attacker:IsMagicImmune() or attacker:HasModifier("modifier_bloodlust") then return end

    -- Check all units and see if there's one valid cast the ability
    local units = Players:GetUnits(playerID)
    local radius = 600
    for _,v in pairs(units) do
        if IsValidEntity(v) and v.bloodlustAbility then
            local ability = v.bloodlustAbility

            -- Get if the ability is on autocast mode and cast the ability on the attacked target
            if ability:GetAutoCastState() and ability:IsFullyCastable() and not v:IsMoving() and v:GetRangeToUnit(attacker) <= radius then
                v:CastAbilityOnTarget(attacker, ability, playerID)
                return
            end
        end
    end
end

function BloodlustAutocast_Attacked(event)
    local caster = event.caster
    local target = event.target
    local playerID = caster:GetPlayerOwnerID()

    if target:IsMagicImmune() or target:HasModifier("modifier_bloodlust") then return end

    -- Check all units and see if there's one valid to cast the ability
    local units = Players:GetUnits(playerID)
    local radius = 600
    for _,v in pairs(units) do
        if IsValidEntity(v) and v.bloodlustAbility then
            local ability = v.bloodlustAbility

            -- Get if the ability is on autocast mode and cast the ability on the attacked target
            if ability:GetAutoCastState() and ability:IsFullyCastable() and not v:IsMoving() and v:GetRangeToUnit(target) <= radius then
                v:CastAbilityOnTarget(target, ability, playerID)
                return
            end
        end
    end
end

----------------------------------------------------------------

function LightningShieldOnSpellStart(event)
    local caster = event.caster
    local ability = event.ability
    local target = event.target
    local duration = ability:GetSpecialValueFor("duration")
    target:EmitSound("Hero_Zuus.StaticField")

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start_bolt_parent.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
    Timers:CreateTimer(0.1, function()
        ability:ApplyDataDrivenModifier(caster, target, 'modifier_lightning_shield', {})
    end)
end

function ModifierLightningShieldOnIntervalThink(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local radius = ability:GetSpecialValueFor("radius")
    local dps = ability:GetSpecialValueFor("damage_per_second")
    local factor = ability:GetSpecialValueFor("think_interval")
    local damage = dps*factor

    local nearby_units = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH,
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES, FIND_ANY_ORDER, false)
    
    for i, nUnit in pairs(nearby_units) do
        if target ~= nUnit then  --The carrier of Lightning Shield cannot damage itself.
            if not nUnit:HasFlyMovementCapability() then
                ApplyDamage({victim = nUnit, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL, ability = ability})
                ParticleManager:CreateParticle("particles/custom/orc/lightning_shield_hit.vpcf", PATTACH_ABSORIGIN, nUnit)
            end
        end
    end
end


function PurgeStart( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local bRemovePositiveBuffs = false
    local bRemoveDebuffs = false
    local bSummoned = target:IsSummoned()

    if target:GetTeamNumber() ~= caster:GetTeamNumber() then
        bRemovePositiveBuffs = true
    else
        bRemoveDebuffs = true
    end
    target:QuickPurge(bRemovePositiveBuffs, bRemoveDebuffs)
    ParticleManager:CreateParticle('particles/generic_gameplay/generic_purge.vpcf', PATTACH_ABSORIGIN_FOLLOW, target)
    target:EmitSound("DOTA_Item.DiffusalBlade.Target")

    if bRemovePositiveBuffs then
        if bSummoned then
            ApplyDamage({
                victim = target,
                attacker = caster,
                damage = ability:GetSpecialValueFor('damage_to_summons'),
                damage_type = DAMAGE_TYPE_PURE, --Goes through MI
                ability = ability
            })
        end
        local duration = ability:GetSpecialValueFor('duration')
        if target:IsHero() or target:IsConsideredHero() then
            duration = ability:GetSpecialValueFor('duration_hero')
        end
        ability:ApplyDataDrivenModifier(caster, target, 'modifier_purge', {duration = duration}) 
    end
end

function ApplyPurge( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local duration = 0 
    local modifier = 'modifier_purge_slow'
    ability:ApplyDataDrivenModifier(caster, target, modifier, nil) 
    target:SetModifierStackCount(modifier, ability, 5)
end

function PurgeThink( event )
    local target = event.target
    local ability = event.ability
    local modifier = 'modifier_purge_slow'
    local new_stack = target:GetModifierStackCount(modifier, nil) - 1
    if new_stack > 0 then
        target:SetModifierStackCount(modifier, ability, new_stack)
    end
end