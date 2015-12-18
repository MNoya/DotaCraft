modifier_autoattack = class({})

function modifier_autoattack:DeclareFunctions()
    return { MODIFIER_PROPERTY_DISABLE_AUTOATTACK }
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
        self:StartIntervalThink(-1)
    end

    return bDisabled
end

function modifier_autoattack:OnIntervalThink()
    if IsServer() then
        local unit = self:GetParent()
        -- Check for enemies around the unit
        local enemies = FindEnemiesInRadius(unit, unit:GetAcquisitionRange())
        if #enemies > 0 then
            -- If an enemy is valid, attack it and stop the thinker
            for _,enemy in pairs(enemies) do
                if UnitCanAttackTarget(unit, enemy) then
                    Attack(unit, enemy)
                    return
                end
            end
        else
            -- If no enemies are found, enable autoattack and stop the thinker
            unit.disable_autoattack = 0
        end
    end
end

function modifier_autoattack:IsHidden()
    return true
end
