-- Allows attacking air units attack restriction
function UnlockAirAttack(event)
    local caster = event.caster
    caster:SetAttacksEnabled("building,air")
end

-- Launches projectiles to every nearby enemy flying unit
function Barrage( event )
    local caster = event.caster
    local ability = event.ability
    local target = event.target
    local radius = ability:GetCastRange()
    if IsCustomBuilding(target) then return end -- Don't barrage when attacking buildings
    local targets = FindEnemiesInRadius(caster, radius)

    for _,enemy in pairs(targets) do
        if enemy:HasFlyMovementCapability() and enemy ~= target then
            local projTable = {
                EffectName = "particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics/gyro_base_attack.vpcf",
                Ability = ability,
                Target = enemy,
                Source = caster,
                bDodgeable = true,
                bProvidesVision = false,
                vSpawnOrigin = caster:GetAbsOrigin(),
                iMoveSpeed = 900,
                iVisionRadius = 0,
                iVisionTeamNumber = caster:GetTeamNumber(),
                iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
            }
            ProjectileManager:CreateTrackingProjectile( projTable )
        end
    end
end