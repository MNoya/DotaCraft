--[[
	Author: Noya, adapted from SpellLibrary ursa_fury_swipes
	Date: 05.02.2015.
	Increase stack after each hit
]]
function IncinerateAttack( event )
	-- Variables
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local modifierName = "modifier_incinerate_stack"
	local damageType = ability:GetAbilityDamageType()

	local duration = ability:GetLevelSpecialValueFor( "bonus_reset_time", ability:GetLevel() - 1 )
	local damage_per_stack = ability:GetLevelSpecialValueFor( "damage_per_stack", ability:GetLevel() - 1 )
	
	-- If the unit has the stack, initialize it, else just increase
	if target:HasModifier( modifierName ) then
		local current_stack = target:GetModifierStackCount( modifierName, ability )
		
		-- Deal damage
		local damage_table = {
			victim = target,
			attacker = caster,
			damage = damage_per_stack * current_stack,
			damage_type = damageType,
			ability = ability, 
		}
		ApplyDamage( damage_table )
		
		ability:ApplyDataDrivenModifier( caster, target, modifierName, { Duration = duration } )
		target:SetModifierStackCount( modifierName, ability, current_stack + 1 )
	else
		ability:ApplyDataDrivenModifier( caster, target, modifierName, { Duration = duration } )
		target:SetModifierStackCount( modifierName, ability, 1 )
	end

end