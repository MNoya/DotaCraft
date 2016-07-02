function OnSpellStart( event )
	local caster = event.caster
	local ability = event.ability
	local target = event.target

	caster:EmitSound('Hero_NagaSiren.Ensnare.Cast')
	if target.ensnare_timer then
		Timers:RemoveTimer(target.ensnare_timer)
	end

	local duration = ability:GetSpecialValueFor('duration')
	target.base_z = target:GetAbsOrigin().z
	local interval = ability:GetSpecialValueFor('lower_duration') / 10
	local height_reduction = ability:GetSpecialValueFor('lower_height') 
	local new_height = target.base_z - ability:GetSpecialValueFor('lower_height') 
	local factor = height_reduction / 10

	if target:HasFlyMovementCapability() then
		target:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
		target.WasFlying = true
	end

	target:EmitSound('Hero_NagaSiren.Ensnare.Target')
	ability:ApplyDataDrivenModifier(caster, target, 'modifier_ensnare', {duration = duration}) 
end

function OnModifierDestroy( event )
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	local ability = event.ability

	local duration = ability:GetSpecialValueFor('duration')
	local interval = ability:GetSpecialValueFor('lower_duration') / 5
	local height_increase = ability:GetSpecialValueFor('lower_height') 
	local new_height = target.base_z + ability:GetSpecialValueFor('lower_height') 
	local factor = height_increase / 5

	if target.WasFlying then
		target.WasFlying = nil
		target:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
	end
end