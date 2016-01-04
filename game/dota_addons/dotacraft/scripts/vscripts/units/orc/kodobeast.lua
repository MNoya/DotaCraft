function DevourPhase( event )
	if event.caster:FindModifierByNameAndCaster('modifier_devour_devouring', event.caster) then
		local pID = event.caster:GetPlayerOwnerID()
		SendErrorMessage(pID, "Can't devour with full mouth!")
		event.caster:Stop()
	end
end

function DevourStart( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	ability.target = target -- The devoured unit
	local duration = math.ceil(target:GetHealth() / ability:GetSpecialValueFor('damage_per_second'))

	ability:ApplyDataDrivenModifier(caster, target, 'modifier_devour_debuff', {})
	ability:ApplyDataDrivenModifier(caster, caster, 'modifier_devour_devouring', {duration = duration})
	ability:ApplyDataDrivenModifier(caster, caster, 'modifier_devour_swallow', {})
	target:AddNoDraw()
end

function DevourThink( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	ApplyDamage({
		victim = target,
		attacker = caster,
		damage = ability:GetSpecialValueFor('damage_per_second'),
		damage_type = ability:GetAbilityDamageType(),
		ability = ability,
		damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY,
	})
end

function DevourDeath( event )
	local caster = event.caster
	local ability = event.ability
	local target = ability.target

	if IsValidEntity(target) then
		target:SetAbsOrigin(caster:GetAbsOrigin())
		target:RemoveModifierByName('modifier_devour_debuff')
		target:RemoveNoDraw()
		ability.target = nil
	end
end

function NotificationFix( event )
	local caster = event.caster
	local ability = event.ability
	local target = ability.target

	target:SetAbsOrigin(caster:GetAbsOrigin())
end