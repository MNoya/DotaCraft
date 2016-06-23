item_cloak_of_flames = class({})

-- Reutilizes "heroes/demon_hunter/immolation_aura"
LinkLuaModifier("modifier_immolation_aura", "heroes/demon_hunter/immolation_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_immolation_aura_debuff", "heroes/demon_hunter/immolation_aura", LUA_MODIFIER_MOTION_NONE)

function item_cloak_of_flames:GetIntrinsicModifierName()
    if self:GetCaster():HasModifier("modifier_immolation_aura") then
        return ""
    else
        return "modifier_immolation_aura"
    end
end