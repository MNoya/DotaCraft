modifier_disable_turning = class({})

function modifier_disable_turning:DeclareFunctions() 
  return {
        MODIFIER_PROPERTY_DISABLE_TURNING,
        MODIFIER_PROPERTY_IGNORE_CAST_ANGLE
    }
end

function modifier_disable_turning:GetModifierDisableTurning( params )
    return 1
end

function modifier_disable_turning:GetModifierIgnoreCastAngle( params )
    return 1
end

function modifier_disable_turning:IsHidden()
    return true
end