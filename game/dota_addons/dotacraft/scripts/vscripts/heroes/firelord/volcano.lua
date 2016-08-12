-- Creates a dummy unit to apply the Volcano aura
function VolcanoStart( event )
    local caster = event.caster
    local point = event.target_points[1]

    caster.volcano_dummy = CreateUnitByName("neutral_volcano", point, false, caster, caster, caster:GetTeam())
    event.ability:ApplyDataDrivenModifier(caster, caster.volcano_dummy, "modifier_volcano_thinker", nil)
end

function StartChannelingAnimation( event )
    local caster = event.caster
    local ability = event.ability
    local interval = ability:GetSpecialValueFor("wave_interval")

    ability.animationTimer = Timers:CreateTimer(function()
        if not caster:IsAlive() or not caster:HasModifier("modifier_volcano_channelling") then return end

        StartAnimation(caster, {duration=2.55, activity=ACT_DOTA_CAST_ABILITY_6, rate=1})
        Timers:CreateTimer(2.6, function()
            if caster:IsAlive() and caster:HasModifier("modifier_volcano_channelling") then
                StartAnimation(caster, {duration=2.35, activity=ACT_DOTA_TELEPORT, rate=1.2})
            end
        end)

        return interval
    end)
end

function StopChannelingAnimation( event )
    Timers:RemoveTimer(event.ability.animationTimer)
    EndAnimation(event.caster)
end

function VolcanoEnd( event )
    local caster = event.caster
    caster:StopSound("Hero_EmberSpirit.FlameGuard.Loop")
    if IsValidEntity(caster.volcano_dummy) then
        caster.volcano_dummy:ForceKill(true)
    end
end

-- Apply knockback, damage and stun to all units but the caster
function VolcanoWave( event )
    local caster = event.caster
    local ability = event.ability
    local wave_damage = ability:GetSpecialValueFor("wave_damage")
    local stun_duration = ability:GetSpecialValueFor("stun_duration")
    local radius = ability:GetSpecialValueFor("radius")
    local abilityDamageType = ability:GetAbilityDamageType()
    local teamNumber = caster:GetTeamNumber()
    local position = caster.volcano_dummy:GetAbsOrigin()
    local targets = FindUnitsInRadius(teamNumber, position, nil, radius/2, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)

    local knockbackModifierTable =
    {
        should_stun = 0,
        knockback_duration = 0.5,
        duration = 0.5,
        knockback_distance = radius/2,
        knockback_height = 20,
        center_x = caster:GetAbsOrigin().x,
        center_y = caster:GetAbsOrigin().y,
        center_z = caster:GetAbsOrigin().z
    }

    for _,unit in pairs(targets) do
        if unit ~= caster and not IsCustomBuilding(unit) and not unit:HasFlyMovementCapability() and not unit:IsWard() then
            unit:AddNewModifier(caster, ability, "modifier_knockback", knockbackModifierTable)
        end
    end  

    Timers:CreateTimer(0.5, function()
        local targets = FindUnitsInRadius(teamNumber, position, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
        for _,unit in pairs(targets) do
            if unit ~= caster then
                if IsCustomBuilding(unit) then
                    DamageBuilding(unit, wave_damage * 2, ability, caster)
                elseif not unit:IsWard() and not unit:HasFlyMovementCapability() then
                    ability:ApplyDataDrivenModifier(caster, unit, "modifier_volcano_stun", {duration = stun_duration})
                    ApplyDamage({ victim = unit, attacker = caster, ability = ability, damage = wave_damage, damage_type = abilityDamageType })
                end
            end
        end
    end)   
end