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

            -- Remove the unit from the enemy player unit list
            local oldOwnerID = target:GetPlayerOwnerID()
            if oldOwnerID then
                Players:RemoveUnit(oldOwnerID, target)
            end

            -- convert target unit information to match caster
            local newOwner = caster:GetOwner()
            local newOwnerID = caster:GetPlayerOwnerID()
            local newTeam = PlayerResource:GetTeam(newOwnerID)
            target:SetOwner(newOwner)
            target:SetControllableByPlayer(newOwnerID, true)
            target:SetTeam(newTeam)
            target:EmitSound("Hero_DeathProphet.Death")
            target:RemoveModifierByName("modifier_possession_target")
            Players:AddUnit(newOwnerID, target)

            -- kill and set selection
            PlayerResource:AddToSelection(newOwnerID, target)
            caster:ForceKill(true)
            caster:AddNoDraw()

            --kill timer
            return nil
        else
            
            -- update position, Caster moves towards Target
            caster:SetAbsOrigin(caster:GetAbsOrigin() + (target:GetAbsOrigin() - caster:GetAbsOrigin()))    
        end
        return 0.2
    end)    
end

function undead_curse ( keys )
    -- Caster & Target
    local target = keys.target
    local caster = keys.caster
    
    -- durations have be inverted due to some weird parsing bug
    local UNIT_DURATION = keys.ability:GetSpecialValueFor("unit_duration")
    local HERO_DURATION = keys.ability:GetSpecialValueFor("hero_duration")
    
    caster:Stop()
    caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
    
    if target:IsHero() or target:IsConsideredHero() then
    --  print(HERO_DURATION)
        keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_undead_curse", {duration=HERO_DURATION})
    else
    --  print(UNIT_DURATION)
        keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_undead_curse", {duration=UNIT_DURATION})
    end
end

function BansheeCurseAutoCast (keys)
    local caster = keys.caster
    local ability = keys.ability
    
    Timers:CreateTimer(function()   
        if not IsValidEntity(caster) or not caster:IsAlive() then return end
            
        if ability:GetAutoCastState() and caster:IsIdle() and not IsChanneling(caster) then
            BansheeCurseAuto_Cast(keys)
        end
        
        return 1
    end)
end

function BansheeCurseAuto_Cast(keys)
    local ability = keys.ability
    local caster = keys.caster
    local AUTOCAST_RANGE = ability:GetSpecialValueFor("cast_range")
    local MODIFIER_NAME = "modifier_undead_curse"
    
    local COOLDOWN = ability:GetCooldown(1)
    local MANA_COST = ability:GetManaCost(-1)
    
    local target = nil
    
    -- find all units within 300 range that are enemey
    local units = FindUnitsInRadius(caster:GetTeamNumber(), 
                                caster:GetAbsOrigin(), 
                                nil, 
                                AUTOCAST_RANGE, 
                                DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                DOTA_UNIT_TARGET_ALL, 
                                DOTA_UNIT_TARGET_FLAG_NONE, 
                                FIND_CLOSEST, 
                                false)
            
    for k,unit in pairs(units) do
        if not unit:HasModifier(MODIFIER_NAME) and not IsCustomBuilding(unit) and not unit:IsMechanical() then
            target = unit
            break
        end
    end
    
    if target ~= nil then
        caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())  
    end
end

-- Automatically toggled on
function ToggleOnAutocast( event )
    local caster = event.caster
    local ability = event.ability

    ability:ToggleAutoCast()
end

-- Puts a variable at 0 for the damage filter to take it
function ResetAntiMagicShell( event )
    local target = event.target
    target.anti_magic_shell_absorbed = 0
end
