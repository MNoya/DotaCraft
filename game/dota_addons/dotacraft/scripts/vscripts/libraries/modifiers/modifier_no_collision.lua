modifier_no_collision = class({})

function modifier_no_collision:CheckState() 
    return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true, }
end

function modifier_no_collision:IsHidden()
    return true
end

function modifier_no_collision:IsPurgable()
    return false
end