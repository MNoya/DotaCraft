function ShockwaveStart(event)
    local caster = event.caster
    local ability = event.ability
    ability.maxDamage = ability:GetLevelSpecialValueFor("max_damage",ability:GetLevel()-1)
    ability.damageDone = 0
end

function ShockwaveDamage(event)
    local caster = event.caster
    local ability = event.ability
    local target = event.target
    local damage = ability:GetAbilityDamage()

    if damage + ability.damageDone > ability.maxDamage then
        damage = ability.maxDamage - ability.damageDone
    end

    if damage > 0 then
        if IsCustomBuilding(target) then
            DamageBuilding(target, damage, ability, caster)
        else
            ApplyDamage({ victim = target, attacker = caster, damage = damage, ability = ability, damage_type = ability:GetAbilityDamageType() })
        end
        ability.damageDone = ability.damageDone + damage
    end
end