-- Denies cast on creeps higher than level 5, with a message
function PolymorphLevelCheck( event )
	local target = event.target
	local hero = event.caster:GetPlayerOwner():GetAssignedHero()
	local pID = hero:GetPlayerID()
	
	if target:GetLevel() > 5 then
		event.caster:Interrupt()
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Can't target creeps over level 5" } )
	end
end