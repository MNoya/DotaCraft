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

	local scaling_factor = ability:GetSpecialValueFor('scaling_factor')
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
	local scaling_factor = ability:GetSpecialValueFor('scaling_factor')
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
	local duration = ability:GetSpecialValueFor("duration")
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
	local radius = ability:GetSpecialValueFor("radius")
	local dps = ability:GetSpecialValueFor("damage_per_second")
	local factor = ability:GetSpecialValueFor("think_interval")
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


function PurgeStart( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local bRemovePositiveBuffs = false
	local bRemoveDebuffs = false
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		bRemovePositiveBuffs = true
	else
		bRemoveDebuffs = true
	end
	target:Purge(bRemovePositiveBuffs, bRemoveDebuffs, false, false, false)
	target:EmitSound('n_creep_SatyrTrickster.Cast')
	ParticleManager:CreateParticle('particles/generic_gameplay/generic_purge.vpcf', PATTACH_ABSORIGIN_FOLLOW, target)
	if bRemovePositiveBuffs then
		if target:IsSummoned() or target:IsDominated() then
			ApplyDamage({
				victim = target,
				attacker = caster,
				damage = ability:GetSpecialValueFor('summoned_unit_damage'),
				damage_type = ability:GetAbilityDamageType(),
				ability = ability
			})
		end
		local duration = 0
		if target:IsHero() or target:IsConsideredHero() then
			duration = ability:GetSpecialValueFor('duration_hero')
		else
			duration = ability:GetSpecialValueFor('duration')
		end
		ability:ApplyDataDrivenModifier(caster, target, 'modifier_purge', {duration = duration}) 
	end
end

function ApplyPurge( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local duration = 0 
	local modifier = 'modifier_purge_slow'
	ability:ApplyDataDrivenModifier(caster, target, modifier, nil) 
	local stacks = ability:GetSpecialValueFor('stack_multi')
	target:SetModifierStackCount(modifier, ability, stacks)
end

function PurgeThink( event )
	local target = event.target
	local ability = event.ability
	local modifier = 'modifier_purge_slow'
	local new_stack = target:GetModifierStackCount(modifier, nil) - 1
	if new_stack > 0 then
		target:SetModifierStackCount(modifier, ability, new_stack)
	end
end