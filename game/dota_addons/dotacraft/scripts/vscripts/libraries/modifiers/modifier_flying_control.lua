modifier_flying_control = class({})

function modifier_flying_control:OnCreated()
    if IsServer() then
        self.baseGround = GetGroundPosition(self:GetParent():GetAbsOrigin(), self:GetParent()).z + 200
        self:StartIntervalThink(0.03)
        self.tree_modifier_stacks = 0
    end
end

function modifier_flying_control:OnIntervalThink()
    local unit = self:GetParent()
    if unit:HasFlyMovementCapability() then
        local origin = unit:GetAbsOrigin()
        local z = math.max(0, self.baseGround - GetGroundPosition(origin, unit).z)
        if GridNav:IsNearbyTree(origin,64,true) then
            self.tree_modifier_stacks = math.min(200, self.tree_modifier_stacks+10)
        else
            self.tree_modifier_stacks = math.max(0, self.tree_modifier_stacks-10)
        end
        self:SetStackCount(z+self.tree_modifier_stacks)
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