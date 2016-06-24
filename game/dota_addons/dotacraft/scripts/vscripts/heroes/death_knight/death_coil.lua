--[[
	Author: Noya
	Date: 9 September 2015
	Can only be cast on living allied units (Heal) or enemy Undead units (Damage). 
	Disallows self targeting and casting on allied units with full health
]]
death_knight_death_coil = class({})

function death_knight_death_coil:OnSpellStart()
	local ability = self
	local caster = ability:GetCaster()
	local target = ability:GetCursorTarget()

	local projectile_speed = ability:GetSpecialValueFor("projectile_speed")
	local projectile_name = "particles/custom/vengeful_magic_missle.vpcf"

	local projectile = {
		Target = target,
		Source = caster,
		Ability = ability,
		EffectName = projectile_name,
		bDodgable = true,
		bProvidesVision = false,
		iMoveSpeed = projectile_speed,
		iVisionTeamNumber = caster:GetTeamNumber(),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	}

	ProjectileManager:CreateTrackingProjectile(projectile)

	caster:EmitSound("Hero_Abaddon.DeathCoil.Cast")
end

function death_knight_death_coil:OnProjectileHit( target, location )
	local ability = self
	local caster = ability:GetCaster()
	
	local damage = ability:GetLevelSpecialValueFor( "target_damage" , ability:GetLevel() - 1 )
	local heal = ability:GetLevelSpecialValueFor( "heal_amount" , ability:GetLevel() - 1 )
	
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		ApplyDamage({ victim = target, attacker = caster, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL })
	else
		local healDone = math.min(heal,target:GetHealthDeficit())
		if healDone > 0 then
			PopupHealing(target, healDone)
			target:Heal( heal, caster)
		end
	end

	target:EmitSound("Hero_Abaddon.DeathCoil.Target")
end

--------------------------------------------------------------------------------

function death_knight_death_coil:CastFilterResultTarget( target )
	local ability = self
	local caster = self:GetCaster()

	-- Check Undead for allies or Living for enemies
	local casterTeam = caster:GetTeamNumber()
 	local targetTeam = target:GetTeamNumber()
 	local allied = casterTeam == targetTeam
 	local bUndead = string.match(target:GetUnitName(),"undead") or string.match(target:GetUnitLabel(),"undead")

	-- Check self-target
	if caster == target then 
		return UF_FAIL_CUSTOM
	end

	-- Check full health ally
	if allied and target:GetHealthPercent() == 100 then
		return UF_FAIL_CUSTOM
	end

 	-- Prevent healing living allies or damaging undead enemies
 	if (allied and not bUndead) or (not allied and bUndead) then
 		return UF_FAIL_CUSTOM
 	end

	return UF_SUCCESS
end
  
function death_knight_death_coil:GetCustomCastErrorTarget( target )
	local ability = self
	local caster = self:GetCaster()

	local casterTeam = caster:GetTeamNumber()
 	local targetTeam = target:GetTeamNumber()
 	local allied = casterTeam == targetTeam
 	local bUndead = string.match(target:GetUnitName(),"undead")

	if caster == target then
		return "#error_cant_target_self"
	end

	if allied and target:GetHealthPercent() == 100 then
		return "#error_full_health"
	end

 	if (allied and not bUndead) or (not allied and bUndead) then
 		return "#error_must_target_undead_allies"
 	end
 
	return ""
end