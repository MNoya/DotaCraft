function StarfallDamage(event)
    local ability = event.ability
    local caster = event.caster
    local wave_damage = ability:GetSpecialValueFor("wave_damage")
    local building_damage = wave_damage * ability:GetSpecialValueFor("building_dmg_pct") * 0.01
    local radius = ability:GetSpecialValueFor("radius")
    local targets = FindEnemiesInRadius( caster, radius, caster:GetAbsOrigin() )
    local abilityDamageType = ability:GetAbilityDamageType()

    for _,target in pairs(targets) do
        ParticleManager:CreateParticle("particles/custom/nightelf/potm/starfall.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    end 

    Timers:CreateTimer(0.4, function()
        for _,target in pairs(targets) do
            if IsValidEntity(target) and target:IsAlive() then
                if IsCustomBuilding(target) then
                    DamageBuilding(target, building_damage, ability, caster)
                else
                    ApplyDamage({victim = target, attacker = caster, damage = wave_damage, ability = ability, damage_type = abilityDamageType})
                end
                target:EmitSound("Ability.StarfallImpact")
            end
        end 
    end)
end