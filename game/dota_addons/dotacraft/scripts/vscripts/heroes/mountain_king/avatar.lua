--[[
	Author: Noya
	Date: 13.1.2015.
	Resizes the target for a duration then resizes back to the normal scale
]]
function AvatarResize( event )
	-- Variables
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor( "duration" , ability:GetLevel() - 1  )
	local model_size = ability:GetLevelSpecialValueFor( "model_size" , ability:GetLevel() - 1  )

	local model_size_interval = 100 / ( model_size - 1 ) 

	--Scale Up in 100 intervals
	for i=1,100 do
		Timers:CreateTimer( i/75, 
    		function()
    			local modelScale = 1 + i/model_size_interval
				caster:SetModelScale( modelScale )
				print(modelScale)
			end)
	end

	--Scale Down 1 second after the duration ends
	for i=1,100 do
		Timers:CreateTimer( duration - 1 + (i/50),
	    	function()
	    		local modelScale = model_size - i/model_size_interval
				caster:SetModelScale( modelScale )
				print(modelScale)
			end)
	end
end