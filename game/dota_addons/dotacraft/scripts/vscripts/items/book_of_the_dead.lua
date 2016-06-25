function BookSpawn(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetSpecialValueFor("duration")

    local fv = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
    local distance = event.distance

    local fp1 = origin + fv * UNIT_FORMATION_DISTANCE
    local row1 = GetGridAroundPoint(8, fp1, fv)
    for i=1,4 do
        BookSpawnSkeletonAt("undead_skeleton_archer", row1[i], caster, duration)
    end

    local fp2 = fp1 + fv * UNIT_FORMATION_DISTANCE
    local row1 = GetGridAroundPoint(8, fp2, fv)
    for i=1,4 do
        BookSpawnSkeletonAt("undead_skeleton_warrior", row1[i], caster, duration)
    end
end

function BookSpawnSkeletonAt(unitName, point, owner, duration)
    local unit = CreateUnitByName(unitName,point,true,owner,owner,owner:GetTeamNumber())
    unit:SetControllableByPlayer(owner:GetPlayerOwnerID(), true)
    unit:SetForwardVector(owner:GetForwardVector())
    unit.no_corpse = true
    unit:AddNewModifier(owner, nil, "modifier_kill", {duration = duration})
    unit:AddNewModifier(owner, nil, "modifier_summoned", {})
    ParticleManager:CreateParticle("particles/neutral_fx/skeleton_spawn.vpcf", PATTACH_ABSORIGIN, unit)
end