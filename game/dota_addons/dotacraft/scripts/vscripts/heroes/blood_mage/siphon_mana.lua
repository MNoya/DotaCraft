-- Checks the target to see if it's an enemy or friend, the ability cant target friendly heroes
function SiphonManaStart( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local pID = caster:GetPlayerID()
    local particleName = "particles/units/heroes/hero_lion/lion_spell_mana_drain.vpcf"
    
    if target:GetTeamNumber() == caster:GetTeamNumber() then
        if target:IsRealHero() then
            caster:Interrupt()
            SendErrorMessage(pID, "#error_cant_target_allied_hero")
        else
            -- Particle from caster to ally
            caster.ManaDrainParticle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, caster)
            ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
        end
    else
        -- Particle from target to caster
        caster.ManaDrainParticle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, caster)
        ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    end
end

-- Kills illusions, if its not an illusion then it moves the caster direction, checks the leash distance and drains mana from the target
function SiphonMana( keys )
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability

    -- If its an illusion then kill it
    if target:IsIllusion() then
        target:ForceKill(true)
    else
        -- Location variables
        local caster_location = caster:GetAbsOrigin()
        local target_location = target:GetAbsOrigin()

        -- Distance variables
        local distance = (target_location - caster_location):Length2D()
        local break_distance = ability:GetLevelSpecialValueFor("break_distance", (ability:GetLevel() - 1))
        local direction = (target_location - caster_location):Normalized()

        -- If the leash is broken then stop the channel
        if distance >= break_distance then
            ability:OnChannelFinish(false)
            caster:Stop()
            return
        end

        -- Make sure that the caster always faces the target
        caster:SetForwardVector(direction)

        -- Mana calculation
        local mana_per_second = ability:GetLevelSpecialValueFor("mana_per_second", (ability:GetLevel() - 1))
        local tick_interval = ability:GetLevelSpecialValueFor("tick_interval", (ability:GetLevel() - 1))
        local mana_drain = mana_per_second / (1/tick_interval)

        local target_mana = target:GetMana()
        local caster_mana = caster:GetMana()
        local caster_max_mana = caster:GetMaxMana()

        -- Mana drain part
        -- If the target has enough mana then drain the maximum amount
        -- otherwise drain whatever is left
        -- Cast on Ally drains mana from hero to the target
        if caster:GetTeamNumber() == target:GetTeamNumber() then

            if caster_mana >= mana_drain then
                caster:ReduceMana(mana_drain)
                target:GiveMana(mana_drain)
            else
                caster:ReduceMana(caster_mana)
                target:GiveMana(caster_mana)
            end

        -- Cast on enemy drains mana from the target to the hero        
        else
            if target_mana >= mana_drain then
                target:ReduceMana(mana_drain)

                -- Mana gained can go over the max mana
                if caster_mana + mana_drain > caster_max_mana then
                    caster:GiveMana(mana_drain)
                    ability:ApplyDataDrivenModifier(caster, caster, "modifier_siphon_mana_extra", nil)
                else
                    caster:GiveMana(mana_drain)
                end
            else
                target:ReduceMana(target_mana)
                caster:GiveMana(target_mana)
            end
        end
    end
end

-- Stops the particle and sound from looping
function SiphonManaEnd( event )
    local target = event.target
    local caster = event.caster
    local sound = event.sound

    StopSoundEvent(sound, target)
    ParticleManager:DestroyParticle(caster.ManaDrainParticle,false) 
end