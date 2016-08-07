function Impale(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    if target:HasFlyMovementCapability() or target:IsMechanical() or target:IsWard() then return end
    local air_time = ability:GetSpecialValueFor("air_time")
    local duration = ability:GetLevelSpecialValueFor("hero_duration",ability:GetLevel()-1)
    if not target:IsHero() then
        duration = ability:GetLevelSpecialValueFor("creep_duration",ability:GetLevel()-1)
    end

    local knockbackModifierTable =
    {
        should_stun = 0,
        knockback_duration = air_time,
        duration = air_time,
        knockback_distance = 0,
        knockback_height = 200,
        center_x = caster:GetAbsOrigin().x,
        center_y = caster:GetAbsOrigin().y,
        center_z = caster:GetAbsOrigin().z,
    }

    target:RemoveModifierByName("modifier_knockback")
    target:EmitSound("Hero_NyxAssassin.Impale.Target")
    ability:ApplyDataDrivenModifier(caster,target,"modifier_impale",{duration=duration})
    target:AddNewModifier(caster, ability, "modifier_knockback", knockbackModifierTable)

    Timers:CreateTimer(air_time, function()
        if target:IsAlive() then
            target:EmitSound("Hero_NyxAssassin.Impale.TargetLand")
            ApplyDamage({victim = target, attacker = caster, damage = ability:GetAbilityDamage(), ability = ability, damage_type = DAMAGE_TYPE_MAGICAL})
        end
    end)
end