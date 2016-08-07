function StormHammer( event )
    local caster = event.caster
    local target = event.target
    local targets = event.target_entities
    local ability = event.ability

    local next_target
    for _,v in pairs(targets) do
        if v ~= target and not v:HasFlyMovementCapability() and not IsCustomBuilding(v) and not v:IsWard() then
            next_target = v
            break
        end
    end
    if next_target then
        local projTable = {
            EffectName = "particles/custom/human/gryphon_rider_attack.vpcf",
            Ability = ability,
            Target = next_target,
            Source = target,
            bDodgeable = true,
            bProvidesVision = false,
            vSpawnOrigin = target:GetAbsOrigin(),
            iMoveSpeed = 900,
            iVisionRadius = 0,
            iVisionTeamNumber = caster:GetTeamNumber(),
            iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
        }
        ProjectileManager:CreateTrackingProjectile( projTable )
    end
end

function StormHammerDamage( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability

    ApplyDamage({ victim = target, attacker = caster, damage = caster:GetAverageTrueAttackDamage(), ability = ability, damage_type = ability:GetAbilityDamageType() })
end

function Mount( event )
    local caster = event.caster
    local ability = event.ability

    local attach = caster:ScriptLookupAttachment("attach_hitloc")
    local origin = caster:GetAttachmentOrigin(attach)
    local fv = caster:GetForwardVector()

    local rider = CreateUnitByName("human_gryphon_mounted_dummy", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber()) 
    ability:ApplyDataDrivenModifier(caster, rider, "modifier_disable_rider", {})

    rider:SetAbsOrigin(Vector(origin.x, origin.y, origin.z-30))
    rider:SetAngles(0,90,0)
    rider:SetParent(caster, "attach_hitloc")

    caster.rider = rider
end

function FakeAttack( event )
    local caster = event.caster

    caster.rider:StartGesture(ACT_DOTA_ATTACK)
end