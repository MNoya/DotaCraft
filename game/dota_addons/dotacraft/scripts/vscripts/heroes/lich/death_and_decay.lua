--[[
    Author: Noya
    Creates a dummy unit to apply the Death and Decay thinker modifier which does the waves
    Does health percentage damage based on every target
]]
function DeathAndDecayStart( event )
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetSpecialValueFor("radius")
    local point = event.target_points[1]

    caster.death_and_decay_dummy = CreateUnitByName("dummy_unit", point, false, caster, caster, caster:GetTeam())
    ability:ApplyDataDrivenModifier(caster, caster.death_and_decay_dummy, "modifier_death_and_decay_thinker", nil)

    ability.particle1 = ParticleManager:CreateParticle("particles/units/heroes/hero_enigma/enigma_blackhole_n.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(ability.particle1, 0, point)
    ParticleManager:SetParticleControl(ability.particle1, 1, point)

    ability.particle2 = ParticleManager:CreateParticle("particles/custom/enigma_midnight_pulse.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(ability.particle2, 0, point)
    ParticleManager:SetParticleControl(ability.particle2, 1, Vector(radius, 0, 0))

    caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)
    Timers:CreateTimer(1.5, function()
        if ability:IsChanneling() then
            caster:RemoveGesture(ACT_DOTA_CAST_ABILITY_4)
            caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)
            return 1
        end
    end)
end

function DeathAndDecayEnd( event )
    local caster = event.caster
    local ability = event.ability
    caster:StopSound("Hero_Lich.ChainFrostLoop")
    ParticleManager:DestroyParticle(ability.particle1,false)
    ParticleManager:DestroyParticle(ability.particle2,false)
    UTIL_Remove(caster.death_and_decay_dummy)
end

function DeathAndDecayDamage( event )
    local caster = event.caster
    local ability = event.ability
    local targets = event.target_entities
    local health_percent_damage_per_sec = ability:GetLevelSpecialValueFor( "health_percent_damage_per_sec" , ability:GetLevel() - 1  ) * 0.01

    for _,target in pairs(targets) do
        if not target:IsDummy() then
            local newHP = target:GetHealth() - (target:GetMaxHealth() * health_percent_damage_per_sec)

            -- Apply particle on each damaged targed
            local particle = ParticleManager:CreateParticle("particles/custom/enigma_malefice.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
            Timers:CreateTimer(1, function() ParticleManager:DestroyParticle(particle,false) end)

            -- If the HP would hit 0 with this damage, kill the unit
            if newHP <= 0 then
                target:Kill(nil, caster)
            else
                target:SetHealth(newHP)
            end
        end
    end
end