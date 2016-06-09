--[[
    Author: Noya
    Creates a dummy unit to apply the Rain of Fire thinker modifier which does the waves
]]
function RainOfFireStart( event )
    local caster = event.caster
    local point = event.target_points[1]
    local ability = event.ability

    caster.fire_storm_dummy = CreateUnitByName("dummy_unit_vulnerable", point, false, caster, caster, caster:GetTeam())
    event.ability:ApplyDataDrivenModifier(caster, caster.fire_storm_dummy, "modifier_rain_of_fire_thinker", {duration=ability:GetChannelTime()-0.5})
end

function ApplyAnimation(event)
    local ability = event.ability
    local caster = event.caster
    local start_time = ability:GetChannelStartTime()
    local time_channeled = GameRules:GetGameTime() - start_time
    local max_channel_time = ability:GetChannelTime()

    if ability:IsChanneling() and (time_channeled < max_channel_time - 1) then
        caster:StartGesture(ACT_DOTA_SPAWN)
    end
end

function RainOfFireWave(event)
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetSpecialValueFor("radius")
    local damage = ability:GetLevelSpecialValueFor("wave_damage",ability:GetLevel()-1)
    local max_wave_damage = ability:GetLevelSpecialValueFor("max_wave_damage",ability:GetLevel()-1)
    local target_position = event.target:GetAbsOrigin() --event.target_points[1]
    local particleName = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"
    local distance = 100

    local particle1 = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl( particle1, 0, target_position )

    local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_rain_of_chaos_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl( particle2, 0, target_position )

    local particle3 = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_sun_strike.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl( particle3, 0, target_position )

    ability:ApplyDamageUnitsMax(damage, FindAllUnitsInRadius(caster, radius, target_position), max_wave_damage)
end

function RainOfFireEnd( event )
    local caster = event.caster

    caster.fire_storm_dummy:RemoveSelf()
end