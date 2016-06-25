function SummonInFront(event)
    local caster = event.caster
    local ability = event.ability
    local origin = caster:GetAbsOrigin()
    local distance = event.Distance
    local fv = caster:GetForwardVector()
    local position = origin + fv * distance
    local unitName = event.Unit
    local particleName = event.Particle
    local duration = event.Duration

    local unit = CreateUnitByName(unitName,point,true,caster,caster,caster:GetTeamNumber())
    unit:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
    unit:SetForwardVector(fv)
    unit:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
    unit:AddNewModifier(caster, nil, "modifier_summoned", {})
    unit.no_corpse = true

    if particleName then
        ParticleManager:CreateParticle(particleName,PATTACH_ABSORIGIN_FOLLOW,unit)
    end
end

function SummonHealingWard(event)
    local caster = event.caster
    local ability = event.ability
    local origin = event.caster:GetAbsOrigin()
    local point = event.target_points[1]
    local duration = ability:GetSpecialValueFor("duration")
    local sentry = CreateUnitByName('warcraft_healing_ward', point, false, caster, caster, caster:GetTeamNumber())
    sentry:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
    sentry:AddNewModifier(caster, nil, "modifier_summoned", {})
    sentry:EmitSound("DOTA_Item.ObserverWard.Activate")
end

function SummonSentryWard(event)
    local caster = event.caster
    local ability = event.ability
    local origin = event.caster:GetAbsOrigin()
    local point = event.target_points[1]
    local duration = ability:GetSpecialValueFor("duration")
    local sentry = CreateUnitByName('warcraft_sentry_ward', point, false, caster, caster, caster:GetTeamNumber())
    ability:ApplyDataDrivenModifier(sentry,sentry,"modifier_sentry_ward",{})
    sentry:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
    sentry:AddNewModifier(caster, nil, "modifier_summoned", {})
    sentry:EmitSound("DOTA_Item.ObserverWard.Activate")
end