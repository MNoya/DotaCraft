modifier_out_of_world = class({})

function modifier_out_of_world:CheckState() 
    local state = {
        [MODIFIER_STATE_OUT_OF_GAME] = true,
        [MODIFIER_STATE_PASSIVES_DISABLED] = true,
        [MODIFIER_STATE_PROVIDES_VISION] = false,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
    }

    return state
end

function modifier_out_of_world:OnCreated( params )
    if not IsServer() then return end
    local unit = self:GetParent()
    unit.originalDayVision = unit:GetDayTimeVisionRange()
    unit.originalNightVision = unit:GetDayTimeVisionRange()
    unit:SetDayTimeVisionRange(0)
    unit:SetNightTimeVisionRange(0)
end

function modifier_out_of_world:OnDestroy( params )
    if not IsServer() then return end
    local unit = self:GetParent()
    unit:SetDayTimeVisionRange(unit.originalDayVision)
    unit:SetNightTimeVisionRange(unit.originalNightVision)
end