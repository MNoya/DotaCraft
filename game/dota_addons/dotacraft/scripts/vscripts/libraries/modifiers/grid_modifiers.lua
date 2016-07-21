modifier_grid_blight = class({})

function modifier_grid_blight:IsHidden() return true end
function modifier_grid_blight:IsPurgable() return false end
function modifier_grid_blight:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

LinkLuaModifier("modifier_grid_blight", "libraries/modifiers/grid_modifiers", LUA_MODIFIER_MOTION_NONE)