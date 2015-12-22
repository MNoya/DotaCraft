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