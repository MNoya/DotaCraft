item_khadgars_pipe_of_insight = class({})

-- Reutilizes "heroes/archmage/brilliance_aura"
LinkLuaModifier("modifier_brilliance_aura", "heroes/archmage/brilliance_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_brilliance_aura_buff", "heroes/archmage/brilliance_aura", LUA_MODIFIER_MOTION_NONE)

function item_khadgars_pipe_of_insight:GetIntrinsicModifierName()
    return "modifier_brilliance_aura"
end