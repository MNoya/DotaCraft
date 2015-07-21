--[[
	Author: Noya
	Date: 18.01.2015.
	Gets the summoning location for the new unit
]]
function SummonLocation( event )
    local caster = event.caster
    local fv = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
    
    -- Gets the vector facing 200 units away from the caster origin
	local front_position = origin + fv * 200

    local result = { }
    table.insert(result, front_position)

    return result
end

-- Set the units looking at the same point of the caster
function SetUnitsMoveForward( event )
	local caster = event.caster -- The Blood Mage
	local target = event.target
    local fv = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
	
	target:SetForwardVector(fv)

	-- Add the target spawned unit to a table on the caster handle, to find them later
	table.insert(caster.phoenix, target)
	target:SetOwner(caster) --The Blood Mage has ownership over this, not the main hero
end

-- Kills the summoned units after a new spell start
function KillPhoenix( event )
	local caster = event.caster
	local targets = caster.phoenix

	if targets then 
		for _,unit in pairs(targets) do		
		   	if unit and IsValidEntity(unit) then
	    	  	unit:RemoveSelf()
	    	end
		end
	end

	-- Reset table
	caster.phoenix = {}
end

-- Deal self damage over time, through magic immunity. This is needed because negative HP regen is not working.
function PhoenixDegen( event )
	local caster = event.caster
	local ability = event.ability
	local phoenix_damage_per_second = ability:GetLevelSpecialValueFor( "phoenix_damage_per_second", ability:GetLevel() - 1 )

	local phoenixHP = caster:GetHealth()

	caster:SetHealth(phoenixHP - phoenix_damage_per_second)

	-- On Health 0 spawn an Egg (same as OnDeath)
	if caster:GetHealth() == 0 then
		PhoenixEgg(event)
	end
end

--[[
	Author: Noya
	Date: 26.01.2015.
	Removes the phoenix and spawns the egg with a timer
]]
function PhoenixEgg( event )
	local caster = event.caster --the phoenix
	local ability = event.ability
	local hero = caster:GetOwner()
	local phoenix_egg_duration = ability:GetLevelSpecialValueFor( "phoenix_egg_duration", ability:GetLevel() - 1 )
	local unit_name = "npc_phoenix_egg"

	-- Set the position, a bit floating over the ground
	local origin = caster:GetAbsOrigin()
	local position = Vector(origin.x, origin.y, origin.z+50)

	local egg = CreateUnitByName(unit_name, origin, true, hero, hero, hero:GetTeamNumber())
	egg:SetAbsOrigin(position)

	-- Add the spawned unit to the table
	table.insert(hero.phoenix, egg)

	-- Apply modifiers for the summon properties
	egg:AddNewModifier(hero, ability, "modifier_kill", {duration = phoenix_egg_duration})

	-- Leave no corpses
	egg.no_corpse = true
	caster.no_corpse = true
	caster:RemoveSelf()
end

--[[
	Author: Noya
	Date: 26.01.2015.
	Check if the egg died from an attacker other than the time-out
]]
function PhoenixEggCheckReborn( event )
	local unit = event.unit --the egg
	local attacker = event.attacker
	local ability = event.ability
	local hero = unit:GetOwner()
	local player = hero:GetPlayerOwner()
	local playerID = hero:GetPlayerID()

	if unit == attacker then
		print("Spawn a Phoenix")
		local unit_name = "npc_phoenix"

		local phoenix = CreateUnitByName(unit_name, unit:GetAbsOrigin(), true, player, hero, hero:GetTeamNumber())
		phoenix:SetControllableByPlayer(playerID, true)

		-- Add the spawned unit to the table
		table.insert(hero.phoenix, egg)

		-- Leave no corpses
		phoenix.no_corpse = true
		unit.no_corpse = true
		unit:RemoveSelf()
	else
		print("Egg killed by attacker: "..attacker:GetUnitName())
		local particleName = "particles/units/heroes/hero_phoenix/phoenix_supernova_death.vpcf"
		local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, unit)
		ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 1, unit:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 3, unit:GetAbsOrigin())
		
		-- Remove the unit, leave no corpse
		unit.no_corpse = true
		unit:RemoveSelf()
	end
end