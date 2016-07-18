archmage_brilliance_aura = class({})

LinkLuaModifier("modifier_brilliance_aura", "heroes/archmage/brilliance_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_brilliance_aura_buff", "heroes/archmage/brilliance_aura", LUA_MODIFIER_MOTION_NONE)

function archmage_brilliance_aura:GetIntrinsicModifierName()
    return "modifier_brilliance_aura"
end

--------------------------------------------------------------------------------

modifier_brilliance_aura = class({})

function modifier_brilliance_aura:IsAura()
    return true
end

function modifier_brilliance_aura:IsHidden()
    return true
end

function modifier_brilliance_aura:IsPurgable()
    return false
end

function modifier_brilliance_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_brilliance_aura:GetModifierAura()
    return "modifier_brilliance_aura_buff"
end

function modifier_brilliance_aura:GetEffectName()
    return "particles/items_fx/aura_shivas.vpcf"
end

function modifier_brilliance_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
   
function modifier_brilliance_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_brilliance_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target) or target:GetMaxMana() == 0
end

function modifier_brilliance_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_brilliance_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_brilliance_aura_buff = class({})

function modifier_brilliance_aura_buff:DeclareFunctions()
    return { MODIFIER_PROPERTY_MANA_REGEN_CONSTANT }
end

function modifier_brilliance_aura_buff:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("mana_regen")
end

function modifier_brilliance_aura_buff:IsPurgable()
    return false
end