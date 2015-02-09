--[[
	Author: Noya
	Date: 09.02.2015.

	Handles the AutoCast logic after starting an attack
]]
function FrenzyAutocast( event )
	local caster = event.caster
	local ability = event.ability

	-- Name of the modifier to avoid casting the spell if the caster is buffed
	local modifier = "modifier_frenzy"

	-- Get if the ability is on autocast mode and cast the ability if it doesn't have the modifier
	if ability:GetAutoCastState() then
		if not IsChanneling( caster ) then
			if not caster:HasModifier(modifier) then
				caster:CastAbilityNoTarget(caster, ability, caster:GetPlayerOwnerID())
			end
		end	
	end	
end

--[[
	Author: Noya
	Date: 13.1.2015.
	Resizes the target for a duration then resizes back to the normal scale
]]
function FrenzyResize( event )
	-- Variables
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor( "duration" , ability:GetLevel() - 1  )
	local model_size = ability:GetLevelSpecialValueFor( "modelscale" , ability:GetLevel() - 1  )

	local model_size_interval = 100 / ( model_size - 1 ) 

	--Scale Up in 100 intervals
	for i=1,100 do
		Timers:CreateTimer( i/75, 
    		function()
    			local modelScale = 1 + i/model_size_interval
				caster:SetModelScale( modelScale )
			end)
	end

	--Scale Down 1 second after the duration ends
	for i=1,100 do
		Timers:CreateTimer( duration - 1 + (i/50),
	    	function()
	    		local modelScale = model_size - i/model_size_interval
				caster:SetModelScale( modelScale )
			end)
	end
end