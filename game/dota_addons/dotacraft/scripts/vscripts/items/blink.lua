function Blink(event)
    local point = event.target_points[1]
    local caster = event.caster
    local casterPos = caster:GetAbsOrigin()
    local pid = caster:GetPlayerID()
    local difference = point - casterPos
    local ability = event.ability
    local range = ability:GetLevelSpecialValueFor("blink_range", (ability:GetLevel() - 1))

    ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, caster)
    event.caster:EmitSound("DOTA_Item.BlinkDagger.Activate")

    if difference:Length2D() > range then
        point = casterPos + (point - casterPos):Normalized() * range
    end

    FindClearSpaceForUnit(caster, point, false) 

    ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, caster)
end