-- Creates Inferno Particle
function SummonInferno(event)
    local inferno_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_rain_of_chaos_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, event.target)
    local inferno_landed = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_rain_of_chaos_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, event.target)
    ParticleManager:SetParticleControl(inferno_landed, 0, event.target:GetAbsOrigin())
end