--[[
	Author: Noya
	Date: 28.01.2015
	Stops the looping sound event
]]
function MaledictStop( event )
	local caster = event.caster
	
	caster:StopSound("Hero_WitchDoctor.Maledict_Loop")
end