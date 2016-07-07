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

    -- Remove the corpse from the game at any point
    function corpse:RemoveCorpse()
        if corpse.removal_timer then Timers:RemoveTimer(corpse.removal_timer) end
        if corpse.meat_wagon then
            -- Take the corpse from a meat wagon
            local stacks = corpse.meat_wagon:GetModifierStackCount("modifier_corpses", corpse.meat_wagon)
            if stacks > 0 then
                target:SetModifierStackCount("modifier_corpses", target, stacks-1)
            end
        end 
        -- Remove the entity
        UTIL_Remove(corpse)
    end

    -- Remove itself after the corpse duration
    corpse.removal_timer = Timers:CreateTimer(CORPSE_DURATION, function()
        if corpse and IsValidEntity(corpse) and not corpse.meat_wagon then
            UTIL_Remove(corpse)
        end
    end)
    return corpse
end

function Corpses:AreAnyInRadius(playerID, origin, radius)
    return self:FindClosestInRadius(playerID, origin, radius) ~= nil
end

function Corpses:AreAnyAlliedInRadius(playerID, origin, radius)
    return self:FindAlliedInRadius(playerID, origin, radius)[1] ~= nil
end

function Corpses:FindClosestInRadius(playerID, origin, radius)
    return self:FindInRadius(playerID, origin, radius)[1]
end

function Corpses:FindInRadius(playerID, origin, radius)
    local targets = FindUnitsInRadius(PlayerResource:GetTeam(playerID), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST, false)
    local corpses = {}
    for _,target in pairs(targets) do
        if IsCorpse(target) then
            if not target.meat_wagon or target.meat_wagon:GetPlayerOwnerID() == playerID then -- Check meat wagon ownership
                table.insert(corpses, target)
            end
        end
    end
    return corpses
end

function Corpses:FindAlliedInRadius(playerID, origin, radius)
    local targets = FindUnitsInRadius(PlayerResource:GetTeam(playerID), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST, false)
    local corpses = {}
    local teamNumber = PlayerResource:GetTeam(playerID)
    for _,target in pairs(targets) do
        if IsCorpse(target) and not target.meat_wagon then -- Ignore meat wagon corpses
            table.insert(corpses, target)
        end
    end
    for k,v in pairs(corpses) do
        print(k,v)
    end
    return corpses
end

function CDOTA_BaseNPC:SetNoCorpse()
    self.no_corpse = true
end

function SetNoCorpse(event)
    event.target:SetNoCorpse()
end

-- Needs a corpse_expiration and not being eaten by cannibalize
function IsCorpse(unit)
    return unit.corpse_expiration and not unit.being_eaten
end

-- Custom Corpse Mechanic
function LeavesCorpse(unit)
    
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
        local leavesCorpse = unit:GetKeyValue("LeavesCorpse")
        if leavesCorpse and leavesCorpse == 0 then
            return false
        else
            -- Leave corpse     
            return true
        end
    end
end