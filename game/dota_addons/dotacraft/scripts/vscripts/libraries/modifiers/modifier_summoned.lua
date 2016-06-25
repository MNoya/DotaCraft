modifier_summoned = class({})

function modifier_summoned:CheckState() 
    return { [MODIFIER_STATE_DOMINATED] = true, }
end

function modifier_summoned:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_summoned:IsHidden()
    return true
end