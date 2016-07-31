-- Takes control over a unit
function Charm( event )
    local caster = event.caster
    local target = event.target
    local hp = target:GetHealth()
    target:TransferOwnership(caster:GetPlayerOwnerID())
    ExecuteOrderFromTable({UnitIndex = target:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_STOP, Queue = false})
end