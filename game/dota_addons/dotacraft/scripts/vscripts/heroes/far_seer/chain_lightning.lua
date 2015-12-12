--[[
    Author: Noya
    Date: 12 December 2015
    Bounces a chain lightning
]]
function ChainLightning( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local teamNumber = caster:GetTeamNumber()
    local targetTeam = ability:GetAbilityTargetTeam()
    local targetTypes = ability:GetAbilityTargetType()
    local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
    local findType = FIND_CLOSEST

    local damage = ability:GetLevelSpecialValueFor( "lightning_damage", ability:GetLevel() - 1 )
    local bounces = ability:GetLevelSpecialValueFor( "lightning_bounces", ability:GetLevel() - 1 )
    local bounce_range = ability:GetLevelSpecialValueFor( "bounce_range", ability:GetLevel() - 1 )
    local decay = ability:GetLevelSpecialValueFor( "lightning_decay", ability:GetLevel() - 1 ) * 0.01
    local time_between_bounces = ability:GetLevelSpecialValueFor( "time_between_bounces", ability:GetLevel() - 1 )

    local start_position = caster:GetAbsOrigin()
    local attach_eye_r = caster:ScriptLookupAttachment("attach_eye_r") --Disruptor
    local attach_attack1 = caster:ScriptLookupAttachment("attach_attack1") --Most units have this
    if attach_eye_r ~= 0 then
        local first_eye = caster:GetAttachmentOrigin(attach_eye_r)
        local second_eye = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_eye_l"))
        start_position = first_eye + (second_eye-first_eye)/2 --Between the eyes
        start_position.z = start_position.z + 50
    
    elseif attach_attack1 ~= 0 then
        start_position = caster:GetAttachmentOrigin(attach_attack1)
    else
        start_position.z = start_position.z + target:GetBoundingMaxs().z
    end

    local current_position = CreateChainLightning(caster, start_position, target, damage)

    -- Every target struck by the chain is added to an entity index list
    local targetsStruck = {}
    targetsStruck[target:GetEntityIndex()] = true

    Timers:CreateTimer(time_between_bounces, function()  
        local units = FindUnitsInRadius(teamNumber, current_position, target, bounce_range, targetTeam, targetTypes, flags, findType, true)

        if #units > 0 then

            -- Hit the first unit that hasn't been struck yet
            local bounce_target
            for _,unit in pairs(units) do
                local entIndex = unit:GetEntityIndex()
                if not targetsStruck[entIndex] then
                    bounce_target = unit
                    targetsStruck[entIndex] = true
                    break
                end
            end

            if bounce_target then
                damage = damage - (damage*decay)
                current_position = CreateChainLightning(caster, current_position, bounce_target, damage)

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

-- Creates a chain lightning on a start position towards a target. Also does sound, damage and popup
function CreateChainLightning( caster, start_position, target, damage )
    local target_position = target:GetAbsOrigin()
    local attach_hitloc = target:ScriptLookupAttachment("attach_hitloc")
    if attach_hitloc ~= 0 then
        target_position = target:GetAttachmentOrigin(attach_hitloc)
    else
        target_position.z = target_position.z + target:GetBoundingMaxs().z
    end

    local particle = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle,0, start_position)
    ParticleManager:SetParticleControl(particle,1, target_position)

    EmitSoundOn("Hero_Zuus.ArcLightning.Target", target)    
    ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL })
    PopupDamage(target, math.floor(damage))

    return target_position
end