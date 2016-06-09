function DoDamage(event)
    local ability = event.ability
    local caster = event.caster
    local team = caster:GetTeamNumber()
    local origin = caster:GetAbsOrigin()
    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local radius = ability:GetCastRange()
    local damage = ability:GetAbilityDamage()
    local max_damage = ability:GetLevelSpecialValueFor("max_damage",ability:GetLevel()-1)
    local enemies = FindUnitsInRadius(team, origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)

    ability:ApplyDamageUnitsMax(damage, enemies, max_damage)
end