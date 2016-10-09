function TeleportStart( event )
    local caster = event.caster
    local target = event.target
    local point = event.target_points[1]
    local selfTarget = target == caster

    -- Prevent targeting anything that isnt a finished city center
    if target and not selfTarget then
        if not IsCityCenter(target) then
            SendErrorMessage(caster:GetPlayerID(), "error_must_target_town_hall")
            return
        elseif target:IsUnderConstruction() then
            SendErrorMessage(caster:GetPlayerID(), "error_building_under_construction")
            return
        end
    end

    -- If no target handle, it was ground targeted, find the closest allied city center to that point
    -- If self-targeted, find the highest level center of the player
    local playerID = caster:GetPlayerOwnerID()
    if not target then
        target = Players:FindClosestFriendlyCityCenter(playerID, point)
    elseif selfTarget then
        target = Players:FindHighestLevelCityCenter(playerID)
    end
    
    -- Start teleport
    local ability = event.ability
    local teleport_delay = ability:GetSpecialValueFor("teleport_delay")
    local radius = ability:GetSpecialValueFor("radius")
    
    -- Caster modifier effects
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_scroll_of_town_portal_caster", {duration=teleport_delay})

    local caster_modifier = caster:FindModifierByNameAndCaster("modifier_scroll_of_town_portal_caster", caster)
    local caster_particle = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(caster_particle, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(caster_particle, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(caster_particle, 2, dotacraft:ColorForPlayer(playerID))
    ParticleManager:SetParticleControl(caster_particle, 4, caster:GetAbsOrigin())
    caster_modifier:AddParticle(caster_particle, false, false, 1, false, false)

    -- Target modifier effects
    ability:ApplyDataDrivenModifier(caster, target, "modifier_scroll_of_town_portal_target", {duration=teleport_delay})

    local target_modifier = target:FindModifierByNameAndCaster("modifier_scroll_of_town_portal_target", caster)
    local target_particle = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(target_particle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(target_particle, 1, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(target_particle, 2, dotacraft:ColorForPlayer(playerID))
    ParticleManager:SetParticleControl(target_particle, 4, target:GetAbsOrigin())
    target_modifier:AddParticle(target_particle, false, false, 1, false, false)

    caster:EmitSound("Hero_KeeperOfTheLight.Recall.Cast")

    ability.teleportTimer = Timers:CreateTimer(teleport_delay, function()
        -- Teleport self-owned army in radius
        local player = caster:GetPlayerOwner()
        local team = caster:GetTeamNumber()
        local position = caster:GetAbsOrigin()
        local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
        local targets = FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

        for _,unit in pairs(targets) do
            if not IsCustomBuilding(unit) and not unit:IsWard() and not unit:IsDummy() and unit:GetPlayerOwner() == player then
                unit:FindClearSpace(target:GetAbsOrigin())
                unit:Stop()
            end
        end

        caster:FindClearSpace(target:GetAbsOrigin())

        caster:StopSound("Hero_KeeperOfTheLight.Recall.Cast")

        caster:RemoveModifierByName("modifier_scroll_of_town_portal_caster")
        target:RemoveModifierByName("modifier_scroll_of_town_portal_target")

        -- Spend the item
        UTIL_Remove(ability)
    end)
end

-- Modifier destroyed, either due to timeout or building destroyed
function TeleportEnd(event)
    local target = event.target
    if not target:IsAlive() then
        event.caster:RemoveModifierByName("modifier_scroll_of_town_portal_caster")
        Timers:RemoveTimer(event.ability.teleportTimer)
        UTIL_Remove(ability)
    end
end