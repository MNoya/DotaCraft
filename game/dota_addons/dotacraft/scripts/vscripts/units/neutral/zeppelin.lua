function InitCargo(event)
    local caster = event.caster
    caster.units = {} -- Hold units being transported
    caster.transportCount = 0
    caster.maxTransportCount = event.ability:GetSpecialValueFor("capacity")
    caster.unloadAbility = caster:FindAbilityByName("zeppelin_unload")

    -- Create indicator count, team only
end

function Load(event)
    local caster = event.caster
    local ability = event.ability
    local target = event.target

    -- If the target can be carried, grab it
    local size = target:GetKeyValue("TransportSize") or 1
    
    if not target:IsFlyingUnit() and caster.transportCount + size <= caster.maxTransportCount then
        caster.transportCount = caster.transportCount + size
        table.insert(caster.units, target)
        target:AddNoDraw()
        ability:ApplyDataDrivenModifier(caster,target,"modifier_zeppelin_transporting",{})
        Timers:CreateTimer(0.1, function()
            target:SetParent(caster,"attach_hitloc")
        end)
    else
        return
    end

    if caster.unloadAbility:IsHidden() then
        caster.unloadAbility:SetHidden(false)
    end
end

function Unload(event)
    local caster = event.caster
    local target = table.remove(caster.units)
    if target then
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
    else
        caster.transportCount = 0
        caster:RemoveModifierByName("modifier_zeppelin_unloading")
        event.ability:SetHidden(true)
    end
end

function OnDeath(event)
    local caster = event.caster
    for _,target in pairs(caster.units) do
        target:SetParent(nil,"")
        target:SetForwardVector(Vector(1,0,0))
        target:SetAbsOrigin(caster:GetAbsOrigin()+RandomVector(RandomInt(1,100)))
        target:RemoveModifierByName("modifier_zeppelin_transporting")
        target:RemoveNoDraw()
    end
end