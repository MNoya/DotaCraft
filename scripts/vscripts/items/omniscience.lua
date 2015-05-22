-- Reveals the entire map using vision dummies.
function RevealMap( event )
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)
	local dummy_table = {}
	
	for i=-4,4 do
		for j = -4,4 do
			--print("Creating Vision Node at ",i*2000,j*2000)
			local dummy = CreateUnitByName("dummy_vision", Vector(i*2000,j*2000,128), false, caster, caster, caster:GetTeamNumber())
			table.insert(dummy_table, dummy)
		end
	end

	Timers:CreateTimer(duration, function()
		for _,dummy in pairs(dummy_table) do
			dummy:RemoveSelf()
		end
	end)
end