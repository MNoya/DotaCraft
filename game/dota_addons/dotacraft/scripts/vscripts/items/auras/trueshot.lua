item_allerias_flute_of_accuracy = class({})

-- Reutilizes "heroes/potm/trueshot_aura"
LinkLuaModifier("modifier_trueshot_aura", "heroes/potm/trueshot_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_trueshot_aura_buff", "heroes/potm/trueshot_aura", LUA_MODIFIER_MOTION_NONE)

function item_allerias_flute_of_accuracy:GetIntrinsicModifierName()
    if self:GetCaster():HasModifier("modifier_trueshot_aura") then
        return ""
    else
        return "modifier_trueshot_aura"
    end
end