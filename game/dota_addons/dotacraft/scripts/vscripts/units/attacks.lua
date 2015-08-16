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
            --print(unit:GetUnitName()," now attacking -> ",target:GetUnitName(),"Team: ",target:GetTeamNumber())
            ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET, TargetIndex = target:GetEntityIndex(), Queue = false}) 
            HoldPosition(unit)
        else
            unit:SetAttacking(nil)
        end
    end
end

-- If attacked and not currently attacking a unit
function AttackAggro( event )
    local unit = event.target
    local target = event.attacker

    if unit:HasModifier("modifier_shadow_meld_active") then
        return
    end

    if unit:IsIdle() then
        --print(unit:GetUnitName(), " was attacked by ", target:GetUnitName()," while idling")
        if UnitCanAttackTarget(unit, target) then
            --print(unit:GetUnitName()," now attacking -> ",target:GetUnitName(),"Team: ",target:GetTeamNumber())
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

function WakeUp( event )
    local unit = event.unit
    local attacker = event.attacker

    local allies = FindAlliesInRadius( unit, unit.AcquisitionRange)
    for _,v in pairs(allies) do
        v:RemoveModifierByName("modifier_neutral_sleep")
        v.state = AI_STATE_AGGRESSIVE
        if not IsValidAlive(v.aggroTarget) then
            v:MoveToTargetToAttack(attacker)
            v.aggroTarget = attacker
        end
    end
end

function NeutralAggro( event )
    local unit = event.unit
    local attacker = event.attacker

    local allies = FindAlliesInRadius( unit, unit.AcquisitionRange)
    for _,v in pairs(allies) do
        if v.state == AI_STATE_IDLE then
            v:RemoveModifierByName("modifier_neutral_idle_aggro")
            v.state = AI_STATE_AGGRESSIVE
            if not IsValidAlive(v.aggroTarget) then
                v:MoveToTargetToAttack(attacker)
                v.aggroTarget = attacker
            end
        end
    end
end

function CheatCheck( event )
    local ability_executed = event.event_ability
    if ability_executed and GameRules.ThereIsNoSpoon then
        ability_executed:RefundManaCost()
    end
end