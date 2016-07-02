modifier_flying_control = class({})

function modifier_flying_control:OnCreated()
    if IsServer() then
        self.baseGround = GetGroundPosition(self:GetParent():GetAbsOrigin(), self:GetParent()).z + 128
        self:StartIntervalThink(0.03)
    end
end

function modifier_flying_control:OnIntervalThink()
    local unit = self:GetParent()
    if unit:HasFlyMovementCapability() then
        local z = math.max(0, self.baseGround - GetGroundPosition(unit:GetAbsOrigin(), unit).z)
        self:SetStackCount(z)
    else
        self:SetStackCount(0)
    end
end

function modifier_flying_control:DeclareFunctions()
    return { MODIFIER_PROPERTY_VISUAL_Z_DELTA }
end

function modifier_flying_control:GetVisualZDelta()
    return 1 * self:GetStackCount()
end

function modifier_flying_control:IsHidden()
    return true
end