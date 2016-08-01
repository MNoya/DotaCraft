function DoomStart(event)
    event.target:SetNoCorpse()
end

function DoomEnd( event )
    local caster = event.caster
    local target = event.unit
    local duration = event.ability:GetSpecialValueFor("doom_guard_duration")

    local doom_guard = caster:CreateSummon("undead_doom_guard", target:GetAbsOrigin(), duration)
    ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, doom_guard)
    ParticleManager:CreateParticle("particles/econ/items/doom/doom_f2p_death_effect/doom_bringer_f2p_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, doom_guard)
    doom_guard:EmitSound("Hero_DoomBringer.LvlDeath")   
    StopSoundEvent("Hero_DoomBringer.Doom", target)
end