--[[
Author: Steve Yoo(Dun1007)
Date: 6/23/2016

If target is too close, find another eligible target. If no such target exists, flee 200 unit 

HOW TO USE: Add "minimum_range" ability to unit.
]]
function OnSiegeAttackStart(keys)
    local unit = keys.caster
    local target = keys.target

    if unit:GetRangeToUnit(target) < 250 then
        -- find new target that is closest.
        local targets = FindUnitsInRadius(unit:GetTeam(), unit:GetAbsOrigin(), nil, unit:GetAttackRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
        for k,v in pairs(targets) do
            -- new eligible target is not primary target, not within 250 range, and not a neutral unit
            if v ~= target and unit:GetRangeToUnit(v) > 250 and not IsNeutralUnit(v) then
                unit:MoveToTargetToAttack(v)
                return
            end
        end

        -- no eligible target, run!
        unit:Stop()
        Flee(unit, target)
        SendErrorMessage(unit:GetPlayerOwnerID(), "error_minimum_range")
    end

end
