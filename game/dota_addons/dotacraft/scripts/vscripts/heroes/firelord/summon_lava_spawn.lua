function LavaSpawn(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("lava_spawn_duration", ability:GetLevel()-1)
    local position = caster:GetAbsOrigin() + caster:GetForwardVector() * 250
    local spawnName = "neutral_lava_spawn"..ability:GetLevel()

    local lava_spawn = caster:CreateSummon(spawnName, position, duration)
    ability:ApplyDataDrivenModifier(caster, lava_spawn, "modifier_lava_spawn", {})
    ability:ApplyDataDrivenModifier(caster, lava_spawn, "modifier_lava_spawn_replicate", {})
    lava_spawn.attack_counter = 0
    lava_spawn.creation_time = GameRules:GetGameTime()
end

-- Counts hits made, create a new unit, with the same kill time and hp remaining than the original
function LavaSpawnAttackCounter( event )
    local caster = event.caster
    local attacker = event.attacker
    local ability = event.ability
    local attacks_to_split = ability:GetLevelSpecialValueFor("attacks_to_split", ability:GetLevel()-1)
    local lava_spawn_duration = ability:GetLevelSpecialValueFor("lava_spawn_duration", ability:GetLevel()-1)

    -- Increase counter
    attacker.attack_counter = attacker.attack_counter + 1

    -- Copy the unit, applying all the necessary modifiers
    if attacker.attack_counter == attacks_to_split then
        local duration = lava_spawn_duration - (GameRules:GetGameTime() - attacker.creation_time)
        local lava_spawn = caster:CreateSummon(attacker:GetUnitName(), attacker:GetAbsOrigin(), duration)
        ability:ApplyDataDrivenModifier(caster, lava_spawn, "modifier_lava_spawn", {})
        lava_spawn:SetHealth(attacker:GetHealth())
    end
end