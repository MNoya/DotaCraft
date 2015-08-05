-- When the unit starts attacking another, check if its enabled attacks actually allow it
function AttackFilter( event )
	local unit = event.attacker
	local target = event.target

	print("AttackFilter: ",unit, target, UnitCanAttackTarget(unit, target))

	--print(unit:GetAttackTarget():GetUnitName())

	if UnitCanAttackTarget(unit, target) then
        ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET, TargetIndex = target:GetEntityIndex(), Queue = false})
    else
        -- Move to position
        --ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, TargetIndex = target:GetEntityIndex(), Position = target:GetAbsOrigin(), Queue = false})

        -- Stop idle acquire
        unit:Stop()
        unit:SetIdleAcquire(false)
    end
end