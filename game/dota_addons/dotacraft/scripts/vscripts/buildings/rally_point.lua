function SpawnUnit( event )
    local caster = event.caster
    local playerID = caster:GetPlayerOwnerID()
    local hero = caster:GetOwner()
    local unit_name = event.UnitName
    local position = caster.initial_spawn_position
    local teamID = caster:GetTeam()

    -- Adjust Mountain Giant secondary unit
    if Players:HasResearch(playerID, "nightelf_research_resistant_skin") then
        unit_name = unit_name.."_resistant_skin"
    end

    -- Adjust Troll Berkserker upgraded unit
    if Players:HasResearch(playerID, "orc_research_berserker_upgrade") then
        unit_name = "orc_troll_berserker"
    end
        
    local unit = CreateUnitByName(unit_name, position, true, hero, hero, caster:GetTeamNumber())
    unit:AddNewModifier(caster, nil, "modifier_phased", { duration = 0.03 })
    unit:SetOwner(hero)
    unit:SetControllableByPlayer(playerID, true)
    
    event.target = unit
    MoveToRallyPoint(event)

    -- Recolor Huskar
    if string.match(unit_name, "orc_troll_berserker") then
        unit:SetRenderColor(255, 255, 0)
    end
end

-- Queues a movement command for the spawned unit to the rally point
-- Also adds the unit to the players army and looks for upgrades
function MoveToRallyPoint( event )
    local caster = event.caster
    local target = event.target
    local entityIndex = target:GetEntityIndex() -- The spawned unit
    local playerID = caster:GetPlayerOwnerID()

    -- Set the builders idle when they spawn
    if IsBuilder(target) then 
        target.state = "idle" 
    end

    dotacraft:ResolveRallyPointOrder(target, caster)

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    target:SetOwner(hero)
    Players:AddUnit(playerID, target)
    CheckAbilityRequirements(target, playerID)
end

function GetInitialRallyPoint( event )
    local caster = event.caster
    local result = {}

    local rally_spawn_position = GetRallySpawnPointPosition(caster)
    if rally_spawn_position then
        table.insert(result, rally_spawn_position)
    else
        print("Fail, no rally point position, this shouldn't happen")
    end

    return result
end

function GetRallySpawnPointPosition(building)
    local rally_point = GetRallyPointPosition(building)

    -- Get point at distance looking towards the rally point
    local origin = building:GetAbsOrigin()
    local towardsTarget = (rally_point - building:GetAbsOrigin()):Normalized()
    return origin + towardsTarget * building:GetCollisionSize()
end

function GetRallyPointPosition(building)
    local flag_type = building.flag_type
    local position
    if flag_type == "tree" then
        position =  building.flag:GetAbsOrigin()
    elseif flag_type == "position" then
        position = building.flag
    elseif flag_type == "target" or flag_type == "mine" then
        local target = building.flag
        if target and IsValidEntity(target) and target:IsAlive() then
            position = target:GetAbsOrigin()
        else
            position = building.initial_spawn_position
        end
    end
    return position
end