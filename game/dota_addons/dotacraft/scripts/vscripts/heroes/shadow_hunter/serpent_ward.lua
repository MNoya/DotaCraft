function SpawnSerpentWard(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel()-1)
    local position = event.target_points[1]
    local wardName = "orc_serpent_ward_"..ability:GetLevel()

    caster:CreateSummon(wardName, position, duration)
end
