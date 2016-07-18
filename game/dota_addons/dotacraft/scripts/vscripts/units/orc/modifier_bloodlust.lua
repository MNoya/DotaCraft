modifier_bloodlust = class({})

function modifier_bloodlust:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, 
             MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, 
             MODIFIER_PROPERTY_MODEL_SCALE, }
end

function modifier_bloodlust:GetModifierModelScale()
    return 30
end

function modifier_bloodlust:GetModifierAttackSpeedBonus_Constant()
    return 40
end


function modifier_bloodlust:GetModifierMoveSpeedBonus_Percentage()
    return 25
end

function modifier_bloodlust:GetDuration()
    return 60
end

function modifier_bloodlust:IsPurgable()
    return true
end

function modifier_bloodlust:GetEffectName()
    return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end

function modifier_bloodlust:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_bloodlust:GetTextureName()
    return "orc_bloodlust"
end