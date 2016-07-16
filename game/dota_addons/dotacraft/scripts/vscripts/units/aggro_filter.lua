function AggroFilter( unit )
    local target = unit:GetAttackTarget() or unit:GetAggroTarget()
    if target then
        local bCanAttackTarget = UnitCanAttackTarget(unit, target) and ShouldAggroNeutral(unit, target)
        if unit.disable_autoattack == 0 then
            -- The unit acquired a new attack target
            if target ~= unit.attack_target then
                if bCanAttackTarget then
                    unit.attack_target = target --Update the target, keep the aggro
                    return
                else
                    -- Is there any enemy unit nearby the invalid one that this unit can attack?
                    local enemies = FindEnemiesInRadius(unit, unit:GetAcquisitionRange())
                    if #enemies > 0 then
                        for _,enemy in pairs(enemies) do
                            if UnitCanAttackTarget(unit, enemy) and ShouldAggroNeutral(unit, enemy) then
                                --print("[ATTACK] attacking unit from modifier_autoattack thinker")
                                Attack(unit, enemy)
                                return
                            end
                        end
                    end
                end
            end
        end

        -- No valid enemies, disable autoattack. 
        if not bCanAttackTarget then
            DisableAggro(unit)
        end
    end
end

-- Disable autoattack and stop any aggro
function DisableAggro( unit )
    unit.disable_autoattack = 1
    if unit:GetAggroTarget() then
        unit:Stop() --Unit will still turn for a frame towards its invalid target
    end

    -- Resume attack move order
    if unit.current_order == DOTA_UNIT_ORDER_ATTACK_MOVE then
        unit.skip = true
        local orderTable = unit.orderTable
        local x = tonumber(orderTable["position_x"])
        local y = tonumber(orderTable["position_y"])
        local z = tonumber(orderTable["position_z"])
        local point = Vector(x,y,z) 
        ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE, Position = point, Queue = false})
    end
end

-- Aggro a target
function Attack( unit, target )
    -- if siege unit is attacking, let OnSiegeAttackStart control the behavior
    if unit:GetKeyValue("MinimumRange") then return end

    unit:AlertNearbyUnits(target, nil)
    unit:MoveToTargetToAttack(target)
    unit.attack_target = target
    unit.disable_autoattack = 0
end

-- Run away from the attacker
function Flee( unit, attacker )
    local unit_origin = unit:GetAbsOrigin()
    local target_origin = attacker:GetAbsOrigin() 
    local flee_position = unit_origin + (unit_origin - target_origin):Normalized() * 200

    unit:MoveToPosition(flee_position)
end

------------------------------------------------------------------------------------

-- If attacked and not currently attacking a unit
function OnAttacked( event )
    local unit = event.target
    local attacker = event.attacker
    if unit:HasModifier("modifier_shadow_meld_active") then
        return
    end

    local enemyAttack = unit:GetTeamNumber() ~= attacker:GetTeamNumber()

    if enemyAttack and unit:IsIdle() and not unit:GetAggroTarget() then
        unit:AlertNearbyUnits(attacker, nil)
        if UnitCanAttackTarget(unit, attacker) then
            --print("[ATTACK] attacking unit from OnAttacked block")
            if not unit:IsDisarmed() then
                Attack(unit, attacker)
            end
        else
            Flee(unit, attacker)
        end
    end
end

-- Builders use more passive attack rules: flee from attacks, even if they can fight back
function OnBuilderAttacked( event )
    local unit = event.target
    local attacker = event.attacker
    local enemyAttack = unit:GetTeamNumber() ~= attacker:GetTeamNumber()

    if enemyAttack and unit:IsIdle() and not unit:GetAggroTarget() then
        Flee(unit, attacker)
    end
end

------------------------------------------------------------------------------------

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

function WakeUp( event )
    local unit = event.unit
    local attacker = event.attacker

    for _,v in pairs(unit.allies) do
        if IsValidAlive(v) then
            v:RemoveModifierByName("modifier_neutral_sleep")
            v.state = AI_STATE_AGGRESSIVE
            if not IsValidAlive(v.aggroTarget) then
                v:MoveToTargetToAttack(attacker)
                v.aggroTarget = attacker
            end
        end
    end
end

function NeutralAggro( event )
    local unit = event.unit
    local attacker = event.attacker

    for _,v in pairs(unit.allies) do
        if IsValidAlive(v) and v.state == AI_STATE_IDLE then
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