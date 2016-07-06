if not Corpses then
    Corpses = class({})
end

CORPSE_DURATION = 88
CORPSE_APPEAR_DELAY = 4

function Corpses:CreateFromUnit(killed)
    if LeavesCorpse( killed ) then
        local name = killed:GetUnitName()
        local position = killed:GetAbsOrigin()
        local team = killed:GetTeamNumber()
        Timers:CreateTimer(CORPSE_APPEAR_DELAY, function()
            Corpses:CreateByNameOnPosition(name, position, team)
        end)
    end
end

function Corpses:CreateByNameOnPosition(name, position, team)
    local corpse = CreateUnitByName("dotacraft_corpse", position, true, nil, nil, team)

    -- Keep a reference to its name and expire time
    corpse.corpse_expiration = GameRules:GetGameTime() + CORPSE_DURATION
    corpse.unit_name = name

    -- Remove itself after the corpse duration
    Timers:CreateTimer(CORPSE_DURATION, function()
        if corpse and IsValidEntity(corpse) then
            corpse:RemoveSelf()
        end
    end)
    return corpse
end

function SetNoCorpse( event )
    event.target.no_corpse = true
end

function FindCorpseInRadius( origin, radius )
    return Entities:FindByModelWithin(nil, CORPSE_MODEL, origin, radius) 
end

-- Custom Corpse Mechanic
function LeavesCorpse( unit )
    
    if not unit or not IsValidEntity(unit) then
        return false

    -- Heroes don't leave corpses (includes illusions)
    elseif unit:IsHero() then
        return false

    -- Ignore buildings 
    elseif unit.GetInvulnCount ~= nil then
        return false

    -- Ignore custom buildings
    elseif IsCustomBuilding(unit) then
        return false

    -- Ignore units that start with dummy keyword   
    elseif string.find(unit:GetUnitName(), "dummy") then
        return false

    -- Ignore units that were specifically set to leave no corpse
    elseif unit.no_corpse then
        return false

    -- Read the LeavesCorpse KV
    else
        local unit_info = GameRules.UnitKV[unit:GetUnitName()]
        if unit_info["LeavesCorpse"] and unit_info["LeavesCorpse"] == 0 then
            return false
        else
            -- Leave corpse     
            return true
        end
    end
end