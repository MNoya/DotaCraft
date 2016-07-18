modifier_repairing = class({}) -- Stackable modifier on the target being repaired
modifier_builder_repairing = class({}) -- Tooltip builder repairing

function modifier_repairing:IsPurgable() return false end
function modifier_builder_repairing:IsPurgable() return false end