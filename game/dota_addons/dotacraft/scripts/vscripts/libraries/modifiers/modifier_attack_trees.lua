modifier_attack_trees = class({})

function modifier_attack_trees:DeclareFunctions()
    return { MODIFIER_PROPERTY_CAN_ATTACK_TREES, }
end

function modifier_attack_trees:GetModifierCanAttackTrees()
    print("GetModifierCanAttackTrees")
    return true
end

function modifier_attack_trees:IsHidden()
    return false
end

function modifier_attack_trees:OnCreated()
    print("MODIFIER_PROPERTY_CAN_ATTACK_TREES is real?")
end