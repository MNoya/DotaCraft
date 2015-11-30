modifier_druid_bear_model = class({})

function modifier_druid_bear_model:DeclareFunctions()
    return { MODIFIER_PROPERTY_MODEL_CHANGE }
end

function modifier_druid_bear_model:GetModifierModelChange()
    return "models/heroes/lone_druid/true_form.vmdl"
end

function modifier_druid_bear_model:IsHidden()
    return true
end


--------------------------------------------------

modifier_druid_crow_model = class({})

function modifier_druid_crow_model:DeclareFunctions()
    return { MODIFIER_PROPERTY_MODEL_CHANGE }
end

function modifier_druid_crow_model:GetModifierModelChange()
    return "models/items/courier/shagbark/shagbark_flying.vmdl"
end

function modifier_druid_crow_model:IsHidden()
    return true
end