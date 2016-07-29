function SummonElemental(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel()-1)
    local position = caster:GetAbsOrigin() + caster:GetForwardVector() * 200
    local elementalName = "human_water_elemental_"..ability:GetLevel()

    local elemental = caster:CreateSummon(elementalName, position, duration)
    ParticleManager:CreateParticle("particles/units/heroes/hero_morphling/morphling_replicate_finish.vpcf", PATTACH_ABSORIGIN_FOLLOW, elemental)
    elemental:EmitSound("Hero_Morphling.Replicate")
end