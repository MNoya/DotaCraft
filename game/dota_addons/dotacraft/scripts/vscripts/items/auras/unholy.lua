item_legion_doom_horn = class({})

-- Reutilizes "heroes/death_knight/unholy_aura"
LinkLuaModifier("modifier_unholy_aura", "heroes/death_knight/unholy_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_unholy_aura_buff", "heroes/death_knight/unholy_aura", LUA_MODIFIER_MOTION_NONE)

function item_legion_doom_horn:GetIntrinsicModifierName()
    return "modifier_unholy_aura"
end