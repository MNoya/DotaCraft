item_warsong_battle_drums = class({})

-- Implements command aura
LinkLuaModifier("modifier_command_aura", "items/auras/command", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_command_aura_buff", "items/auras/command", LUA_MODIFIER_MOTION_NONE)

function item_warsong_battle_drums:GetIntrinsicModifierName()
    if self:GetCaster():HasModifier("modifier_command_aura") then
        return ""
    else
        return "modifier_command_aura"
    end
end

--------------------------------------------------------------------------------

modifier_command_aura = class({})

function modifier_command_aura:IsAura()
    return true
end

function modifier_command_aura:IsHidden()
    return true
end

function modifier_command_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_command_aura:GetModifierAura()
    return "modifier_command_aura_buff"
end

function modifier_command_aura:GetEffectName()
    return "particles/items_fx/aura_assault_ring.vpcf"
end

function modifier_command_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
   
function modifier_command_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_command_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target)
end

function modifier_command_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_command_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_command_aura_buff = class({})

function modifier_command_aura_buff:DeclareFunctions()
    return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE }
end

function modifier_command_aura_buff:GetModifierBaseDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_bonus_pct")
end