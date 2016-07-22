modifier_flying_control = class({})

function modifier_flying_control:OnCreated()
    if IsServer() then
        local offset = self:GetParent():GetUnitName() == "undead_destroyer" and 120 or 200
        self.baseGround = GetGroundPosition(self:GetParent():GetAbsOrigin(), self:GetParent()).z + offset
        self:StartIntervalThink(0.03)
        self.treeHeight = 0
    end
end

function modifier_flying_control:OnIntervalThink()
    local unit = self:GetParent()
    if unit:HasFlyMovementCapability() then
        local origin = unit:GetAbsOrigin()

        -- Gain height in steps
        local z = math.min(self:GetStackCount()+20, math.max(0, self.baseGround - GetGroundPosition(origin, unit).z))
        if GridNav:IsNearbyTree(origin,64,true) then
            self.treeHeight = math.min(200, self.treeHeight+10)
        else
            self.treeHeight = math.max(0, self.treeHeight-10)
        end
        self:SetStackCount(z+self.treeHeight)
    else
        -- The unit lost its flying capability (due to an ensnare-type of spell)
        local z = math.max(0, self:GetStackCount()-10)
        self:SetStackCount(z)
    end
end

function modifier_flying_control:DeclareFunctions()
    return { MODIFIER_PROPERTY_VISUAL_Z_DELTA }
end

function modifier_flying_control:GetVisualZDelta()
    return self:GetStackCount()
end

function modifier_flying_control:IsHidden()
    return true
end

function modifier_flying_control:IsPurgable()
    return false
end