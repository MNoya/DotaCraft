function TeleportationStart(event)
    local caster = event.caster
    local target = event.target
    local point = event.target_points[1]

    -- If no target handle, it was ground targeted
    local playerID = caster:GetPlayerOwnerID()
    if not target or selfTarget then
        target = Players:FindClosestFriendlyUnit(playerID, point, function(unit) return unit ~= caster and not unit:IsFlyingUnit() end)
    end

    local ability = event.ability
    local duration = ability:GetChannelTime()
    local color = dotacraft:ColorForPlayer(playerID)
    ability.target = target

    -- Caster modifier effects
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_staff_of_teleportation_caster", {duration=duration})

    local caster_modifier = caster:FindModifierByNameAndCaster("modifier_staff_of_teleportation_caster", caster)
    local caster_particle = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(caster_particle, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(caster_particle, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(caster_particle, 2, color)
    ParticleManager:SetParticleControl(caster_particle, 4, caster:GetAbsOrigin())
    caster_modifier:AddParticle(caster_particle, false, false, 1, false, false)

    -- Target modifier effects
    ability:ApplyDataDrivenModifier(caster, target, "modifier_staff_of_teleportation_target", {duration=duration})

    local target_modifier = target:FindModifierByNameAndCaster("modifier_staff_of_teleportation_target", caster)
    local target_particle = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(target_particle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(target_particle, 1, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(target_particle, 2, color)
    ParticleManager:SetParticleControl(target_particle, 4, target:GetAbsOrigin())
    target_modifier:AddParticle(target_particle, false, false, 1, false, false)
end

function TeleportationInterrupted(event)
    local caster = event.caster
    local ability = event.ability
    local target = ability.target

    caster:RemoveModifierByName("modifier_staff_of_teleportation_caster")
    target:RemoveModifierByName("modifier_staff_of_teleportation_target")
end

function TeleportationSuccess(event)
    local caster = event.caster
    local ability = event.ability
    local target = ability.target

    caster:EmitSound("Hero_Chen.TeleportOut")
    ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_test_of_faith.vpcf", PATTACH_ABSORIGIN, caster)

    caster:FindClearSpace(target:GetAbsOrigin())

    ability.target = nil
end

---------------------------------------------------------------------------

function Preservation(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local playerID = caster:GetPlayerOwnerID()

    if target:GetPlayerOwnerID() ~= playerID then
        SendErrorMessage(playerID, "error_cant_target_friendly")
        ability:EndCooldown()
    else
        local city_center = Players:FindHighestLevelCityCenter(target)
        caster:EmitSound("Hero_Chen.TeleportOut")
        ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_test_of_faith.vpcf", PATTACH_ABSORIGIN, target)
        FindClearSpaceForUnit(target, city_center:GetAbsOrigin(), true)
    end
end

---------------------------------------------------------------------------

function Sanctuary(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local playerID = caster:GetPlayerOwnerID()

    if target:GetPlayerOwnerID() ~= playerID then
        SendErrorMessage(playerID, "error_cant_target_friendly")
        ability:EndCooldown()
    else
        local city_center = Players:FindHighestLevelCityCenter(target)
        caster:EmitSound("Hero_Chen.TeleportOut")
        ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_test_of_faith.vpcf", PATTACH_ABSORIGIN, target)
        FindClearSpaceForUnit(target, city_center:GetAbsOrigin(), true)
        ability:ApplyDataDrivenModifier(caster, target, "modifier_staff_of_sanctuary_heal", {})
    end
end

function HealCheck(event)
    local target = event.target
    if target:GetHealthDeficit() == 0 then
        target:RemoveModifierByName("modifier_staff_of_sanctuary_heal")
    end
end