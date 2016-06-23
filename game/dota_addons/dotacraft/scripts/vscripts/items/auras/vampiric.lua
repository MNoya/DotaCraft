item_scourge_bone_chimes = class({})

-- Reutilizes "heroes/dread_lord/vampiric_aura"
LinkLuaModifier("modifier_vampiric_aura", "heroes/dread_lord/vampiric_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vampiric_aura_buff", "heroes/dread_lord/vampiric_aura", LUA_MODIFIER_MOTION_NONE)

function item_scourge_bone_chimes:GetIntrinsicModifierName()
    if self:GetCaster():HasModifier("modifier_vampiric_aura") then
        return ""
    else
        return "modifier_vampiric_aura"
    end
end