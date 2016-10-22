-- Launch a meteor and spawn an infernal after a delay
function SpawnInferno(event)
    local caster = event.caster
    local ability = event.ability
    
    caster:EmitSound("Hero_Warlock.RainOfChaos_buildup")

    --Create a particle effect consisting of the meteor falling from the sky and landing at the target point.
    local caster_point = caster:GetAbsOrigin()
    local target_point = event.target_points[1]
    local caster_point_temp = Vector(caster_point.x, caster_point.y, 0)
    local target_point_temp = Vector(target_point.x, target_point.y, 0)
    local point_difference_normalized = (target_point_temp - caster_point_temp):Normalized()
    local travel_speed = 300
    local delay = 1
    local velocity_per_second = point_difference_normalized * 300
    local meteor_fly_original_point = (target_point - (velocity_per_second * 1)) + Vector (0, 0, 1500) --Start the meteor in the air in a place where it'll be moving the same speed when flying and when rolling.
    local chaos_meteor_fly_particle_effect = ParticleManager:CreateParticle("particles/custom/inferno_meteor.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(chaos_meteor_fly_particle_effect, 0, meteor_fly_original_point)
    ParticleManager:SetParticleControl(chaos_meteor_fly_particle_effect, 1, target_point)
    ParticleManager:SetParticleControl(chaos_meteor_fly_particle_effect, 2, Vector(delay+0.3, 0, 0))

    local duration = ability:GetSpecialValueFor("infernal_duration")
    local radius = ability:GetSpecialValueFor("radius")
    local stun_hero_duration = ability:GetSpecialValueFor("stun_hero_duration")
    local stun_creep_duration = ability:GetSpecialValueFor("stun_creep_duration")
    local damage = ability:GetAbilityDamage()

    Timers:CreateTimer(delay, function()
        local infernal = caster:CreateSummon("undead_inferno", target_point, duration)
        infernal:SetRenderColor(128, 255, 0)
        local impact = ParticleManager:CreateParticle("particles/custom/warlock_rain_of_chaos_start.vpcf",PATTACH_CUSTOMORIGIN,caster)
        ParticleManager:SetParticleControl(impact,0,target_point)

        GridNav:DestroyTreesAroundPoint(target_point, radius, true)

        caster:EmitSound("Hero_Warlock.RainOfChaos")

        local targets = FindUnitsInRadius(caster:GetTeamNumber(), target_point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
        for _,target in pairs(targets) do
            if not IsCustomBuilding(target) and not target:IsMechanical() and not target:IsWard() then
                local stun_duration = target:IsHero() and stun_hero_duration or stun_creep_duration
                ability:ApplyDataDrivenModifier(caster,target,"modifier_inferno_stun",{duration = stun_duration})
                ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
            end
        end
        if ability:IsItem() then
            UTIL_Remove(ability)
        end
    end)
end