if not Attacks then
    Attacks = class({})
end

function Attacks:Init()
    -- Build NetTable with the attacks enabled
    for name,values in pairs(GameRules.UnitKV) do
        if type(values)=="table" and values['AttacksEnabled'] then
            CustomNetTables:SetTableValue("attacks_enabled", name, {enabled = values['AttacksEnabled']})
        end
    end
end

-- Ground/Air Attack mechanics
function UnitCanAttackTarget( unit, target )
    if not target.IsCreature then return true end -- filter item drops
    local attacks_enabled = unit:GetAttacksEnabled()
    local target_type = GetMovementCapability(target)
    
    if attacks_enabled == "building" and not IsCustomBuilding(target) then return false end
  
    if not unit:HasAttackCapability() or unit:IsDisarmed() or target:IsInvulnerable() or target:IsAttackImmune() or not unit:CanEntityBeSeenByMyTeam(target)
        or (unit:GetAttackType() == "magic" and target:IsMagicImmune() and not IsCustomBuilding(target)) or (target:IsEthereal() and unit:GetAttackType() ~= "magic") then
            return false
    end

    return string.match(attacks_enabled, target_type)
end

-- Don't aggro a neutral if its not a direct order or is idle/sleeping
function ShouldAggroNeutral( unit, target )
    if IsNeutralUnit(target) or target:IsNightmared() then
        if unit.attack_target_order == target or target.state == AI_STATE_AGGRESSIVE or target.state == AI_STATE_RETURNING then
            return true
        end
    else
        return true --Only filter neutrals
    end
    return false
end

-- Check the Acquisition Range (stored on spawn) for valid targets that can be attacked by this unit
-- Neutrals shouldn't be autoacquired unless its a move-attack order or they attack first
function FindAttackableEnemies( unit, bIncludeNeutrals )
    local radius = unit.AcquisitionRange
    if not radius then return end
    local enemies = FindEnemiesInRadius( unit, radius )
    for _,target in pairs(enemies) do
        if UnitCanAttackTarget(unit, target) and not target:HasModifier("modifier_invisible") then
            --DebugDrawCircle(target:GetAbsOrigin(), Vector(255,0,0), 255, 32, true, 1)
            if bIncludeNeutrals then
                return target
            elseif target:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
                return target
            end
        end
    end
    return nil
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
        if not IsValidEntity(caster) or not caster:IsAlive() then return end
        Timers:CreateTimer(caster:TimeUntilNextAttack(), function() caster:StartGesture(ACT_DOTA_ATTACK) end)
        ability.attack_ground_timer_attack = Timers:CreateTimer(caster:TimeUntilNextAttack()+caster:GetAttackAnimationPoint(), function()
            -- Create the projectile and deal damage on hit
            AttackGroundPos(caster, position)
        end)

        local time = 1 / caster:GetAttacksPerSecond()   

        return time
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
    attacker:PerformAttack(attacker,false,false,false,false,false) --self-attack, used for putting the attack on cooldown, denied in damage filter

    local distanceToTarget = (attacker:GetAbsOrigin() - position):Length2D()
    local time = distanceToTarget/speed
    Timers:CreateTimer(time, function()
        -- Destroy the projectile
        ParticleManager:DestroyParticle(projectile, false)

        -- Deal ground attack damage
        SplashAttackGround( attacker, position )

        if attacker.BurningOil then
            attacker.BurningOil(position)
        end
    end)
end

-- Deals damage based on the attacker around a position, with full/medium/small factors based on distance from the impact
function SplashAttackGround(attacker, position)
    SplashAttackUnit(attacker, position)
    
    -- Hit ground particle. This could be each particle endcap instead
    local hit = ParticleManager:CreateParticle("particles/units/heroes/hero_magnataur/magnus_dust_hit.vpcf", PATTACH_CUSTOMORIGIN, attacker)
    ParticleManager:SetParticleControl(hit, 0, position)

    -- Tree damage (NElves only deal ground damage with upgrade)
    if not IsNightElf(attacker) or attacker:HasAbility("nightelf_vorpal_blades") then
        local damage_to_trees = 10
        local small_damage_radius = attacker:GetKeyValue("SplashSmallRadius") or 10
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

function SplashAttackUnit(attacker, position)
    local full_damage_radius = attacker:GetKeyValue("SplashFullRadius") or 0
    local medium_damage_radius = attacker:GetKeyValue("SplashMediumRadius") or 0
    local small_damage_radius = attacker:GetKeyValue("SplashSmallRadius") or 0

    local full_damage = attacker:GetAttackDamage()
    local medium_damage = full_damage * attacker:GetKeyValue("SplashMediumDamage") or 0
    local small_damage = full_damage * attacker:GetKeyValue("SplashSmallDamage") or 0
    medium_damage = medium_damage + small_damage -- Small damage gets added to the mid aoe

    local splash_targets = FindAllUnitsAroundPoint(attacker, position, small_damage_radius)
    if DEBUG then
        DebugDrawCircle(position, Vector(255,0,0), 50, full_damage_radius, true, 3)
        DebugDrawCircle(position, Vector(255,0,0), 50, medium_damage_radius, true, 3)
        DebugDrawCircle(position, Vector(255,0,0), 50, small_damage_radius, true, 3)
    end

    -- Damage each unit only once
    if attacker.FragmentationShard then
        for _,unit in pairs(splash_targets) do
            if not unit:HasFlyMovementCapability() then
                local distance_from_impact = (unit:GetAbsOrigin() - position):Length2D()
                local damage
                
                if attacker:IsOpposingTeam(unit:GetTeamNumber()) and unit:GetArmorType() == "unarmored" or unit:GetArmorType() == "medium" then
                    attacker:FragmentationShard(unit, position)
                    if distance_from_impact <= full_damage_radius then
                        damage = full_damage + 25
                    elseif distance_from_impact <= medium_damage_radius then
                        damage = medium_damage + 18
                    else
                        damage = small_damage + 12
                    end
                else
                    if distance_from_impact <= full_damage_radius then
                        damage = full_damage
                    elseif distance_from_impact <= medium_damage_radius then
                        damage = medium_damage
                    else
                        damage = small_damage
                    end
                end
                ApplyDamage({ victim = unit, attacker = attacker, damage = damage, ability = GameRules.Applier, damage_type = DAMAGE_TYPE_PHYSICAL})
            end
        end
    else
        for _,unit in pairs(splash_targets) do
            if not unit:HasFlyMovementCapability() then
                local distance_from_impact = (unit:GetAbsOrigin() - position):Length2D()
                if distance_from_impact <= full_damage_radius then
                    ApplyDamage({ victim = unit, attacker = attacker, damage = full_damage, ability = GameRules.Applier, damage_type = DAMAGE_TYPE_PHYSICAL})
                elseif distance_from_impact <= medium_damage_radius then
                    ApplyDamage({ victim = unit, attacker = attacker, damage = medium_damage, ability = GameRules.Applier, damage_type = DAMAGE_TYPE_PHYSICAL})
                else
                    ApplyDamage({ victim = unit, attacker = attacker, damage = small_damage, ability = GameRules.Applier, damage_type = DAMAGE_TYPE_PHYSICAL})
                end
            end
        end
    end
end

-- Returns "air" if the unit can fly
function GetMovementCapability( unit )
    return unit:HasFlyMovementCapability() and "air" or "ground"
end