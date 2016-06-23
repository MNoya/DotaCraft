item_the_lion_horn_of_stormwind = class({})

-- Reutilizes "heroes/paladin/devotion_aura"
LinkLuaModifier("modifier_devotion_aura", "heroes/paladin/devotion_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_devotion_aura_buff", "heroes/paladin/devotion_aura", LUA_MODIFIER_MOTION_NONE)

function item_the_lion_horn_of_stormwind:GetIntrinsicModifierName()
    if self:GetCaster():HasModifier("modifier_devotion_aura") then
        return ""
    else
        return "modifier_devotion_aura"
    end
end