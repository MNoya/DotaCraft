if not Attacks then
    Attacks = class({})
end

function Attacks:Init()
    for name,values in pairs(GameRules.UnitKV) do
        -- Build NetTable with the attacks enabled
        if values['AttacksEnabled'] then
            CustomNetTables:SetTableValue("attacks_enabled", name, {enabled = values['AttacksEnabled']})
        end
    end

    for name,values in pairs(GameRules.HeroKV) do
        -- Build NetTable with the attacks enabled
        if values['AttacksEnabled'] then
            CustomNetTables:SetTableValue("attacks_enabled", name, {enabled = values['AttacksEnabled']})
        end
    end
end

ATTACK_TYPES = {
    ["DOTA_COMBAT_CLASS_ATTACK_BASIC"] = "normal",
    ["DOTA_COMBAT_CLASS_ATTACK_PIERCE"] = "pierce",
    ["DOTA_COMBAT_CLASS_ATTACK_SIEGE"] = "siege",
    ["DOTA_COMBAT_CLASS_ATTACK_LIGHT"] = "chaos",
    ["DOTA_COMBAT_CLASS_ATTACK_HERO"] = "hero",
    ["DOTA_COMBAT_CLASS_ATTACK_MAGIC"] = "magic",
}

ARMOR_TYPES = {
    ["DOTA_COMBAT_CLASS_DEFEND_SOFT"] = "unarmored",
    ["DOTA_COMBAT_CLASS_DEFEND_WEAK"] = "light",
    ["DOTA_COMBAT_CLASS_DEFEND_BASIC"] = "medium",
    ["DOTA_COMBAT_CLASS_DEFEND_STRONG"] = "heavy",
    ["DOTA_COMBAT_CLASS_DEFEND_STRUCTURE"] = "fortified",
    ["DOTA_COMBAT_CLASS_DEFEND_HERO"] = "hero",
}

-- Returns a string with the wc3 damage name
function GetAttackType( unit )
    if unit and IsValidEntity(unit) then
        local unitName = unit:GetUnitName()
        if GameRules.UnitKV[unitName] and GameRules.UnitKV[unitName]["CombatClassAttack"] then
            local attack_string = GameRules.UnitKV[unitName]["CombatClassAttack"]
            return ATTACK_TYPES[attack_string]
        elseif unit:IsHero() then
            return "hero"
        end
    end
    return 0
end

-- Returns a string with the wc3 armor name
function GetArmorType( unit )
    if unit and IsValidEntity(unit) then
        local unitName = unit:GetUnitName()
        if GameRules.UnitKV[unitName] and GameRules.UnitKV[unitName]["CombatClassDefend"] then
            local armor_string = GameRules.UnitKV[unitName]["CombatClassDefend"]
            return ARMOR_TYPES[armor_string]
        elseif unit:IsHero() then
            return "hero"
        end
    end
    return 0
end

-- Changes the Attack Type string defined in the KV, and the current visual tooltip
-- attack_type can be normal/pierce/siege/chaos/magic/hero
function SetAttackType( unit, attack_type )
    local unitName = unit:GetUnitName()
    if GameRules.UnitKV[unitName]["CombatClassAttack"] then
        local current_attack_type = GetAttackType(unit)
        unit:RemoveModifierByName("modifier_attack_"..current_attack_type)

        local attack_key = getIndexTable(ATTACK_TYPES, attack_type)
        GameRules.UnitKV[unitName]["CombatClassAttack"] = attack_key        

        ApplyModifier(unit, "modifier_attack_"..attack_type)
    end
end

-- Changes the Armor Type string defined in the KV, and the current visual tooltip
-- attack_type can be unarmored/light/medium/heavy/fortified/hero
function SetArmorType( unit, armor_type )
    local unitName = unit:GetUnitName()
    if GameRules.UnitKV[unitName]["CombatClassDefend"] then
        local current_armor_type = GetArmorType(unit)
        unit:RemoveModifierByName("modifier_armor_"..current_armor_type)

        local armor_key = getIndexTable(ARMOR_TYPES, armor_type)
        GameRules.UnitKV[unitName]["CombatClassDefend"] = armor_key

        ApplyModifier(unit, "modifier_armor_"..armor_type)
    end
end

function GetDamageForAttackAndArmor( attack_type, armor_type )
--[[
http://classic.battle.net/war3/basics/armorandweapontypes.shtml
        Unarm   Light   Medium  Heavy   Fort   Hero   
Normal  100%    100%    150%    100%    70%    100%   
Pierce  150%    200%    75%     100%    35%    50%    
Siege   150%    100%    50%     100%    150%   50%      
Chaos   100%    100%    100%    100%    100%   100%     
Hero    100%    100%    100%    100%    50%    100%

-- Custom Attack Types
Magic   100%    125%    75%     200%    35%    50%
Spells  100%    100%    100%    100%    100%   70%  
]]
    if attack_type == "normal" then
        if armor_type == "unarmored" then
            return 1
        elseif armor_type == "light" then
            return 1
        elseif armor_type == "medium" then
            return 1.5
        elseif armor_type == "heavy" then
            return 1 --1.25 in dota
        elseif armor_type == "fortified" then
            return 0.7
        elseif armor_type == "hero" then
            return 1 --0.75 in dota
        end

    elseif attack_type == "pierce" then
        if armor_type == "unarmored" then
            return 1.5
        elseif armor_type == "light" then
            return 2
        elseif armor_type == "medium" then
            return 0.75
        elseif armor_type == "heavy" then
            return 1 --0.75 in dota
        elseif armor_type == "fortified" then
            return 0.35
        elseif armor_type == "hero" then
            return 0.5
        end

    elseif attack_type == "siege" then
        if armor_type == "unarmored" then
            return 1.5 --1 in dota
        elseif armor_type == "light" then
            return 1
        elseif armor_type == "medium" then
            return 0.5
        elseif armor_type == "heavy" then
            return 1 --1.25 in dota
        elseif armor_type == "fortified" then
            return 1.5
        elseif armor_type == "hero" then
            return 0.5 --0.75 in dota
        end

    elseif attack_type == "chaos" then
        if armor_type == "unarmored" then
            return 1
        elseif armor_type == "light" then
            return 1
        elseif armor_type == "medium" then
            return 1
        elseif armor_type == "heavy" then
            return 1
        elseif armor_type == "fortified" then
            return 1 --0.4 in Dota
        elseif armor_type == "hero" then
            return 1
        end

    elseif attack_type == "hero" then
        if armor_type == "unarmored" then
            return 1
        elseif armor_type == "light" then
            return 1
        elseif armor_type == "medium" then
            return 1
        elseif armor_type == "heavy" then
            return 1
        elseif armor_type == "fortified" then
            return 0.5
        elseif armor_type == "hero" then
            return 1
        end

    elseif attack_type == "magic" then
        if armor_type == "unarmored" then
            return 1
        elseif armor_type == "light" then
            return 1.25
        elseif armor_type == "medium" then
            return 0.75
        elseif armor_type == "heavy" then
            return 2
        elseif armor_type == "fortified" then
            return 0.35
        elseif armor_type == "hero" then
            return 0.5
        end
    end
    return 1
end

-- Ground/Air Attack mechanics
function UnitCanAttackTarget( unit, target )
    local attacks_enabled = GetAttacksEnabled(unit)
    local target_type = GetMovementCapability(target)
  
    if not unit:HasAttackCapability() 
        or (target.IsInvulnerable and target:IsInvulnerable()) 
        or (target.IsAttackImmune and target:IsAttackImmune()) 
        or not unit:CanEntityBeSeenByMyTeam(target) then
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
    if unit:HasFlyMovementCapability() then
        return "air"
    else 
        return "ground"
    end
end

-- Searches for "AttacksEnabled" in the KV files
-- Default by omission is "none", other possible returns should be "ground,air" or "air"
function GetAttacksEnabled( unit )
    local unitName = unit:GetUnitName()
    local attacks_enabled

    if unit:IsHero() then
        attacks_enabled = GameRules.HeroKV[unitName]["AttacksEnabled"]
    elseif GameRules.UnitKV[unitName] then
        attacks_enabled = GameRules.UnitKV[unitName]["AttacksEnabled"]
    end

    return attacks_enabled or "none"
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