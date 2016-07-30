function FlameStrikeOrbThrow(event)
    local caster = event.caster
    local ability = event.ability
    local point = event.target_points[1]

    -- Remove first orb
    local orbNumber
    for i=1,3 do
        if caster.orbs[i] then
            ParticleManager:DestroyParticle(caster.orbs[i], true)
            caster.orbs[i] = nil
            orbNumber = i
            break
        end
    end

    -- Launch orb
    local speed = 900
    local orb = ParticleManager:CreateParticle("particles/units/heroes/hero_rubick/rubick_base_attack.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(orb, 0, caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1")))
    ParticleManager:SetParticleControl(orb, 1, point)
    ParticleManager:SetParticleControl(orb, 2, Vector(speed, 0, 0))
    ParticleManager:SetParticleControl(orb, 3, point)

    local distanceToTarget = (caster:GetAbsOrigin() - point):Length2D()
    Timers:CreateTimer(distanceToTarget/speed, function()
        ParticleManager:DestroyParticle(orb, false)
    end)

    -- Restore orb
    Timers:CreateTimer(1, function() 
        if orbNumber then
            caster.orbs[orbNumber] = ParticleManager:CreateParticle("particles/custom/human/blood_mage/exort_orb.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
            ParticleManager:SetParticleControlEnt(caster.orbs[orbNumber], 1, caster, PATTACH_POINT_FOLLOW, "attach_orb"..orbNumber, caster:GetAbsOrigin(), false)
        else
            for i=1,3 do
                caster.orbs[i] = ParticleManager:CreateParticle("particles/custom/human/blood_mage/exort_orb.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
                ParticleManager:SetParticleControlEnt(caster.orbs[i], 1, caster, PATTACH_POINT_FOLLOW, "attach_orb"..i, caster:GetAbsOrigin(), false)
            end
        end
    end)
end

function FlameStrikeStart(event)
    local caster = event.caster
    local point = event.target_points[1]
    StartAnimation(caster, {duration=1, activity=ACT_DOTA_CAST_TORNADO, rate=1})

    local particle1 = ParticleManager:CreateParticle("particles/custom/human/blood_mage/invoker_sun_strike_team_immortal1.vpcf",PATTACH_CUSTOMORIGIN,caster)
    ParticleManager:SetParticleControl(particle1,0,point)

    local particle2 = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_requiemofsouls_line_ground.vpcf",PATTACH_CUSTOMORIGIN,caster)
    ParticleManager:SetParticleControl(particle2,0,point)

    local ability = event.ability
    Timers:CreateTimer(ability:GetSpecialValueFor("delay"), function()
        local flame_strike = CreateUnitByName("dummy_unit_vulnerable", point, false, caster, caster, caster:GetTeam())
        event.ability:ApplyDataDrivenModifier(caster, flame_strike, "modifier_flame_strike_thinker1", nil)
        Timers:CreateTimer(2.1, function()
            if IsValidEntity(flame_strike) then flame_strike:ForceKill(true) end
        end)
    end)
end

function FlameStrikeSecond(event)
    local caster = event.caster
    local origin = event.target:GetAbsOrigin()
    local flame_strike = CreateUnitByName("dummy_unit_vulnerable", origin, false, caster, caster, caster:GetTeam())
    event.ability:ApplyDataDrivenModifier(caster, flame_strike, "modifier_flame_strike_thinker2", nil)
    Timers:CreateTimer(6.0, function()
        if IsValidEntity(flame_strike) then flame_strike:ForceKill(true) end
    end)
end

function FlameStrikeDamage(event)
    local ability = event.ability
    local caster = event.caster
    local targets = event.target_entities
    local damage = event.Damage
    local buildingReduction = ability:GetKeyValue("BuildingReduction")

    if targets then
        for k,target in pairs(targets) do
            local damageDone = damage
            if IsCustomBuilding(target) then
                DamageBuilding(target, damage*buildingReduction, ability, caster)
            else
                ApplyDamage({ victim = target, attacker = caster, damage = damageDone, ability = ability, damage_type = ability:GetAbilityDamageType() })
            end
        end
    elseif event.target then
        local target = event.target
        local damageDone = damage
        if IsCustomBuilding(target) then
            DamageBuilding(target, damage*buildingReduction, ability, caster)
        else
            ApplyDamage({ victim = target, attacker = caster, damage = damageDone, ability = ability, damage_type = ability:GetAbilityDamageType() })
        end
    end 
end