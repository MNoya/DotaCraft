--[[
	Author: Noya
	Date: 13.1.2015.
	Disallows self targeting. If cast on an ally it will heal, if cast on an enemy it will do damage.
	Doesn't have the Undead restriction for now
]]
function HolyLight( event )
	-- Variables
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local damage = ability:GetLevelSpecialValueFor( "target_damage" , ability:GetLevel() - 1  )
	local heal = ability:GetLevelSpecialValueFor( "heal_amount" , ability:GetLevel() - 1 )
	local particle_radius = ability:GetLevelSpecialValueFor( "particle_radius" , ability:GetLevel() - 1 )
	local particle_name = "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf"

	-- Check self-target
	if caster ~= target then 
		-- Play the ability sound
		target:EmitSound("Hero_Omniknight.Purification")

		-- If the target and caster are on a different team, do Damage. Heal otherwise
		if target:GetTeamNumber() ~= caster:GetTeamNumber() then
			ApplyDamage({ victim = target, attacker = caster, damage = damage,	damage_type = DAMAGE_TYPE_MAGICAL })
		else
			target:Heal( heal, caster)
		end

		-- Particle 
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 1, Vector(particle_radius,0,0))

	else
		--The ability was self targeted, refund mana and cooldown
		ability:RefundManaCost()
		ability:EndCooldown()

		-- Play Error Sound
		EmitSoundOnClient("General.CastFail_InvalidTarget_Hero", caster:GetPlayerOwner())

		SendErrorMessage(pID, "#error_cant_target_self")
	end
end