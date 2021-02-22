--[[
    Author: Steve Yoo(Dun1007), Martin Noya
    If target is too close, find another eligible target. If no such target exists, flee from the original target

    Instructions:
        Add "minimum_range" ability to unit.
        Add "MinimumRange" keyvalue on unit definition to control different range of each unit.
]]
function OnSiegeAttackStart(keys)
    local unit = keys.caster
    local target = keys.target
    local minRange = unit:GetKeyValue("MinimumRange")
    
    if unit:GetRangeToUnit(target) < minRange then
        -- find new target in range
        local targets = FindUnitsInRadius(unit:GetTeam(), unit:GetAbsOrigin(), nil, unit:Script_GetAttackRange()+unit:GetHullRadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
        for _,enemy in pairs(targets) do

            -- new eligible target must be over the min range and meet standard attack rules
            if enemy ~= target and unit:GetRangeToUnit(enemy) >= minRange and UnitCanAttackTarget(unit, enemy) and ShouldAggroNeutral(unit, enemy) then
                unit:MoveToTargetToAttack(enemy)
                return
            end
        end

        -- no eligible target, run!
        unit:Stop()
        Flee(unit, target)

        SendErrorMessageForSelectedUnit(unit:GetPlayerOwnerID(), "error_minimum_range", unit)
    end
end
