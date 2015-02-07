--[[
	Author: Noya
	Date: 25.01.2015.
	Stops Doom looping sound
]]
function DoomStopSound( event )
	-- Variables
	local unit = event.unit
	
	StopSoundEvent("Hero_DoomBringer.Doom", unit)
end

-- Denies cast on creeps higher than level 5, with a message
function DoomLevelCheck( event )
	local target = event.target
	local pID = event.caster:GetPlayerID()
	
	if target:GetLevel() > 5 then
		event.caster:Interrupt()
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Can't target creeps over level 5" } )
	end
end