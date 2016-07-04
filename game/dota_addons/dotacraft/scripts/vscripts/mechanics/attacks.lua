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