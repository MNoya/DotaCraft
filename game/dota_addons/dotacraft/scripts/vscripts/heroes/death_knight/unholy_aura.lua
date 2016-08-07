death_knight_unholy_aura = class({})

LinkLuaModifier("modifier_unholy_aura", "heroes/death_knight/unholy_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_unholy_aura_buff", "heroes/death_knight/unholy_aura", LUA_MODIFIER_MOTION_NONE)

function death_knight_unholy_aura:GetIntrinsicModifierName()
    return "modifier_unholy_aura"
end

--------------------------------------------------------------------------------

modifier_unholy_aura = class({})

function modifier_unholy_aura:IsAura()
    return true
end

function modifier_unholy_aura:IsHidden()
    return true
end

function modifier_unholy_aura:IsPurgable()
    return false
end

function modifier_unholy_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_unholy_aura:GetModifierAura()
    return "modifier_unholy_aura_buff"
end

function modifier_unholy_aura:GetEffectName()
    return "particles/custom/doom_bringer_doom.vpcf"
end

function modifier_unholy_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
   
function modifier_unholy_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_unholy_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target) or target:IsWard()
end

function modifier_unholy_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_unholy_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_unholy_aura_buff = class({})

function modifier_unholy_aura_buff:DeclareFunctions()
    return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_unholy_aura_buff:GetModifierConstantHealthRegen()
    return self:GetAbility():GetSpecialValueFor("health_regen_bonus")
end

function modifier_unholy_aura_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed_bonus")
end

function modifier_unholy_aura_buff:IsPurgable()
    return false
end