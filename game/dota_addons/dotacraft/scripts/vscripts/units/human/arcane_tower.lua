function DamageToSummons( event )
    local target = event.target
    local ability = event.ability

    if target:IsSummoned() then
        local damage_to_summons = ability:GetSpecialValueFor("damage_to_summons")
        ApplyDamage({victim = target, attacker = caster, damage = damage_to_summons, damage_type = DAMAGE_TYPE_PURE})
        PopupSpellDamage(target, damage_to_summons)
    end
end