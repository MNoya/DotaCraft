-- Burns mana and deals magic damage equal to the mana burned
function ManaBurn( event )
    local target = event.target
    local caster = event.caster
    local ability = event.ability
    local abilityDamageType = ability:GetAbilityDamageType()
    local mana_burn = ability:GetLevelSpecialValueFor("mana_burn", ability:GetLevel() - 1 )
    local damage_per_mana = ability:GetLevelSpecialValueFor("damage_per_mana", ability:GetLevel() - 1 )

    -- Set the new target mana
    mana_burn = math.min(mana_burn, target:GetMana())
    target:ReduceMana(mana_burn)

    -- Do the damage
    ApplyDamage({ victim = target, attacker = caster, damage = mana_burn*damage_per_mana, ability = ability, damage_type = abilityDamageType })
end