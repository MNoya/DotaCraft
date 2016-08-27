function Kaboom(event)
    local sapper = event.caster
    local origin = sapper:GetAbsOrigin()
    local ability = event.ability
    local hull = sapper:GetHullRadius()
    local full_dmg_radius = ability:GetLevelSpecialValueFor("full_dmg_radius",ability:GetLevel()-1) + hull
    local outer_dmg_radius = ability:GetLevelSpecialValueFor("outer_dmg_radius",ability:GetLevel()-1) + hull

    local full_dmg = ability:GetLevelSpecialValueFor("full_dmg",ability:GetLevel()-1)
    local outer_dmg = ability:GetLevelSpecialValueFor("outer_dmg",ability:GetLevel()-1)

    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local flags = DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES
    local targets = FindUnitsInRadius(sapper:GetTeamNumber(), origin, nil, outer_dmg_radius, DOTA_UNIT_TARGET_TEAM_BOTH, target_type, flags, 0, false)

    for _,target in pairs(targets) do
        if target ~= sapper then
            if target:GetRangeToUnit(sapper) <= full_dmg_radius then
                ApplyDamage({victim = target, attacker = sapper, damage = full_dmg, ability = ability, damage_type = DAMAGE_TYPE_MAGICAL})
            else
                ApplyDamage({victim = target, attacker = sapper, damage = outer_dmg, ability = ability, damage_type = DAMAGE_TYPE_MAGICAL})
            end
        end
    end

    local particleName = "particles/units/heroes/hero_techies/techies_suicide.vpcf"
    if ability:GetAbilityName():match("tinker") then
        particleName = "particles/units/heroes/hero_techies/techies_suicide_fire.vpcf"
    end

    local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle,0,origin)

    sapper:EmitSound("Hero_Techies.Suicide")
    sapper:ForceKill(true)
end

function KaboomCast(event)
    local sapper = event.caster
    local kaboom = event.ability
    sapper:Stop()
    sapper.current_order = DOTA_UNIT_ORDER_ATTACK_TARGET
    sapper:CastAbilityImmediately(kaboom,sapper:GetPlayerOwnerID())
end

-- Find targets if the ability is on autocast, otherwise keep in passive state
function KaboomThink(event)
    local sapper = event.caster
    local kaboom = event.ability

    if kaboom:GetAutoCastState() then
        local target = sapper:GetAggroTarget()
        if target then
            if not sapper:IsMoving() then
                sapper:CastAbilityOnTarget(target,kaboom,sapper:GetPlayerOwnerID())
            end
        else
            local enemies = FindEnemiesInRadius(sapper, sapper:GetAcquisitionRange())
            if #enemies > 0 then

                for _,enemy in pairs(enemies) do
                    if UnitCanAttackTarget(sapper, enemy) and ShouldAggroNeutral(sapper, enemy) then
                        sapper.current_order = DOTA_UNIT_ORDER_ATTACK_TARGET
                        sapper:MoveToTargetToAttack(enemy)
                        return
                    end
                end
            end
        end
    end
end