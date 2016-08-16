function UnlockBurningOil(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetSpecialValueFor("duration")
    SetRangedProjectileName(caster, "particles/custom/orc/burning_oil.vpcf")
    
    caster.OnAttackGround = function (position)
        local burning_oil_dummy = CreateUnitByName("dummy_unit_vulnerable", position, false, caster, caster, caster:GetTeam())
        ability:ApplyDataDrivenModifier(caster, burning_oil_dummy, "modifier_burning_oil_thinker", {duration=duration})
        
        Timers:CreateTimer(duration, function()
            UTIL_Remove(burning_oil_dummy)
        end)
    end
end

function BurningOilDamage(event)
    local caster = event.caster
    local target = event.target
    local damage = event.Damage
    if IsCustomBuilding(target) then
        DamageBuilding(target, damage, ability, caster)
    else
        ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
    end
end