--[[
	Author:
	Date: Day.Month.2015.
	(Description)
]]
function AbilityName( event )
	-- Variables
	local caster = event.caster
	local ability = event.ability
	local value = = ability:GetLevelSpecialValueFor( "value" , ability:GetLevel() - 1  )

	-- Try to comment each block of logical actions
	-- If the ability handle is not nil, print a message
	if ability then
		print("RunScript")
	end
end