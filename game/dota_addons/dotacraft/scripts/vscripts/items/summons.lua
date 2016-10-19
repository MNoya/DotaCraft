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

    local unit = caster:CreateSummon(unitName, position, duration)

    if particleName then
        ParticleManager:CreateParticle(particleName,PATTACH_ABSORIGIN_FOLLOW,unit)
    end
end

function DemonicFigurine(event)
    local caster = event.caster
    local position = caster:GetAbsOrigin() + caster:GetForwardVector() * 200
    local duration = event.ability:GetSpecialValueFor("duration")
    local doom_guard = caster:CreateSummon("undead_doom_guard", position, duration)
    ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, doom_guard)
    ParticleManager:CreateParticle("particles/econ/items/doom/doom_f2p_death_effect/doom_bringer_f2p_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, doom_guard)
    doom_guard:EmitSound("Hero_DoomBringer.LvlDeath")
end