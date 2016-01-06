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
        }

        return state
    end

    function modifier_builder_hidden:OnCreated( params )    
        local unit = self:GetParent()
        unit.originalDayVision = unit:GetDayTimeVisionRange()
        unit.originalNightVision = unit:GetDayTimeVisionRange()
        unit:SetDayTimeVisionRange(0)
        unit:SetNightTimeVisionRange(0)
    end

    function modifier_builder_hidden:OnDestroy( params )
        local unit = self:GetParent()
        unit:SetDayTimeVisionRange(unit.originalDayVision)
        unit:SetNightTimeVisionRange(unit.originalNightVision)
    end
end

function modifier_builder_hidden:IsHidden()
    return true
end