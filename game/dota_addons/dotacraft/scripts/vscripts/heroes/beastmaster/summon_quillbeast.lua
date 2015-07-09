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
	print("check")
	-- Get if the ability is on autocast mode and cast the ability if it doesn't have the modifier
	if ability:GetAutoCastState() then
		if not caster:HasModifier(modifier) then
			caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())
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
	local model_size = ability:GetLevelSpecialValueFor( "model_size" , ability:GetLevel() - 1  )

	-- Substract a bit from original model scale
	if caster:GetUnitName() == "npc_beastmaster_raging_quillbeast" then
		model_size = model_size - 0.15
	else
		model_size = model_size - 0.25
	end

	local model_size_interval = 400

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