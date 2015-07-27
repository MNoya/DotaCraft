--[[ ============================================================================================================
	Author: wFX, based on Noya/Rook code.
================================================================================================================= ]]

function Bloodlust(event)	
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	if target.bloodlust_timer then
		Timers:RemoveTimer(target.bloodlust_timer)
	end

	local scaling_factor = ability:GetLevelSpecialValueFor('scaling_factor', 0)
	local final_model_scale = GameRules.UnitKV[target:GetUnitName()]["ModelScale"] + scaling_factor
	local model_size_interval = scaling_factor/25
	local interval = 0.03
	target.bloodlust_timer = Timers:CreateTimer(interval, function() 
			local current_scale = target:GetModelScale()
			if current_scale <= final_model_scale then
				local modelScale = current_scale + model_size_interval
				target:SetModelScale( modelScale )
				return 0.03
			else
				return
			end
		end)

	ability:ApplyDataDrivenModifier(caster, target, 'modifier_orc_bloodlust', nil) 

	caster:EmitSound('Hero_OgreMagi.Bloodlust.Cast')
	target:EmitSound('Hero_OgreMagi.Bloodlust.Target')
end

function BloodlustDelete(event)	
	local target = event.target
	local ability = event.ability
	local scaling_factor = ability:GetLevelSpecialValueFor('scaling_factor', 0)
	local final_model_scale = GameRules.UnitKV[target:GetUnitName()]["ModelScale"]
	local model_size_interval = scaling_factor/50
	
	if target.bloodlust_timer then
		Timers:RemoveTimer(target.bloodlust_timer)
	end
	local interval = 0.03
	target.bloodlust_timer = Timers:CreateTimer(interval, function() 
			local current_scale = target:GetModelScale()
			if current_scale >= final_model_scale then
				local modelScale = current_scale - model_size_interval
				target:SetModelScale( modelScale )
				return 0.03
			else
				return
			end
		end)

end


function LightningShieldOnSpellStart(event)
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	local duration = ability:GetLevelSpecialValueFor("duration", 0)
	target:EmitSound("Hero_Zuus.StaticField")

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start_bolt_parent.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
	Timers:CreateTimer(0.1, function()
		ability:ApplyDataDrivenModifier(caster, target, 'modifier_orc_lightning_shield', {})
	end)
end

function ModifierLightningShieldOnIntervalThink(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local radius = ability:GetLevelSpecialValueFor("radius", 0)
	local dps = ability:GetLevelSpecialValueFor("damage_per_second", 0)
	local factor = ability:GetLevelSpecialValueFor("think_interval", 0)
	local damage = dps*factor

	local nearby_units = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES, FIND_ANY_ORDER, false)
	
	for i, nUnit in pairs(nearby_units) do
		if target ~= nUnit then  --The carrier of Lightning Shield cannot damage itself.
			ApplyDamage({victim = nUnit, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
			ParticleManager:CreateParticle("particles/custom/orc/lightning_shield_hit.vpcf", PATTACH_ABSORIGIN, nUnit)
		end
	end
end