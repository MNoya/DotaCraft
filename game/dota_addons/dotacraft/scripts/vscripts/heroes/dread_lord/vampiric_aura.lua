dread_lord_vampiric_aura = class({})

LinkLuaModifier("modifier_vampiric_aura", "heroes/dread_lord/vampiric_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vampiric_aura_buff", "heroes/dread_lord/vampiric_aura", LUA_MODIFIER_MOTION_NONE)

function dread_lord_vampiric_aura:GetIntrinsicModifierName()
    return "modifier_vampiric_aura"
end

--------------------------------------------------------------------------------

modifier_vampiric_aura = class({})

function modifier_vampiric_aura:IsAura()
    return true
end

function modifier_vampiric_aura:IsHidden()
    return true
end

function modifier_vampiric_aura:IsPurgable()
    return false
end

function modifier_vampiric_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_vampiric_aura:GetModifierAura()
    return "modifier_vampiric_aura_buff"
end

function modifier_vampiric_aura:GetEffectName()
    return "particles/custom/aura_vampiric.vpcf"
end

function modifier_vampiric_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
   
function modifier_vampiric_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_vampiric_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MELEE_ONLY
end

function modifier_vampiric_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target) or target:IsWard()
end

function modifier_vampiric_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_vampiric_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_vampiric_aura_buff = class({})

function modifier_vampiric_aura_buff:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_vampiric_aura_buff:OnAttackLanded(event)
    local attacker = event.attacker
    if attacker == self:GetParent() then
        local target = event.target
        if not IsCustomBuilding(target) and not target:IsMechanical() and not target:IsWard() then
            local lifesteal = self:GetAbility():GetSpecialValueFor("lifesteal") * event.damage * 0.01
            attacker:Heal(lifesteal,self)
            local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
            ParticleManager:SetParticleControlEnt(particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
        end
    end
end

function modifier_vampiric_aura:IsPurgable()
    return false
end