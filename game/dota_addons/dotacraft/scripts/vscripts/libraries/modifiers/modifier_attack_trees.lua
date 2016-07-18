modifier_attack_trees = class({})

function modifier_attack_trees:DeclareFunctions()
    return { MODIFIER_PROPERTY_CAN_ATTACK_TREES }
end

function modifier_attack_trees:GetModifierCanAttackTrees()
    return 1
end

function modifier_attack_trees:IsHidden()
    return true
end

function modifier_attack_trees:IsPurgable()
    return false
end