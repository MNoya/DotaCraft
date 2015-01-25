--[[
	Author: Noya
	Date: 25.01.2015.
	Spawns a beetle near a corpse, consuming it in the process.
]]
function CarrionBeetleSpawn( event )
	local caster = event.caster
	local player = event.caster:GetPlayerID()
	local ability = event.ability
	local level = ability:GetLevel()
	local beetle_limit = ability:GetLevelSpecialValueFor( "beetle_limit", ability:GetLevel() - 1 )
	local unit_name = "npc_carrion_beetle_"..level

	-- Initialize the table of beetles
	if caster.beetles == nil then
		caster.beetles = {}
	end

	-- Find all corpse entities in the radius
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), ability:GetCastRange())

	-- Go through every unit, stop at the first corpse found
	for _, unit in pairs(targets) do
		if unit.corpse_expiration ~= nil then

			-- If the caster has already hit the limit of beetles, kill the oldest, then continue
			if #caster.beetles >= beetle_limit then
				print("Attempting to kill one beetle from "..#caster.beetles)
				for k,v in pairs(caster.beetles) do
					if k==1 and v and IsValidEntity(v) and v:IsAlive() then v:ForceKill(false) end
				end
			end

			-- Create the beetle
			local beetle = CreateUnitByName(unit_name, unit:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
			beetle:SetControllableByPlayer(player, true)
			ability:ApplyDataDrivenModifier(caster, beetle, "modifier_carrion_beetle", nil)
			beetle.no_corpse = true
			table.insert(caster.beetles, beetle)
			print("Spawned beetle, Current table size: ".. #caster.beetles)
			unit:RemoveSelf()
			return
		end
	end

end

-- Denies casting if no corpses near, with a message
function CarrionBeetlesPrecast( event )
	local ability = event.ability
	local corpse = Entities:FindByModelWithin(nil, CORPSE_MODEL, event.caster:GetAbsOrigin(), ability:GetCastRange()) 
	if corpse == nil then
		event.caster:Interrupt()
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "No Usable Corpses Near" } )
	end
end

-- Remove the units from the table when they die to allow for new ones to spawn
function RemoveDeadBeetle( event )
	local caster = event.caster
	local unit = event.unit
	local targets = caster.beetles

	for k,beetle in pairs(targets) do		
	   	if beetle and IsValidEntity(beetle) and beetle == unit then
    	  	table.remove(caster.beetles,k)
    	  	print("Dead beetle, Current table size: ".. #caster.beetles)
    	end
	end
end