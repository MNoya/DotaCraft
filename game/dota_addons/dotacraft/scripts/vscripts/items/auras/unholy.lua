item_legion_doom_horn = class({})

-- Reutilizes "heroes/death_knight/unholy_aura"
LinkLuaModifier("modifier_unholy_aura", "heroes/death_knight/unholy_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_unholy_aura_buff", "heroes/death_knight/unholy_aura", LUA_MODIFIER_MOTION_NONE)

function item_legion_doom_horn:GetIntrinsicModifierName()
    if self:GetCaster():HasModifier("modifier_unholy_aura") then
        return ""
    else
        return "modifier_unholy_aura"
    end
end