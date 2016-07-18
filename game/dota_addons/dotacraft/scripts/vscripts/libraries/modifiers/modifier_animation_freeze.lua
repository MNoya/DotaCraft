modifier_animation_freeze = class({})

function modifier_animation_freeze:CheckState() 
    return { [MODIFIER_STATE_FROZEN] = true, }
end

function modifier_animation_freeze:IsHidden()
    return true
end

function modifier_animation_freeze:IsPurgable()
    return false
end