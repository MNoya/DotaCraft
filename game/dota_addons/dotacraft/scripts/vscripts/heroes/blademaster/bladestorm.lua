--[[
	Author: Noya
	Date: 28.01.2015
	Stops the looping sound event
]]
function BladeFuryStop( event )
	local caster = event.caster
	
	caster:StopSound("Hero_Juggernaut.BladeFuryStart")
end