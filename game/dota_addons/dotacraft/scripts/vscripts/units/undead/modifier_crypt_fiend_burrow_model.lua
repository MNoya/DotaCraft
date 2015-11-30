modifier_crypt_fiend_burrow_model = class({})

function modifier_crypt_fiend_burrow_model:DeclareFunctions()
    return { MODIFIER_PROPERTY_MODEL_CHANGE }
end

function modifier_crypt_fiend_burrow_model:GetModifierModelChange()
    return "models/heroes/nerubian_assassin/mound.vmdl"
end

function modifier_crypt_fiend_burrow_model:IsHidden()
    return true
end