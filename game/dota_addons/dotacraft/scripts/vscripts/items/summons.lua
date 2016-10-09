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

    local unit = CreateUnitByName(unitName,position,true,caster,caster,caster:GetTeamNumber())
    unit:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
    unit:SetForwardVector(fv)
    unit:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
    unit:AddNewModifier(caster, nil, "modifier_summoned", {})
    unit.no_corpse = true

    if particleName then
        ParticleManager:CreateParticle(particleName,PATTACH_ABSORIGIN_FOLLOW,unit)
    end
end