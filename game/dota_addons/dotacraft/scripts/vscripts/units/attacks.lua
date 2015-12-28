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
-- Point ground ability
function AttackGround( event )
    local caster = event.caster
    local ability = event.ability
    local position = event.target_points[1]
    local start_time = caster:GetAttackAnimationPoint() -- Time to wait to fire the projectile
    local minimum_range = ability:GetSpecialValueFor("minimum_range")

    if (position - caster:GetAbsOrigin()):Length() < minimum_range then
        SendErrorMessage(caster:GetPlayerOwnerID(), "#error_minimum_range")
        caster:Interrupt()
        return
    end

    ToggleOn(ability)

    -- Disable autoattack acquiring
    caster:RemoveModifierByName("modifier_autoattack")
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_attacking_ground", {})

    -- Time fake attacks
    ability.attack_ground_timer = Timers:CreateTimer(function()
        caster:StartGesture(ACT_DOTA_ATTACK)
        ability.attack_ground_timer_attack = Timers:CreateTimer(start_time, function()
            ability:StartCooldown( 1/caster:GetAttacksPerSecond() - start_time)

            -- Create the projectile and deal damage on hit
            AttackGroundPos(caster, position)
        end)

        local time = 1 / caster:GetAttacksPerSecond()   

        return  time
    end)
end

function StopAttackGround( event )
    local caster = event.caster
    local ability = event.ability

    caster:RemoveGesture(ACT_DOTA_ATTACK)
    if (ability.attack_ground_timer) then Timers:RemoveTimer(ability.attack_ground_timer) end
    if (ability.attack_ground_timer_attack) then Timers:RemoveTimer(ability.attack_ground_timer_attack) end
    caster:AddNewModifier(caster, nil, "modifier_autoattack", {})
    caster:RemoveModifierByName("modifier_attacking_ground")

    ToggleOff(ability)
end

-- Attack Ground for Artillery attacks, redirected from FilterProjectile
function AttackGroundPos(attacker, position)
    local speed = attacker:GetProjectileSpeed()
    local projectile = ParticleManager:CreateParticle(GetRangedProjectileName(attacker), PATTACH_CUSTOMORIGIN, attacker)
    ParticleManager:SetParticleControl(projectile, 0, attacker:GetAttachmentOrigin(attacker:ScriptLookupAttachment("attach_attack1")))
    ParticleManager:SetParticleControl(projectile, 1, position)
    ParticleManager:SetParticleControl(projectile, 2, Vector(speed, 0, 0))
    ParticleManager:SetParticleControl(projectile, 3, position)

    local distanceToTarget = (attacker:GetAbsOrigin() - position):Length2D()
    local time = distanceToTarget/speed
    Timers:CreateTimer(time, function()
        -- Destroy the projectile
        ParticleManager:DestroyParticle(projectile, false)

        -- Deal ground attack damage
        SplashAttackGround( attacker, position )
    end)
end

-- Deals damage based on the attacker around a position, with full/medium/small factors based on distance from the impact
function SplashAttackGround( attacker, position )
    local full_damage_radius = GetFullSplashRadius(attacker)
    local medium_damage_radius = GetMediumSplashRadius(attacker)
    local small_damage_radius = GetSmallSplashRadius(attacker)

    local full_damage = attacker:GetAttackDamage()
    local medium_damage = full_damage * GetMediumSplashDamage(attacker)
    local small_damage = full_damage * GetSmallSplashDamage(attacker)
    medium_damage = medium_damage + small_damage -- Small damage gets added to the mid aoe

    local splash_targets = FindAllUnitsAroundPoint( attacker, position, small_damage_radius )
    if DEBUG then
        DebugDrawCircle(position, Vector(255,0,0), 50, full_damage_radius, true, 3)
        DebugDrawCircle(position, Vector(255,0,0), 50, medium_damage_radius, true, 3)
        DebugDrawCircle(position, Vector(255,0,0), 50, small_damage_radius, true, 3)
    end

    -- Damage each unit only once
    for _,unit in pairs(splash_targets) do
        local distance_from_impact = (unit:GetAbsOrigin() - position):Length2D()
        if distance_from_impact <= full_damage_radius then
            ApplyDamage({ victim = unit, attacker = attacker, damage = full_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
        elseif distance_from_impact <= medium_damage_radius then
            ApplyDamage({ victim = unit, attacker = attacker, damage = medium_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
        else
            ApplyDamage({ victim = unit, attacker = attacker, damage = small_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
        end
    end
    
    -- Hit ground particle. This could be each particle endcap instead
    local hit = ParticleManager:CreateParticle("particles/units/heroes/hero_magnataur/magnus_dust_hit.vpcf", PATTACH_CUSTOMORIGIN, attacker)
    ParticleManager:SetParticleControl(hit, 0, position)

    -- Tree damage (NElves only deal ground damage with upgrade)
    if not IsNightElf(attacker) or attacker:HasAbility("nightelf_vorpal_blades") then
        local damage_to_trees = 10
        local trees = GridNav:GetAllTreesAroundPoint(position, small_damage_radius, true)

        for _,tree in pairs(trees) do
            if tree:IsStanding() then
                tree.health = tree.health - damage_to_trees

                -- Hit tree particle
                local particleName = "particles/custom/tree_pine_01_destruction.vpcf"
                local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, attacker)
                ParticleManager:SetParticleControl(particle, 0, tree:GetAbsOrigin())
            end
            if tree.health <= 0 then
                tree:CutDown(attacker:GetPlayerOwnerID())
            end
        end
    end
end

function SplashAttackUnit( attack_damage, attacker, victim )
    local position = victim:GetAbsOrigin()
    local medium_radius = GetMediumSplashRadius(attacker)
    local medium_damage = attack_damage * GetMediumSplashDamage(attacker)
    local small_radius = GetSmallSplashRadius(attacker)
    local small_damage = attack_damage * GetSmallSplashDamage(attacker)

    --print("Attacked for "..attack_damage.." - Splashing "..medium_damage.." damage in "..medium_radius.." (medium radius) and "..small_damage.." in "..small_radius.." (small radius)")

    local targets_medium_radius = FindAllUnitsInRadius(target, medium_radius)
    DebugDrawCircle(position, Vector(255,0,0), 100, medium_radius, true, 3)
    for _,v in pairs(targets_medium_radius) do
        if v ~= attacker and v ~= victim then
            v.damage_from_splash = medium_damage
            ApplyDamage({ victim = v, attacker = attacker, damage = medium_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
        end
    end

    local targets_small_radius = FindAllUnitsInRadius(target, small_radius)
    DebugDrawCircle(position, Vector(255,0,0), 100, small_radius, true, 3)
    for _,v in pairs(targets_small_radius) do
        if v ~= attacker and v ~= victim then
            v.damage_from_splash = small_damage
            ApplyDamage({ victim = v, attacker = attacker, damage = small_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
        end
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