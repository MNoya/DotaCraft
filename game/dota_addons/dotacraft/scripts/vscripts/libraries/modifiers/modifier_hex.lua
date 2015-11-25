modifier_hex = class({})

function modifier_hex:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MODEL_CHANGE
    }

    return funcs
end

function modifier_hex:GetModifierModelChange()
    return "models/items/hex/sheep_hex/sheep_hex.vmdl"
end

function modifier_hex:CheckState() 
  local state = {
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_MUTED] = true,
    [MODIFIER_STATE_HEXED] = true,
    [MODIFIER_STATE_EVADE_DISABLED] = true,
    [MODIFIER_STATE_SILENCED] = true,
  }

  return state
end