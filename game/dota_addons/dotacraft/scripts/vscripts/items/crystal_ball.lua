function Reveal(event)
    local caster = event.caster
    local ability = event.ability
    local level = ability:GetLevel()
    local reveal_radius = ability:GetSpecialValueFor("reveal_radius")
    local duration = ability:GetSpecialValueFor("duration")
    local point = event.target_points[1]

    -- Particle for team
    local fxIndex = ParticleManager:CreateParticleForTeam( "particles/items_fx/dust_of_appearance.vpcf", PATTACH_WORLDORIGIN, caster, caster:GetTeamNumber() )
    ParticleManager:SetParticleControl( fxIndex, 0, point )
    ParticleManager:SetParticleControl( fxIndex, 1, Vector(reveal_radius,0,reveal_radius) )

    ability:CreateVisibilityNode(point, reveal_radius, duration)
end