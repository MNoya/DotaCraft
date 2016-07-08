-- Starts the ability, finds a target if it was point-targeted, keeps track of the units that will be teleported
function MassTeleportStart( event )
	local caster = event.caster
	local ability = event.ability
	local playerID = caster:GetPlayerOwnerID()
	local radius = ability:GetSpecialValueFor("radius")
	local target = event.target
    if not target then
        target = FindClosestUnitToTeleport(caster, event.target_points[1] )
    end
    if not target then
        ability:RefundManaCost()
        ability:EndCooldown()
        ability:OnChannelFinish(true)
        return
    end
	
	ability.teleport_target = target

    StartAnimation(caster, {duration=1.5, activity=ACT_DOTA_CAST_ABILITY_1, rate=0.75})
    Timers:CreateTimer(1.5, function() 
        if IsValidAlive(caster) and ability:IsChanneling() then
            StartAnimation(caster, {duration=1.5, activity=ACT_DOTA_CAST_ABILITY_1, rate=0.75})
        end
    end)

    local max_units_teleported = ability:GetSpecialValueFor("max_units_teleported")
    local nearby_units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, 0, FIND_CLOSEST, false)
    
    -- Filter by only units owned by this player, and units not being currently teleported by another spell
    ability.teleport_units = {}
    for k,unit in pairs(nearby_units) do
        if unit ~= caster and unit:GetPlayerOwnerID() == playerID and not unit.bTeleporting and (#ability.teleport_units <= max_units_teleported) and not IsCustomBuilding(unit) then
            unit.bTeleporting = true
            table.insert(ability.teleport_units, unit)
        end
    end

    -- Apply particle on the units, destroyed when the channel stops
    local particleName = "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_recall.vpcf"
    for _,unit in pairs(ability.teleport_units) do
        unit.teleport_particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, unit)
    end

    -- Apply particle on the target
    local color = dotacraft:ColorForTeam( caster:GetTeamNumber() )
    local particle_target = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(particle_target, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle_target, 1, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle_target, 2, Vector(color[1], color[2], color[3]))
    ParticleManager:SetParticleControl(particle_target, 4, target:GetAbsOrigin())
    ability.particle_target = particle_target
end

-- Stops the channeling sound and particles
function MassTeleportStop( event )
    local caster = event.caster
    local ability = event.ability
    local targets = ability.teleport_units

    caster:StopSound("Hero_KeeperOfTheLight.Recall.Cast")
    if not targets then return end

    for _,unit in pairs(targets) do
        if IsValidAlive(unit) then
            unit:Stop()
            unit.bTeleporting = nil
            ParticleManager:DestroyParticle(unit.teleport_particle,false)
        end
    end
    ParticleManager:DestroyParticle(ability.particle_target, true)
    ability.teleport_units = nil
    ability.teleport_target = nil
end

-- Teleports every initial target to the destination
function MassTeleport( event )
    local caster = event.caster
    local ability = event.ability
    local target = ability.teleport_target
    if not target then
        ability:OnChannelFinish(true)
        caster:Stop()
        return
    end

    local ability = event.ability
    local targets = ability.teleport_units
    local numUnits = #targets

    local gridPoints = GetGridAroundPoint(numUnits, target:GetAbsOrigin())
    for k,unit in pairs(targets) do
        FindClearSpaceForUnit(unit, gridPoints[k], true)
    end
    caster:FindClearSpace(target:GetAbsOrigin())
    MassTeleportStop(event)
end

function FindClosestUnitToTeleport( caster, position )
    local units = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, 2000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
    for _,unit in pairs(units) do
        if IsValidAlive(unit) and not IsCustomBuilding(unit) and not unit:IsFlyingUnit() then
            return unit
        end
    end
    return nil
end