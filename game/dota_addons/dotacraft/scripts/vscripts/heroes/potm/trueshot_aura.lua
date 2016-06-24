potm_trueshot_aura = class({})

LinkLuaModifier("modifier_trueshot_aura", "heroes/potm/trueshot_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_trueshot_aura_buff", "heroes/potm/trueshot_aura", LUA_MODIFIER_MOTION_NONE)

function potm_trueshot_aura:GetIntrinsicModifierName()
    return "modifier_trueshot_aura"
end

--------------------------------------------------------------------------------

modifier_trueshot_aura = class({})

function modifier_trueshot_aura:IsAura()
    return true
end

function modifier_trueshot_aura:IsHidden()
    return true
end

function modifier_trueshot_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_trueshot_aura:GetModifierAura()
    return "modifier_trueshot_aura_buff"
end

function modifier_trueshot_aura:GetEffectName()
    return "particles/custom/aura_trueshot.vpcf"
end

function modifier_trueshot_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
   
function modifier_trueshot_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_trueshot_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_RANGED_ONLY
end

function modifier_trueshot_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target)
end

function modifier_trueshot_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_trueshot_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_trueshot_aura_buff = class({})

function modifier_trueshot_aura_buff:DeclareFunctions()
    return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE }
end

function modifier_trueshot_aura_buff:GetModifierBaseDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_bonus_percent")
end