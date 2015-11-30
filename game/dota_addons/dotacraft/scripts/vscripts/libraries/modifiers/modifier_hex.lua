modifier_hex_frog = class({})

function modifier_hex_frog:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
    }

    return funcs
end

function modifier_hex_frog:CheckState() 
  local state = {
      [MODIFIER_STATE_DISARMED] = true,
      [MODIFIER_STATE_MUTED] = true,
      [MODIFIER_STATE_HEXED] = true,
      [MODIFIER_STATE_EVADE_DISABLED] = true,
      [MODIFIER_STATE_SILENCED] = true,
  }

  return state
end

function modifier_hex_frog:GetModifierModelChange()
    return "models/props_gameplay/frog.vmdl"
end

function modifier_hex_frog:GetModifierMoveSpeedOverride()
    return 100
end

--------------------------------------------------

modifier_hex_sheep = class({})

function modifier_hex_sheep:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MODEL_CHANGE,
        MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
    }

    return funcs
end

function modifier_hex_sheep:CheckState() 
  local state = {
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_MUTED] = true,
    [MODIFIER_STATE_HEXED] = true,
    [MODIFIER_STATE_EVADE_DISABLED] = true,
    [MODIFIER_STATE_SILENCED] = true,
  }

  return state
end

function modifier_hex_sheep:GetModifierModelChange()
    return "models/items/hex/sheep_hex/sheep_hex.vmdl"
end

function modifier_hex_sheep:GetModifierMoveSpeedOverride()
    return 100
end