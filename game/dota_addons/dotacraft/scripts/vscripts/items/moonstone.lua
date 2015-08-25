function Moonstone( event )
	local ability = event.ability
	local night_duration = ability:GetSpecialValueFor("night_duration")
	local original_time_of_day = GameRules:GetTimeOfDay()
	print("Moonstone Start at ",GameRules:GetGameTime(),"Time of day: ",original_time_of_day)

	-- Force Night Time
	GameRules:SetTimeOfDay( 0.75 )

	-- Stop the old effect just in case
	if GameRules.ExtendedNightTime then
		Timers:RemoveTimer(GameRules.ExtendedNightTime)
	end

	-- Make a timer to end the extended night
	GameRules.ExtendedNightTime = Timers:CreateTimer(night_duration, function()
		GameRules:SetTimeOfDay(original_time_of_day)
		print("Moonstone End - Set Time Of Day back to the original: ",original_time_of_day)
	end)
end