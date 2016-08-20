modifier_unsummoning = class({})

function modifier_unsummoning:GetStatusEffectName()
    return "particles/status_fx/status_effect_wraithking_ghosts.vpcf"
end

function modifier_unsummoning:StatusEffectPriority()
    return 100
end

function modifier_unsummoning:GetEffectName()
    return "particles/custom/undead/unsummon.vpcf"
end

function modifier_unsummoning:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_unsummoning:IsHidden() return true end
function modifier_unsummoning:IsPurgable() return false end
function modifier_unsummoning:RemoveOnDeath() return false end