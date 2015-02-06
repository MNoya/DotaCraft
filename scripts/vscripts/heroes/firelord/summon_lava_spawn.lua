--[[
	Author: Noya
	Date: 20.01.2015.
	Gets the summoning location for the new units
]]
function GetSummonPoints( event )
    local caster = event.caster
    local fv = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
    local distance = event.distance

	local front_position = origin + fv * distance

    local result = { }
    table.insert(result, front_position)

    return result
end

-- Set the units looking at the same point of the caster
function SetUnitsMoveForward( event )
	local caster = event.caster
	local target = event.target
    local fv = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
	
	target:SetForwardVector(fv)

	-- Keep the unit creation time to replicate
	target.creation_time = GameRules:GetGameTime()

	-- Leave no corpse
	target.no_corpse = true
end


--[[
	Author: Noya
	Date: 20.01.2015.
	Counts hits made, create a new unit, with the same kill time and hp remaining than the original
]]
function LavaSpawnAttackCounter( event )
	local caster = event.caster
	local player = caster:GetPlayerID()
	local attacker = event.attacker
	local ability = event.ability
	local attacks_to_split = ability:GetLevelSpecialValueFor( "attacks_to_split", ability:GetLevel() - 1 )
	local lava_spawn_duration = ability:GetLevelSpecialValueFor( "lava_spawn_duration", ability:GetLevel() - 1 )

	-- Initialize counter
	if not attacker.attack_counter then
		attacker.attack_counter = 0
	end

	-- Increase counter
	attacker.attack_counter = attacker.attack_counter + 1

	-- Copy the unit, applying all the necessary modifiers
	if attacker.attack_counter == attacks_to_split then
		
		local lava_spawn = CreateUnitByName(attacker:GetUnitName(), attacker:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
		lava_spawn:SetControllableByPlayer(player, true)
		ability:ApplyDataDrivenModifier(caster, lava_spawn, "modifier_lava_spawn", nil)
		lava_spawn:SetHealth(attacker:GetHealth())
		local time = lava_spawn_duration - ( GameRules:GetGameTime() - attacker.creation_time) 
		print(time)
		lava_spawn:AddNewModifier(caster, ability, "modifier_kill", {duration = time})
		lava_spawn.no_corpse = true
	end
end
