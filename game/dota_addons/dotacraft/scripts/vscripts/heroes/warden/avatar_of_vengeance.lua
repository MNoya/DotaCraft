--[[
	Author: Noya
	Date: 14.1.2015
	Finds the npc_spirit_of_vengeance in the map and kills them
]]
function KillVengeanceSpirits(event)
	local avatar = event.caster
	local kill_radius = 3000 -- This could be higher but might have performance issues

	for _,v in pairs(avatar.spirits) do
		if v and IsValidEntity(v) and v:IsAlive() then
			v:ForceKill(false)
		end
	end
end

-- Denies casting if no corpses near, with a message
function SpiritOfVengeancePrecast( event )
	local ability = event.ability
	local caster = event.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local pID = hero:GetPlayerID()
	local corpse = Entities:FindByModelWithin(nil, CORPSE_MODEL, event.caster:GetAbsOrigin(), ability:GetCastRange()) 
	if corpse == nil then
		event.caster:Interrupt()
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "No Usable Corpses Near" } )
	end
end

--[[
	Author: Noya
	Date: 25.01.2015.
	Spawns a spirit near a corpse, consuming it in the process.
]]
function SpiritOfVengeanceSpawn( event )
	local caster = event.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	local ability = event.ability
	local level = ability:GetLevel()
	local spirit_limit = ability:GetLevelSpecialValueFor( "spirit_limit", ability:GetLevel() - 1 )
	local unit_name = "npc_spirit_of_vengeance"

	-- Initialize the table of spirits
	if caster.spirits == nil then
		caster.spirits = {}
	end

	-- Find all corpse entities in the radius
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), ability:GetCastRange())

	-- Go through every unit, stop at the first corpse found
	for _, unit in pairs(targets) do
		if unit.corpse_expiration ~= nil then

			-- If the caster has already hit the limit of spirits, kill the oldest, then continue
			if #caster.spirits >= spirit_limit then
				print("Attempting to kill one spirit from "..#caster.spirits)
				for k,v in pairs(caster.spirits) do
					if k==1 and v and IsValidEntity(v) and v:IsAlive() then v:ForceKill(false) end
				end
			end

			-- Create the spirit
			local spirit = CreateUnitByName(unit_name, unit:GetAbsOrigin(), true, hero, hero, hero:GetTeamNumber())
			print(unit_name, playerID, unit:GetAbsOrigin(), caster:GetUnitName(), hero:GetUnitName(), hero:GetTeamNumber())
			
			spirit:SetControllableByPlayer(playerID, true)
			spirit.no_corpse = true
			table.insert(caster.spirits, spirit)
			print("Spawned spirit, Current table size: ".. #caster.spirits)
			unit:EmitSound("Hero_Spectre.DaggerCast")
			unit:RemoveSelf()
			return
		end
	end
end