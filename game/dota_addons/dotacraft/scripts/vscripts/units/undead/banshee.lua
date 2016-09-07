function PossessionStart( event )
    local duration = event.ability:GetSpecialValueFor("duration")
    local ability = event.ability
    local target = event.target
    local caster = event.caster

    caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)
    ability:ApplyDataDrivenModifier(caster, target, "modifier_possession_target", {duration=duration+1})
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_possession_caster", {duration=duration})
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_death_prophet/death_prophet_spiritsiphon.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(particle, 5, Vector(duration, 0, 0))
    caster:EmitSound("Hero_DeathProphet.Exorcism.Cast")
    for i=1,3 do
        Timers:CreateTimer(i*1.2, function()
            if IsValidAlive(caster) and ability:IsChanneling() then
                caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)
            else
                ParticleManager:DestroyParticle(particle,true)
                return
            end
        end)
    end
end

function PossessionEnd( keys )
    local target = keys.target
    local caster = keys.caster
    local ability = keys.ability
    
    Timers:CreateTimer(function()
    
        -- incase the unit has finished channelling but dies mid-possession(highly unlikely but possible)
        if not IsValidAlive(target) then return end
        if not IsValidAlive(caster) then return end
        
        local casterposition = caster:GetAbsOrigin()
        local targetposition = target:GetAbsOrigin()
        
        caster:EmitSound("Hero_DeathProphet.Exorcism.Damage")

        if (casterposition-targetposition):Length2D() < 10 then

            -- particle management
            ParticleManager:CreateParticle("particles/units/heroes/hero_death_prophet/death_prophet_excorcism_attack_impact_death.vpcf", 1, target)

            local reselect = PlayerResource:IsUnitSelected(newOwnerID, caster)
            target:TransferOwnership(caster:GetPlayerOwnerID())
            caster:EmitSound("Hero_DeathProphet.Death")
            caster:ForceKill(true)
            caster:AddNoDraw()

            if reselect then
                PlayerResource:AddToSelection(newOwnerID, target)
            end

            return
        else
            
            -- update position, Caster moves towards Target
            caster:SetAbsOrigin(caster:GetAbsOrigin() + (target:GetAbsOrigin() - caster:GetAbsOrigin()))    
        end
        return 0.2
    end)    
end

function CurseAutocast(keys)
    local ability = keys.ability
    local caster = keys.caster
    local autocast_radius = ability:GetCastRange()
    local modifier_name = "modifier_undead_curse"
    
    if caster.state == AI_STATE_IDLE or caster.state == AI_STATE_SLEEPING then return end
    
    if ability:GetAutoCastState() and ability:IsFullyCastable() and not caster:IsMoving() and not IsChanneling(caster) then
        local target
        local enemies = FindEnemiesInRadius(caster, autocast_radius)
        for k,unit in pairs(enemies) do
            if not IsCustomBuilding(unit) and not unit:IsMechanical() and not unit:IsWard() and not unit:HasModifier(modifier_name) then
                target = unit
                break
            end
        end

        if target then
            caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())
        end
    end
end

-- Puts a variable at 0 for the damage filter to take it
function ResetAntiMagicShell( event )
    local target = event.target
    target.anti_magic_shell_absorbed = 0
end
