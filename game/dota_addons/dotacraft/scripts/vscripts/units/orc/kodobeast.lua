function DevourPhase( event )
    local caster = event.caster
    local target = event.target
    if caster:HasModifier('modifier_devour_devouring') then
        SendErrorMessage(caster:GetPlayerOwnerID(), "error_mouth_full")
        caster:Interrupt()
    elseif target:GetUnitName() == "orc_kodo_beast" then
        SendErrorMessage(caster:GetPlayerOwnerID(), "error_unable_to_devour")
        caster:Interrupt()
    end
end

function DevourStart( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability

    ability.target = target -- The devoured unit
    local duration = math.ceil(target:GetHealth() / ability:GetSpecialValueFor('damage_per_second'))

    caster:EmitSound("Hero_DoomBringer.DevourCast")
    caster:StartGesture(ACT_DOTA_SPAWN)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_devour.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc")))
    ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

    ability:ApplyDataDrivenModifier(caster, target, 'modifier_devour_debuff', {})
    ability:ApplyDataDrivenModifier(caster, caster, 'modifier_devour_devouring', {duration = duration})
    target:AddNoDraw()
    Timers:CreateTimer(0.1, function()
        target:SetParent(caster,"attach_hitloc")
    end)
end

function DevourThink( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local damage = ability:GetSpecialValueFor('damage_per_second')

    if target:GetHealth() > damage then
        target:SetHealth(target:GetHealth()-damage)
    else
        target:SetModelScale(0)
        target:SetParent(nil,"")
        target:SetAbsOrigin(caster:GetAbsOrigin())
        target:RemoveModifierByName('modifier_devour_debuff')
        target:RemoveNoDraw()
        target:Kill(ability,caster)
    end
end

-- Kodo dies, eject target
function DevourDeath( event )
    local caster = event.caster
    local ability = event.ability
    local target = ability.target

    if IsValidEntity(target) then
        target:SetParent(nil,"")
        target:SetForwardVector(Vector(1,0,0))
        target:SetAbsOrigin(caster:GetAbsOrigin())
        target:RemoveModifierByName('modifier_devour_debuff')
        target:RemoveNoDraw()
        ability.target = nil
    end
end

---------------------------------------------------------------------

orc_war_drums = class({})

-- Stacks with command aura
LinkLuaModifier("modifier_war_drums_aura", "units/orc/kodobeast", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_war_drums", "units/orc/kodobeast", LUA_MODIFIER_MOTION_NONE)

function orc_war_drums:GetIntrinsicModifierName()
    return "modifier_war_drums_aura"
end

--------------------------------------------------------------------------------

modifier_war_drums_aura = class({})

function modifier_war_drums_aura:IsAura()
    return true
end

function modifier_war_drums_aura:IsHidden()
    return true
end

function modifier_war_drums_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_war_drums_aura:GetModifierAura()
    return "modifier_war_drums"
end

function modifier_war_drums_aura:GetEffectName()
    return "particles/custom/aura_command.vpcf"
end

function modifier_war_drums_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
   
function modifier_war_drums_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_war_drums_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target) or target:IsWard()
end

function modifier_war_drums_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_war_drums_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_war_drums = class({})

function modifier_war_drums:DeclareFunctions()
    return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE }
end

function modifier_war_drums:GetModifierBaseDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_increase")
end