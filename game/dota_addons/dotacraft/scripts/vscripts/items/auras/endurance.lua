item_ancient_janngo_of_endurance = class({})

-- Reutilizes "heroes/tauren_chieftain/endurance_aura"
LinkLuaModifier("modifier_endurance_aura", "heroes/tauren_chieftain/endurance_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_endurance_aura_buff", "heroes/tauren_chieftain/endurance_aura", LUA_MODIFIER_MOTION_NONE)

function item_ancient_janngo_of_endurance:GetIntrinsicModifierName()
    if self:GetCaster():HasModifier("modifier_endurance_aura") then
        return ""
    else
        return "modifier_endurance_aura"
    end
end