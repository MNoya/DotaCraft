function InitCargo(event)
    local caster = event.caster
    caster.units = {} -- Hold units being transported
    caster.transportCount = 0
    caster.maxTransportCount = event.ability:GetSpecialValueFor("capacity")
    caster.loadAbility = event.ability
    caster.unloadAbility = caster:FindAbilityByName("zeppelin_unload")
    caster.counter_particle = ParticleManager:CreateParticleForTeam("particles/custom/transport_counter.vpcf", PATTACH_OVERHEAD_FOLLOW, caster, caster:GetTeamNumber())
end

function Load(event)
    local caster = event.caster
    local ability = event.ability
    local target = event.target

    -- If the target can be carried, grab it
    if target:IsTransportableOnZeppelin(caster) then
        local size = target:GetKeyValue("TransportSize") or 1
        caster.transportCount = caster.transportCount + size
        table.insert(caster.units, target)
        target:AddNoDraw()
        target:Stop()
        ability:ApplyDataDrivenModifier(caster,target,"modifier_zeppelin_transporting",{})
        Timers:CreateTimer(0.1, function()
            target:SetParent(caster,"attach_hitloc")
        end)
        SetCounter(caster.counter_particle, caster.transportCount, caster.maxTransportCount)

        local playerID = target:GetPlayerOwnerID()
        local selectedUnits = PlayerResource:GetSelectedEntities(playerID)
        local numSelected = TableCount(selectedUnits)
        if PlayerResource:IsUnitSelected(playerID, target) then
            if numSelected == 1 then
                PlayerResource:AddToSelection(playerID, caster)
            end
            PlayerResource:RemoveFromSelection(playerID, target)
        end

        if caster.transportCount == caster.maxTransportCount then
            ability:SetActivated(false)
        end
    else
        return
    end

    if caster.unloadAbility:IsHidden() then
        caster.unloadAbility:SetHidden(false)
    end
end

function UnloadStart(event)
    local caster = event.caster
    local point = event.target_points[1]

    -- Prevent landing on deep water/blocked terrain (Error: "Unable to land there")
    local treeBlocked = GridNav:IsNearbyTree(point, 30, true)
    local terrainBlocked = not GridNav:IsTraversable(point) or GridNav:IsBlocked(point)
    local location = point
    if treeBlocked or terrainBlocked then
        location = BuildingHelper:FindClosestEmptyPositionNearby(point, 1, 300, true)
        if not location then
            SendErrorMessage(caster:GetPlayerOwnerID(), "error_unable_to_land_there")
            return
        end
    end

    local ability = event.ability
    ability:ApplyDataDrivenModifier(caster,caster,"modifier_zeppelin_unloading_order",{})
    ability.unloadingTimer = Timers:CreateTimer(0.03, function()
        caster:MoveToPosition(location)
        if (caster:GetAbsOrigin()-location):Length2D() > 50 then
            return 0.03
        else
            caster:RemoveModifierByName("modifier_zeppelin_unloading_order")
            ability:ApplyDataDrivenModifier(caster,caster,"modifier_zeppelin_unloading",{})
        end
    end)
end

function CancelUnload(event)
    local ability = event.ability
    if ability.unloadingTimer then
        Timers:RemoveTimer(ability.unloadingTimer)
        ability.unloadingTimer = nil
    end
end

function Unload(event)
    local caster = event.caster
    local target = table.remove(caster.units)
    if target then
        target:Stop()
        target:SetParent(nil,"")
        target:SetForwardVector(Vector(1,0,0))
        target:SetAbsOrigin(caster:GetAbsOrigin())
        target:RemoveModifierByName("modifier_zeppelin_transporting")
        Timers:CreateTimer(0.1, function()
            target:RemoveNoDraw()
        end)

        local size = target:GetKeyValue("TransportSize") or 1
        caster.transportCount = caster.transportCount - size
        
        if caster.transportCount == 0 then
            caster:RemoveModifierByName("modifier_zeppelin_unloading")
            event.ability:SetHidden(true)
        end
        SetCounter(caster.counter_particle, caster.transportCount, caster.maxTransportCount)
    else
        caster.transportCount = 0
        caster:RemoveModifierByName("modifier_zeppelin_unloading")
        event.ability:SetHidden(true)
    end

    if caster.transportCount <= caster.maxTransportCount then
        caster.loadAbility:SetActivated(true)
    end
end

function SetCounter(particle, count, max)
    for i=1,count do
        ParticleManager:SetParticleControl(particle, i, Vector(1,0,0))
    end
    for i=count+1,8 do
        ParticleManager:SetParticleControl(particle, i, Vector(0,0,0))
    end
end

function OnDeath(event)
    local caster = event.caster
    local bKill = false

    -- If there is no free terrain to land the units nearby, kill all
    local origin = caster:GetAbsOrigin()
    local treeBlocked = GridNav:IsNearbyTree(origin, 30, true)
    local terrainBlocked = not GridNav:IsTraversable(origin) or GridNav:IsBlocked(origin)
    if treeBlocked or terrainBlocked then
        bKill = BuildingHelper:FindClosestEmptyPositionNearby(origin, 1, 300) ~= nil
    end

    local ability = event.ability
    for _,target in pairs(caster.units) do
        if bKill then
            target:ForceKill(false)
        else
            target:Stop()
            target:SetParent(nil,"")
            target:SetForwardVector(Vector(1,0,0))
            target:SetAbsOrigin(caster:GetAbsOrigin()+RandomVector(RandomInt(1,100)))
            target:RemoveModifierByName("modifier_zeppelin_transporting")
            ability:ApplyDataDrivenModifier(caster,target,"modifier_dizziness",{})
            target:RemoveNoDraw()
        end
    end
    if caster.counter_particle then
        ParticleManager:DestroyParticle(caster.counter_particle,true)
    end
    caster.units = {}
end