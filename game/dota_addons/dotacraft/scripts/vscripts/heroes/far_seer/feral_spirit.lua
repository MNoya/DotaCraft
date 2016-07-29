local wolfNames = {
    [1] = "orc_spirit_wolf",
    [2] = "orc_dire_wolf",
    [3] = "orc_shadow_wolf",
}
function SpawnWolves(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("wolf_duration", ability:GetLevel()-1)
    local position = caster:GetAbsOrigin() + caster:GetForwardVector() * 150

    -- Reset table
    local wolves = caster.wolves or {}
    for _,unit in pairs(wolves) do     
        if unit and IsValidEntity(unit) then
            unit:ForceKill(true) 
        end
    end
    caster.wolves = {}
    
    -- Gets 2 points facing a distance away from the caster origin and separated from each other at 30 degrees left and right
    local positions = {}
    positions[1] = RotatePosition(caster:GetAbsOrigin(), QAngle(0, 30, 0), position)
    positions[2] = RotatePosition(caster:GetAbsOrigin(), QAngle(0, -30, 0), position)

    -- Summon 2 wolves
    for i=1,2 do
        local wofl = caster:CreateSummon(wolfNames[ability:GetLevel()], positions[i], duration)
        ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, wolf)
    end
end