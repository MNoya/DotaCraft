--[[
	Author: Noya
	Date: 21.01.2015.
	Kills a target, gives Health to the caster according to the sacrificed target current Health
]]
function DeathCoil( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local damage = ability:GetLevelSpecialValueFor( "target_damage" , ability:GetLevel() - 1 )
	local heal = ability:GetLevelSpecialValueFor( "heal_amount" , ability:GetLevel() - 1 )
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL })
	else
		target:Heal( heal, caster)
	end
end

-- Denies self cast, with a message
function DeathCoilPrecast( event )
	if event.target == event.caster then
		event.caster:Interrupt()
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Ability Can't Target Self" } )
	end
end