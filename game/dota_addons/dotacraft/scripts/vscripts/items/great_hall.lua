function ChangeGreatHall( event )
	local ability = event.ability
	local item_name = ability:GetAbilityName()
	local unit = event.caster
	if unit:IsHero() then
		local playerID = unit:GetPlayerID()
		local race = Players:GetRace(playerID)
		local new_name = "item_build_tiny_great_hall_"..race
		if new_name ~= item_name then
			print("Changing Item "..item_name.." to "..new_name)
			ability:RemoveSelf()
			Timers:CreateTimer(function() 
				unit:AddItem(CreateItem(new_name, unit, unit))
			end)
		end
	end		
end