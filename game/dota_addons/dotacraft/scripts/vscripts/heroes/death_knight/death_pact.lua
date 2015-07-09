--[[
	Author: Noya
	Date: 21.01.2015.
	Kills a target, gives Health to the caster according to the sacrificed target current Health
]]
function DeathPact( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local target_health = event.target:GetHealth()
	local rate = ability:GetLevelSpecialValueFor( "conversion_rate" , ability:GetLevel() - 1 ) * 0.01

	caster:Heal( target_health * rate, caster)
	target:Kill(ability, caster)
end

-- Denies casting on full health, with a message
function DeathPactPrecast( event )
	if event.caster:GetHealthPercent() == 100 then
		event.caster:Interrupt()
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Already on Full Health" } )
	end
end