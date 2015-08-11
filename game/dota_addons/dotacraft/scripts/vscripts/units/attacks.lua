-- Acquire valid attackable targets if the target is idle or in Attack-Move state
function AutoAcquire( event )
    local unit = event.target

    if unit:HasModifier("modifier_shadow_meld_active") then
        return
    end

    if unit:IsIdle() or unit.bAttackMove then
        local target = FindAttackableEnemies(unit, unit.bAttackMove)
        if target then
            --print(unit:GetUnitName()," now attacking -> ",target:GetUnitName(),"Team: ",target:GetTeamNumber())
            unit.bAttackMove = false
            unit:MoveToTargetToAttack(target)
        end
    end
end

-- When holding position, only attack units within attack range
function HoldAcquire( event )
    local unit = event.target

    if unit:AttackReady() and not unit:IsAttacking() then
        local target = FindAttackableEnemies(unit, unit.bAttackMove)
        if target and unit:GetRangeToUnit(target) <= unit:GetAttackRange() then
            ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET, TargetIndex = target:GetEntityIndex(), Queue = false}) 
            HoldPosition(unit)
        else
            unit:SetAttacking(nil)
        end
    end
end

-- Check the Acquisition Range (stored on spawn) for valid targets that can be attacked by this unit
-- Neutrals shouldn't be autoacquired unless its a move-attack order or they attack first
function FindAttackableEnemies( unit, bIncludeNeutrals )
    local radius = unit.AcquisitionRange
    local enemies = FindEnemiesInRadius( unit, radius )
    for _,target in pairs(enemies) do
        if UnitCanAttackTarget(unit, target) then
            if bIncludeNeutrals then
                return target
            elseif target:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
                return target
            end
        end
    end
    return nil
end

-- If attacked and not currently attacking a unit
function AttackAggro( event )
    local unit = event.target
    local target = event.attacker

    if unit:IsIdle() then
        --print(unit:GetUnitName(), " was attacked by ", target:GetUnitName()," while idling")
        if UnitCanAttackTarget(unit, target) then
            unit:MoveToTargetToAttack(target)
        else
            -- Run away from the unit that attacked this
            local unit_origin = unit:GetAbsOrigin()
            local target_origin = target:GetAbsOrigin() 
            local flee_position = unit_origin + (unit_origin - target_origin):Normalized() * 200

            unit:MoveToPosition(flee_position) 
        end
    end
end