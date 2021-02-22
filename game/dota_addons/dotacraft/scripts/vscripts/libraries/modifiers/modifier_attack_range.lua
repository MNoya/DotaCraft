modifier_attack_range = class({})

function modifier_attack_range:OnCreated(params)
    if IsServer() then
        local range = params.range
        local current_range = self:GetParent():Script_GetAttackRange()
        self.range = params.range - current_range
        self:SetStackCount(self.range)
    end
end

function modifier_attack_range:DeclareFunctions()
    return {MODIFIER_PROPERTY_ATTACK_RANGE_BONUS}
end

function modifier_attack_range:GetModifierAttackRangeBonus()
    return self:GetStackCount()
end

function modifier_attack_range:IsHidden() return true end
function modifier_attack_range:IsPurgable() return false end