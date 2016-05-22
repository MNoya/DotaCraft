function ModelChange( event )
    local caster = event.caster

    --[[
        models/heroes/shadow_fiend/shadow_fiend_head.vmdl
        models/heroes/shadow_fiend/shadow_fiend_arms.vmdl
        models/heroes/shadow_fiend/shadow_fiend_shoulders.vmdl
    ]]

    SwapWearable(caster, "models/heroes/shadow_fiend/shadow_fiend_head.vmdl", "models/heroes/shadow_fiend/head_arcana.vmdl")
    SwapWearable(caster, "models/heroes/shadow_fiend/shadow_fiend_arms.vmdl", "models/items/shadow_fiend/arms_deso/arms_deso.vmdl")

    AddAnimationTranslate(caster, "arcana")

    -- Trail
    local particle = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle, 2, Vector(1,0,0))
    ParticleManager:SetParticleControl(particle, 3, Vector(1,0,0))
    ParticleManager:SetParticleControl(particle, 6, Vector(1,0,0))
end

function DeathEffect( event )
    local caster = event.caster
    local origin = caster:GetAbsOrigin()
    local particle = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_death.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin())
end