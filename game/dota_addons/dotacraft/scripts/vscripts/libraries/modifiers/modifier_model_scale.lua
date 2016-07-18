modifier_model_scale = class({})

function modifier_model_scale:OnCreated(params)
    local scale = params.scale or 100
    self.scale = scale
end

function modifier_model_scale:DeclareFunctions()
    return { MODIFIER_PROPERTY_MODEL_SCALE, }
end

function modifier_model_scale:GetModifierModelScale()
    return self.scale
end

function modifier_model_scale:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_model_scale:IsHidden()
    return true
end

function modifier_model_scale:IsPurgable()
    return false
end