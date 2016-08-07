tauren_chieftain_endurance_aura = class({})

LinkLuaModifier("modifier_endurance_aura", "heroes/tauren_chieftain/endurance_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_endurance_aura_buff", "heroes/tauren_chieftain/endurance_aura", LUA_MODIFIER_MOTION_NONE)

function tauren_chieftain_endurance_aura:GetIntrinsicModifierName()
    return "modifier_endurance_aura"
end

--------------------------------------------------------------------------------

modifier_endurance_aura = class({})

function modifier_endurance_aura:IsAura()
    return true
end

function modifier_endurance_aura:IsHidden()
    return true
end

function modifier_endurance_aura:IsPurgable()
    return false
end

function modifier_endurance_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_endurance_aura:GetModifierAura()
    return "modifier_endurance_aura_buff"
end

function modifier_endurance_aura:GetEffectName()
    return "particles/custom/aura_endurance.vpcf"
end

function modifier_endurance_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
   
function modifier_endurance_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_endurance_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target) or target:IsWard()
end

function modifier_endurance_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_endurance_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_endurance_aura_buff = class({})

function modifier_endurance_aura_buff:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_endurance_aura_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed_bonus")
end

function modifier_endurance_aura_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed_bonus")
end

function modifier_endurance_aura_buff:IsPurgable()
    return false
end