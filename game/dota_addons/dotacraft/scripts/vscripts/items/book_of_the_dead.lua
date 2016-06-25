function BookSpawn(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetSpecialValueFor("duration")

    local fv = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
    local distance = event.distance

    local fp1 = origin + fv * UNIT_FORMATION_DISTANCE
    local pw1 = RotatePosition(origin, QAngle(0, 30, 0), fp1)
    local pw2 = RotatePosition(origin, QAngle(0, -30, 0), fp1)

    BookSpawnSkeletonAt("undead_skeleton_archer", pw1, caster, duration)
    BookSpawnSkeletonAt("undead_skeleton_archer", pw2, caster, duration)

    local pa1 = pw1 + fv * UNIT_FORMATION_DISTANCE
    local pa2 = pw2 + fv * UNIT_FORMATION_DISTANCE  
   
    BookSpawnSkeletonAt("undead_skeleton_warrior", pa1, caster, duration)
    BookSpawnSkeletonAt("undead_skeleton_warrior", pa2, caster, duration)
end

function BookSpawnSkeletonAt(unitName, point, owner, duration)
    local unit = CreateUnitByName(unitName,point,true,owner,owner,owner:GetTeamNumber())
    unit:SetControllableByPlayer(owner:GetPlayerOwnerID(), true)
    unit:SetForwardVector(owner:GetForwardVector())
    unit:AddNewModifier(owner, nil, "modifier_kill", {duration = duration})
    unit:AddNewModifier(owner, nil, "modifier_summoned", {})
    ParticleManager:CreateParticle("particles/neutral_fx/skeleton_spawn.vpcf", PATTACH_ABSORIGIN, unit)
end