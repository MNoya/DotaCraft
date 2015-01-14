
function death_coil_precast( event )
	if event.target == event.caster then
		event.caster:Stop() 
	end
end

function death_coil_cast( event )
	print(event.caster:GetMana())
end