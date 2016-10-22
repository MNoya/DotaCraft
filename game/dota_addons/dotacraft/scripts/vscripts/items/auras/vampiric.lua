item_scourge_bone_chimes = class({})

-- Reutilizes "heroes/dread_lord/vampiric_aura"
LinkLuaModifier("modifier_vampiric_aura", "heroes/dread_lord/vampiric_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vampiric_aura_buff", "heroes/dread_lord/vampiric_aura", LUA_MODIFIER_MOTION_NONE)

function item_scourge_bone_chimes:GetIntrinsicModifierName()
    return "modifier_vampiric_aura"
end

--------------------------------------------------------------------------------

neutral_vampiric_aura = class({})

function neutral_vampiric_aura:GetIntrinsicModifierName()
    return "modifier_vampiric_aura"
end

--------------------------------------------------------------------------------