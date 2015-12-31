function SelfTeleport( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability

    caster:EmitSound("Hero_Chen.TeleportOut")
    ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_test_of_faith.vpcf", PATTACH_ABSORIGIN, caster)
    -- Add another particle effect on target
    FindClearSpaceForUnit(caster, target:GetAbsOrigin(), true)
end