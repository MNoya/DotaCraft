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
                if UnitCanAttackTarget(unit, enemy) and ShouldAggroNeutral(unit, enemy) then
                    --print("[ATTACK] attacking unit from modifier_autoattack thinker")
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
                if UnitCanAttackTarget(unit, enemy) and ShouldAggroNeutral(unit, enemy) then
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