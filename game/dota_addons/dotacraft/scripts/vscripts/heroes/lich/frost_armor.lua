--[[
	Handles the AutoCast Logic
	Author: Noya

	Auto-Cast can interrupt current orders and forget the next queued command. Following queued commands are not forgotten
	Cannot occur while channeling a spell.
]]
function FrostArmorAutocast( event )
	local caster = event.caster
	local target = event.target -- victim of the attack
	local ability = event.ability

	if caster.state == AI_STATE_IDLE or caster.state == AI_STATE_SLEEPING then return end

	-- Name of the modifier to avoid casting the spell on targets that were already buffed
	local modifier = "modifier_frost_armor"

	-- Get if the ability is on autocast mode and cast the ability on the attacked target if it doesn't have the modifier
	if ability:GetAutoCastState() and ability:IsFullyCastable() and not caster:IsMoving() then
		if not IsChanneling(caster) and not target:HasModifier(modifier) then
			caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())
		end	
	end	
end

--[[
	Author: Noya
	Plays the lich_frost_armor particle and destroys it later
]]
function FrostArmorParticle( event )
	local target = event.target
	local location = target:GetAbsOrigin()
	local particleName = "particles/units/heroes/hero_lich/lich_frost_armor.vpcf"

	-- Particle. Need to wait one frame for the older particle to be destroyed
	Timers:CreateTimer(0.01, function()
		target.FrostArmorParticle = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, target)
		ParticleManager:SetParticleControl(target.FrostArmorParticle, 0, target:GetAbsOrigin())
		ParticleManager:SetParticleControl(target.FrostArmorParticle, 1, Vector(1,0,0))

		ParticleManager:SetParticleControlEnt(target.FrostArmorParticle, 2, target, PATTACH_ABSORIGIN_FOLLOW, "attach_origin", target:GetAbsOrigin(), true)
	end)
end

-- Destroys the particle when the modifier is destroyed
function EndFrostArmorParticle( event )
	local target = event.target
	ParticleManager:DestroyParticle(target.FrostArmorParticle,false)
end