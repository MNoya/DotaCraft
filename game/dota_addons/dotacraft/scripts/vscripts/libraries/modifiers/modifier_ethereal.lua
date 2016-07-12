modifier_ethereal = class({})

function modifier_ethereal:DeclareFunctions()
    return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE, }
end

function modifier_ethereal:CheckState() 
    return { [MODIFIER_STATE_DISARMED] = true, }
end

function modifier_ethereal:GetModifierMagicalResistanceDecrepifyUnique( params )
    return -66
end

function modifier_ethereal:IsPurgable()
    return false --Parent modifier takes care of it
end

function modifier_ethereal:IsHidden()
    return true
end

function modifier_ethereal:GetEffectName()
    return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_ethereal:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end