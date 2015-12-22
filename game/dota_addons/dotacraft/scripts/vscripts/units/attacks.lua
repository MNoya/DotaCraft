modifier_autoattack = class({})

function modifier_autoattack:DeclareFunctions()
    return { MODIFIER_PROPERTY_DISABLE_AUTOATTACK, }
end

function modifier_autoattack:OnCreated( params )
    if not IsServer() then return end

    local unit = self:GetParent()
    unit.attack_target = nil
    unit.disable_autoattack = 0
    self:StartIntervalThink(0.03)
end

function modifier_autoattack:GetDisableAutoAttack( params )
    local bDisabled = self:GetParent().disable_autoattack

    if bDisabled == 1 then
        if not self.thinking then
            self.thinking = true
            self:StartIntervalThink(0.1)
        end
    elseif self.thinking then
        self.thinking = false
        self:StartIntervalThink(0.03)
    end

    return bDisabled
end

function modifier_autoattack:OnIntervalThink()
    local unit = self:GetParent()

    AggroFilter(unit)
       
    -- Disabled autoattack state
    if unit.disable_autoattack == 1 then
        local enemies = FindEnemiesInRadius(unit, unit:GetAcquisitionRange())
        if #enemies > 0 then
            -- If an enemy is valid, attack it and stop the thinker
            for _,enemy in pairs(enemies) do
                if UnitCanAttackTarget(unit, enemy) and not enemy:HasModifier("modifier_neutral_sleep") then
                    Attack(unit, enemy)
                    return
                end
            end
        end
    end
end

function modifier_autoattack:IsHidden()
    return true
end

------------------------------------------------------------------------------------

modifier_autoattack_passive = class({})

function modifier_autoattack_passive:DeclareFunctions()
    return { MODIFIER_PROPERTY_DISABLE_AUTOATTACK }
end

function modifier_autoattack_passive:OnCreated( params )
    if not IsServer() then return end

    local unit = self:GetParent()
    unit.attack_target = nil
    unit.disable_autoattack = 0
    if unit:HasAttackCapability() then
        self:StartIntervalThink(0.03)
    end
end

function modifier_autoattack_passive:OnIntervalThink()
    local unit = self:GetParent()

    -- If the last order was not an Attack-Move or Attack-Target order, disable autoattack
    if not (unit.current_order == DOTA_UNIT_ORDER_ATTACK_MOVE or unit.current_order == DOTA_UNIT_ORDER_ATTACK_TARGET) then
        DisableAggro(unit)
        return
    else
        AggroFilter(unit)
    end
end

function modifier_autoattack_passive:GetDisableAutoAttack( params )
    -- Enable autoattack in case there are valid attackable units nearby and the passive unit its set to aggro
    local unit = self:GetParent()
    if (unit.disable_autoattack == 1 and unit.current_order == DOTA_UNIT_ORDER_ATTACK_MOVE or unit.current_order == DOTA_UNIT_ORDER_ATTACK_TARGET) then
        local enemies = FindEnemiesInRadius(unit, unit:GetAcquisitionRange())
        if #enemies > 0 then
            for _,enemy in pairs(enemies) do
                if UnitCanAttackTarget(unit, enemy) then
                    unit.disable_autoattack = 0
                    break
                end
            end
        end
    end

    local bDisabled = unit.disable_autoattack

    if bDisabled == 1 then
        if not self.thinking then
            self.thinking = true
            self:StartIntervalThink(0.1)
        end
    elseif self.thinking then
        self.thinking = false
        self:StartIntervalThink(0.03)
    end

    return bDisabled
end

function modifier_autoattack_passive:IsHidden()
    return true
end

------------------------------------------------------------------------------------

function AggroFilter( unit )
    local target = unit:GetAttackTarget() or unit:GetAggroTarget()

    if target then
        local bCanAttackTarget = UnitCanAttackTarget(unit, target) and (not target:HasModifier("modifier_neutral_sleep") or unit.attack_target_order == target)

        if unit.disable_autoattack == 0 then
            -- The unit acquired a new attack target
            if target ~= unit.attack_target then
                if bCanAttackTarget then
                    Attack(unit, target)
                    return
                else
                    -- Is there any enemy unit nearby the invalid one that this unit can attack?
                    local enemies = FindEnemiesInRadius(unit, unit:GetAcquisitionRange())
                    if #enemies > 0 then
                        for _,enemy in pairs(enemies) do
                            if UnitCanAttackTarget(unit, enemy) then
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
end

-- Aggro a target
function Attack( unit, target )
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
        if UnitCanAttackTarget(unit, attacker) then
            Attack(unit, attacker)
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