modifier_builder_hidden = class({})

-- Builder can send build orders while inside the building
-- Builder is selectable while inside the building
if IsServer() then
    function modifier_builder_hidden:CheckState() 
        local state = {
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_INVULNERABLE] = true,
            [MODIFIER_STATE_ROOTED] = true,
            [MODIFIER_STATE_DISARMED] = true,
            [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
            [MODIFIER_STATE_NO_HEALTH_BAR] = true,
            [MODIFIER_STATE_BLIND] = true,
        }

        return state
    end
end

function modifier_builder_hidden:IsHidden()
    return true
end

function modifier_builder_hidden:IsPurgable()
    return false
end