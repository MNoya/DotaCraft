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