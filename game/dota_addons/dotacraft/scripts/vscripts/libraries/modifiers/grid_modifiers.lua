modifier_grid_blight = class({})

function modifier_grid_blight:IsHidden() return true end
function modifier_grid_blight:IsPurgable() return false end

LinkLuaModifier("modifier_grid_blight", "libraries/modifiers/grid_modifiers", LUA_MODIFIER_MOTION_NONE)