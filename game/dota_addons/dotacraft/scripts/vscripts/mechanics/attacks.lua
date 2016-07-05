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
    local attacks_enabled = GetAttacksEnabled(unit)
    local target_type = GetMovementCapability(target)
  
    if not unit:HasAttackCapability() or target:IsInvulnerable() or target:IsAttackImmune()
        or not unit:CanEntityBeSeenByMyTeam(target) or (unit:GetAttackType() == "magic" and target:IsMagicImmune() and not IsCustomBuilding(target)) then
            return false
    end

    return string.match(attacks_enabled, target_type)
end

-- Don't aggro a neutral if its not a direct order or is idle/sleeping
function ShouldAggroNeutral( unit, target )
    if IsNeutralUnit(target) then
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
        caster:StartGesture(ACT_DOTA_ATTACK)
        ability.attack_ground_timer_attack = Timers:CreateTimer(caster:TimeUntilNextAttack(), function()
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
        if not unit:HasFlyMovementCapability() then
            local distance_from_impact = (unit:GetAbsOrigin() - position):Length2D()
            if distance_from_impact <= full_damage_radius then
                ApplyDamage({ victim = unit, attacker = attacker, damage = full_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
            elseif distance_from_impact <= medium_damage_radius then
                ApplyDamage({ victim = unit, attacker = attacker, damage = medium_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
            else
                ApplyDamage({ victim = unit, attacker = attacker, damage = small_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
            end
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

-- Returns "air" if the unit can fly
function GetMovementCapability( unit )
    return unit:HasFlyMovementCapability() and "air" or "ground"
end

-- Searches for "AttacksEnabled" in the KV files
-- Default by omission is "none", other possible returns should be "ground,air" or "air"
function GetAttacksEnabled( unit )
    return GameRules.UnitKV[unit:GetUnitName()]["AttacksEnabled"] or "none"
end

function SetAttacksEnabled( unit, attack_string )
    local unitName = unit:GetUnitName()
    local unitTable = GameRules.UnitKV[unitName] or GameRules.HeroKV[unitName]
    
    unitTable["AttacksEnabled"] = attack_string
    CustomNetTables:SetTableValue("attacks_enabled", unitName, {enabled = attack_string})
end

-- Searches for "AttacksEnabled", false by omission
function HasSplashAttack( unit )
    local unitName = unit:GetUnitName()
    local unit_table = GameRules.UnitKV[unitName]
    
    if unit_table then
        if unit_table["SplashAttack"] and unit_table["SplashAttack"] == 1 then
            return true
        end
    end

    return false
end

function GetFullSplashRadius( unit )
    local unitName = unit:GetUnitName()
    local unit_table = GameRules.UnitKV[unitName]
    if unit_table["SplashFullRadius"] then
        return unit_table["SplashFullRadius"]
    end
    return 0
end

function GetMediumSplashRadius( unit )
    local unitName = unit:GetUnitName()
    local unit_table = GameRules.UnitKV[unitName]
    if unit_table["SplashMediumRadius"] then
        return unit_table["SplashMediumRadius"]
    end
    return 0
end

function GetSmallSplashRadius( unit )
    local unitName = unit:GetUnitName()
    local unit_table = GameRules.UnitKV[unitName]
    if unit_table["SplashSmallRadius"] then
        return unit_table["SplashSmallRadius"]
    end
    return 0
end

function GetMediumSplashDamage( unit )
    local unitName = unit:GetUnitName()
    local unit_table = GameRules.UnitKV[unitName]
    if unit_table["SplashMediumDamage"] then
        return unit_table["SplashMediumDamage"]
    end
    return 0
end

function GetSmallSplashDamage( unit )
    local unitName = unit:GetUnitName()
    local unit_table = GameRules.UnitKV[unitName]
    if unit_table["SplashSmallDamage"] then
        return unit_table["SplashSmallDamage"]
    end
    return 0
end