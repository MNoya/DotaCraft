--[[
	Author: Noya
	Date: 14.1.2015
	Finds the npc_spirit_of_vengeance in the map and kills them
]]
function KillVengeanceSpirits(event)
	local caster = event.caster

	for _,v in pairs(caster.spirits) do
		if v and IsValidEntity(v) and v:IsAlive() then
			v:ForceKill(false)
		end
	end

	caster.spirit_count = 0
	caster.spirits = {}
end

-- Denies casting if no corpses near, with a message
function SpiritOfVengeancePrecast( event )
	local ability = event.ability
	local caster = event.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local pID = hero:GetPlayerID()
	local corpse = FindCorpseInRadius(caster:GetAbsOrigin(), ability:GetCastRange())
	if corpse == nil then
		event.caster:Interrupt()
		SendErrorMessage(pID, "#error_no_usable_corpses")
	end
end

-- Checks in radius to create new spirits if possible
function SpiritOfVengeanceAutocast( event )
	local ability = event.ability
	local caster = event.caster
	if ability:GetAutoCastState() == true then
		local corpse = FindCorpseInRadius(caster:GetAbsOrigin(), ability:GetCastRange())
		local spirit_limit = ability:GetSpecialValueFor( "spirit_limit" )
		if corpse and caster.spirit_count and caster.spirit_count < spirit_limit then
			caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())
		end
	end
end

function InitializeSpiritCount( event )
	local caster = event.caster

	-- Initialize the table of spirits
	caster.spirits = {}
	caster.spirit_count = 0
end

-- When a spirit times out or gets killed
function UpdateSpirits( event )
	local caster = event.caster
	local avatar = caster.avatar

	if avatar.spirit_count then
		avatar.spirit_count = avatar.spirit_count - 1
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
	local spirit_limit = ability:GetSpecialValueFor( "spirit_limit" )
	local duration = ability:GetSpecialValueFor( "spirit_limit" )
	local unit_name = "npc_spirit_of_vengeance"

	-- Find all corpse entities in the radius
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), ability:GetCastRange())

	-- Go through every unit, stop at the first corpse found
	for _, unit in pairs(targets) do
		if unit.corpse_expiration ~= nil then

			-- If the caster has already hit the limit of spirits, kill the oldest, then continue
			if caster.spirit_count >= spirit_limit then
				for k,v in pairs(caster.spirits) do
					if IsValidEntity(v) and v:IsAlive() then 
						v:ForceKill(false)
						return
					end
				end
			end

			-- Create the spirit
			local spirit = CreateUnitByName(unit_name, unit:GetAbsOrigin(), true, hero, hero, hero:GetTeamNumber())
			spirit:AddNewModifier(caster, {}, "modifier_kill", {duration = 50})
			spirit.avatar = caster
			
			spirit:SetControllableByPlayer(playerID, true)
			spirit.no_corpse = true
			table.insert(caster.spirits, spirit)
			caster.spirit_count = caster.spirit_count + 1

			unit:EmitSound("Hero_Spectre.DaggerCast")
			unit:RemoveSelf()
			return
		end
	end
end