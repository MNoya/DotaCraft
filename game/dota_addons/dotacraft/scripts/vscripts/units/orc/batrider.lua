function UnstableSpellStart( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_unstable_concoction", {})
    caster:EmitSound("Hero_Huskar.Life_Break") 
    Timers:CreateTimer(function()
        caster:MoveToPosition(target:GetAbsOrigin())
        local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 20, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
        for _,enemy in pairs(enemies) do
            if enemy == target then
                caster.target = target
                caster:ForceKill(true)
                return
            end
        end
        return 0.03
    end)
end

function UnstableDeath( event )
    local caster = event.caster
    local target = caster.target
    local ability = event.ability
    local radius = ability:GetSpecialValueFor("partial_damage_radius")
    local damage = ability:GetSpecialValueFor("full_damage_amount")
    local partial_damage = ability:GetSpecialValueFor("partial_damage_amount")

    ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = ability:GetAbilityDamageType(), ability = ability})
    
    local enemies = FindEnemiesInRadius(caster, radius, target:GetAbsOrigin())
    for _,enemy in pairs(enemies) do
        if enemy:IsFlyingUnit() then
            ApplyDamage({victim = target, attacker = caster, damage = partial_damage, damage_type = ability:GetAbilityDamageType(), ability = ability})
        end
    end
    caster:EmitSound("Hero_Techies.Suicide")
    ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_suicide.vpcf", PATTACH_ABSORIGIN, target)
end

---------------------------------------------------------------------

function LiquidOrb( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability

    if IsCustomBuilding(target) then
        ability:ApplyDataDrivenModifier(caster, target, "modifier_liquid_fire_debuff", nil) 
        target:EmitSound("Hero_Jakiro.LiquidFire")
    end
end

function LiquidOrbThink( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local damage = ability:GetSpecialValueFor("damage_per_second")/2
    
    DamageBuilding(target, damage, ability, caster)
end

function LiquidOrbEffect(event)
    local target = event.target
    local caster = event.caster
    local modifier = target:FindModifierByNameAndCaster("modifier_liquid_fire_debuff",caster)
    local size = BuildingHelper:GetBlockPathingSize(target:GetUnitName())
    local particle = ParticleManager:CreateParticle("particles/custom/orc/liquid_fire_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(particle,1,Vector(size,0,0))
    ParticleManager:SetParticleControl(particle,2,Vector(size*10,0,0))
    ParticleManager:SetParticleControl(particle,3,target:GetAbsOrigin())
    modifier:AddParticle(particle, false, false, 1, false, false)
end