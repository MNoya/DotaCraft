local bearNames = {
    [1] = "neutral_beastmaster_bear",
    [2] = "neutral_beastmaster_raging_bear",
    [3] = "neutral_beastmaster_spirit_bear",
}
function SpawnBear(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel()-1)
    local fv = caster:GetForwardVector()
    local position = caster:GetAbsOrigin() + fv * 200
    local playerID = caster:GetPlayerOwnerID()
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    local bear = caster:CreateSummon(bearNames[ability:GetLevel()], position, duration)
    ability:ApplyDataDrivenModifier(caster, bear, "modifier_beastmaster_bear", {})
end

--------------------------------------------------------------------------------

--[[Author: Amused/D3luxe
    Used by: Noya
    Blinks the target to the target point, if the point is beyond max blink range then blink the maximum range]]
function Blink(keys)
    local point = keys.target_points[1]
    local caster = keys.caster
    local casterPos = caster:GetAbsOrigin()
    local difference = point - casterPos
    local ability = keys.ability
    local range = ability:GetLevelSpecialValueFor("blink_range", (ability:GetLevel() - 1))

    if difference:Length2D() > range then
        point = casterPos + (point - casterPos):Normalized() * range
    end

    FindClearSpaceForUnit(caster, point, false)
    Timers:CreateTimer(0.15, function()
        ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_bear_blink_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    end)
end