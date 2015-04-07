-- Launches projectiles to every nearby flying unit
function Barrage( event )
	local caster = event.caster
	local ability = event.ability
	local targets = event.target_entities

	for _,enemy in pairs(targets) do
		if enemy:HasFlyMovementCapability() then
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
			print("Barrage Launched to "..enemy:GetUnitName().." number ".. enemy:GetEntityIndex())
		end
	end

end