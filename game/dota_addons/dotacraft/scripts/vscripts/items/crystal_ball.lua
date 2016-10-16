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

    AddFOWViewer(caster:GetTeamNumber(),point,reveal_radius,duration,false)

    local dummy = CreateUnitByName("npc_dota_thinker", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
    EmitSoundOnLocationForAllies(point,"DOTA_Item.DustOfAppearance.Activate",dummy)
    Timers:CreateTimer(5, function() UTIL_Remove(dummy) end)
end