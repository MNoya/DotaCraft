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
        caster.wolves[i] = caster:CreateSummon(wolfNames[ability:GetLevel()], positions[i], duration)
        ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster.wolves[i])
    end
end

function SummonByName(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel()-1)
    local unitName = event.UnitName
    local position = caster:GetAbsOrigin() + caster:GetForwardVector() * 150

    -- Reset table
    local summoned = caster.summoned or {}
    for _,unit in pairs(summoned) do     
        if unit and IsValidEntity(unit) then
            unit:ForceKill(true) 
        end
    end
    caster.summoned = {}
    caster.allies = caster.allies or {}
    
    -- Gets 2 points facing a distance away from the caster origin and separated from each other at 30 degrees left and right
    local positions = {}
    positions[1] = RotatePosition(caster:GetAbsOrigin(), QAngle(0, 30, 0), position)
    positions[2] = RotatePosition(caster:GetAbsOrigin(), QAngle(0, -30, 0), position)

    -- Summon 2
    for i=1,2 do
        caster.summoned[i] = caster:CreateSummon(unitName, positions[i], duration)
        ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster.summoned[i])
    end

    for i=1,2 do
        caster.summoned[i].allies = {}
        for k,v in pairs(caster.allies) do
            if IsValidAlive(v) then
                if v.allies then
                    table.insert(v.allies, caster.summoned[i])
                end
                table.insert(caster.summoned[i].allies, v)
            end
        end
    end
end