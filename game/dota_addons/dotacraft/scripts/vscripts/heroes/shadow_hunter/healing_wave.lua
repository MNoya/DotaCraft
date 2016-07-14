--[[
    Author: Noya
    Bounces from the main target to nearby targets in range. Avoids bouncing to full health units
]]
function HealingWave( event )
    local hero = event.caster
    local target = event.target
    local ability = event.ability
    local bounces = ability:GetLevelSpecialValueFor("max_bounces", ability:GetLevel()-1)
    local healing = ability:GetLevelSpecialValueFor("healing", ability:GetLevel()-1)
    local decay = ability:GetSpecialValueFor("wave_decay_percent")  * 0.01
    local radius = ability:GetSpecialValueFor("bounce_range")
    local time_between_bounces = 0.3

    local start_position = caster:GetAbsOrigin()
    local attach_attack1 = caster:ScriptLookupAttachment("attach_attack1")
    if attach_attack1 ~= 0 then
        start_position = caster:GetAttachmentOrigin(attach_attack1)
    else
        start_position.z = start_position.z + target:GetBoundingMaxs().z
    end
    local current_position = CreateHealingWave(caster, caster:GetAbsOrigin(), target, healing, ability)
    bounces = bounces - 1 --The first hit counts as a bounce

    -- Every target struck by the chain is added to an entity index list
    local targetsStruck = {}
    targetsStruck[target:GetEntityIndex()] = true

    -- do bounces from target to new targets
    Timers:CreateTimer(time_between_bounces, function()
    
        -- unit selection and counting
        local allies = FindOrganicAlliesInRadius(caster, radius, current_position)

        if #allies > 0 then

            -- Hit the first unit with health deficit that hasn't been struck yet
            local bounce_target
            for _,unit in pairs(units) do
                local entIndex = unit:GetEntityIndex()
                if not targetsStruck[entIndex] and unit:GetHealthDeficit() > 0 then
                    bounce_target = unit
                    targetsStruck[entIndex] = true
                    break
                end
            end

            if bounce_target then
                -- heal and decay
                healing = healing - (healing*decay)
                current_position = CreateHealingWave(caster, current_position, bounce_target, healing, ability)

                -- decrement remaining spell bounces
                bounces = bounces - 1

                -- fire the timer again if spell bounces remain
                if bounces > 0 then
                    return time_between_bounces
                end
            end
        end
    end)
end

function CreateHealingWave(caster, start_position, target, healing, ability)
    local target_position = target:GetAbsOrigin()
    local attach_hitloc = target:ScriptLookupAttachment("attach_hitloc")
    if attach_hitloc ~= 0 then
        target_position = target:GetAttachmentOrigin(attach_hitloc)
    else
        target_position.z = target_position.z + target:GetBoundingMaxs().z
    end

    local particle = ParticleManager:CreateParticle("particles/custom/dazzle_shadow_wave.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
    ParticleManager:SetParticleControl(particle, 0, start_position)
    ParticleManager:SetParticleControl(particle, 1, target_position)

    local particle = ParticleManager:CreateParticle("particles/custom/dazzle_shadow_wave_copy.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
    ParticleManager:SetParticleControl(particle, 0, start_position)
    ParticleManager:SetParticleControl(particle, 1, target_position)

    target:Heal(healing, target)
    local heal = math.floor(math.min(healing, caster:GetHealthDeficit())+0.5)
    if heal > 0 then
        PopupHealing(target,heal)
    end
end