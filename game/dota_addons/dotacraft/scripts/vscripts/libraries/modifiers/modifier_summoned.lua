modifier_summoned = class({})

function modifier_summoned:CheckState() 
    return { [MODIFIER_STATE_DOMINATED] = true, }
end

function modifier_summoned:IsHidden() return true end
function modifier_summoned:IsPurgable() return false end
function modifier_summoned:RemoveOnDeath() return false end