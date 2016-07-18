modifier_movespeed_cap = class({})
local attributes = LoadKeyValues("scripts/kv/attributes.kv")
function modifier_movespeed_cap:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_MAX,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }

    return funcs
end

function modifier_movespeed_cap:GetModifierMoveSpeed_Max( params )
    return attributes.MAX_MS or 522
end

function modifier_movespeed_cap:GetModifierMoveSpeed_Limit( params )
    return attributes.MAX_MS or 522
end

function modifier_movespeed_cap:IsHidden()
    return true
end

function modifier_movespeed_cap:IsPurgable()
    return false
end