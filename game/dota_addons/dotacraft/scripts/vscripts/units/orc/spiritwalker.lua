function EtherStart( event )
	local caster = event.caster
	local ability = event.ability
	if caster:FindModifierByNameAndCaster('modifier_etheral_form', caster) then
		caster:RemoveModifierByNameAndCaster('modifier_etheral_form', caster)
		local cooldown = ability:GetSpecialValueFor('cooldown')
		ability:StartCooldown(cooldown)
	else
		caster:EmitSound('Hero_Pugna.Decrepify')
		local delay = ability:GetSpecialValueFor('delay')
		Timers:CreateTimer(delay, function ()
			ability:ApplyDataDrivenModifier(caster, caster, 'modifier_etheral_form', {})
		end
		)
	end
end

