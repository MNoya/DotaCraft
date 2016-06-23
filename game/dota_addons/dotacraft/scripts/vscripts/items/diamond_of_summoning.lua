-- Capture up to 12 units and project them towards the caster
function SummoningStart(event)
    local caster = event.caster
    local point = event.target_points[1]
    local ability = event.ability
    local radius = ability:GetSpecialValueFor("radius")
    local max_teleport_units = ability:GetSpecialValueFor("teleport_units")

    -- Beware of refreshing this ability
    if ability.teleport_units and #ability.teleport_units > 0 then
        for k,v in pairs(ability.teleport_units) do
            v:RemoveNoDraw()
            v:RemoveModifierByName("modifier_invulnerable")
        end
        ability.teleport_units = {}
        return
    end

    local allies = FindAlliesInRadius(caster, radius, point)
    if #allies == 0 then return end
    local teleport_units = {}
    local grabbed = 0

    for _,ally in pairs(allies) do
        if not IsCustomBuilding(ally) and ally ~= caster and not ally:IsUnselectable() then
            table.insert(teleport_units, ally)
            grabbed = grabbed + 1
            if grabbed == max_teleport_units then break end
        end
    end
    ability.teleport_units = teleport_units

    caster:EmitSound("Hero_Pugna.NetherBlastPreCast")
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_netherblast.vpcf",PATTACH_CUSTOMORIGIN,hero)
    ParticleManager:SetParticleControl(particle,0,point)
    ParticleManager:SetParticleControl(particle,1,Vector(radius,radius,radius))

    for _,teleport_target in pairs(teleport_units) do
        teleport_target:AddNoDraw()
        teleport_target:AddNewModifier(nil,nil,"modifier_invulnerable",{})

        local particle = ParticleManager:CreateParticle("particles/econ/items/necrolyte/necrophos_sullen/necro_sullen_pulse_friend_explosion.vpcf",PATTACH_CUSTOMORIGIN,caster)
        ParticleManager:SetParticleControl(particle, 0, teleport_target:GetAbsOrigin())
        ParticleManager:SetParticleControlEnt(particle, 3, teleport_target, PATTACH_POINT_FOLLOW, "attach_hitloc", teleport_target:GetAbsOrigin(), true)
    end

    Timers:CreateTimer(0.1, function()
        for _,teleport_target in pairs(teleport_units) do
            local projTable = {
                EffectName = "particles/econ/items/necrolyte/necrophos_sullen/necro_sullen_pulse_friend.vpcf",
                Ability = ability,
                Target = caster,
                Source = teleport_target,
                bDodgeable = false,
                bProvidesVision = false,
                vSpawnOrigin = teleport_target:GetAbsOrigin(),
                iMoveSpeed = 700,
                iVisionRadius = 0,
            }
            ProjectileManager:CreateTrackingProjectile( projTable )
        end
    end)
end

-- Teleport one of the units
function SummoningEnd(event)
    local ability = event.ability
    local caster = event.caster
    local index = RandomInt(1, #ability.teleport_units)
    local target = ability.teleport_units[index]
    table.remove(ability.teleport_units, index)
    
    local particle = ParticleManager:CreateParticle("particles/econ/items/necrolyte/necrophos_sullen/necro_sullen_pulse_friend_explosion.vpcf",PATTACH_CUSTOMORIGIN,caster)
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControlEnt(particle, 3, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

    FindClearSpaceForUnit(target,caster:GetAbsOrigin()+RandomVector(100),true)
    target:RemoveNoDraw()
    target:RemoveModifierByName("modifier_invulnerable")
end