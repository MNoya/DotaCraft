--[[
	Author: Noya
	Date: 21.01.2015.
	Primal Split
]]

-- Starts the ability
function PrimalSplit( event )
	local caster = event.caster
	local playerID = caster:GetPlayerID()
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor( "duration" , ability:GetLevel() - 1 )
	local level = ability:GetLevel()

	-- Set the unit names to create
	-- EARTH
	local unit_name_earth = event.unit_name_earth

	-- STORM
	local unit_name_storm = event.unit_name_storm

	-- FIRE
	local unit_name_fire = event.unit_name_fire

	-- Set the positions
	local forwardV = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
    local distance = 100
	local ang_right = QAngle(0, -90, 0)
    local ang_left = QAngle(0, 90, 0)

	-- Earth in front
	local earth_position = origin + forwardV * distance

	-- Storm at the left, a bit behind
	local storm_position = RotatePosition(origin, ang_left, earth_position)

	-- Fire at the righ, a bit behind
	local fire_position = RotatePosition(origin, ang_right, earth_position)

	-- Create the units
	caster.Earth = CreateUnitByName(unit_name_earth, earth_position, true, caster, caster, caster:GetTeamNumber())
	caster.Storm = CreateUnitByName(unit_name_storm, storm_position, true, caster, caster, caster:GetTeamNumber())
	caster.Fire = CreateUnitByName(unit_name_fire, fire_position, true, caster, caster, caster:GetTeamNumber())

	PlayerResource:AddToSelection(playerID, caster.Earth)
	PlayerResource:AddToSelection(playerID, caster.Storm)
	PlayerResource:AddToSelection(playerID, caster.Fire)
	PlayerResource:RemoveFromSelection(playerID, caster)

	-- Make them controllable
	caster.Earth:SetControllableByPlayer(playerID, true)
	caster.Storm:SetControllableByPlayer(playerID, true)
	caster.Fire:SetControllableByPlayer(playerID, true)

	-- Set all of them looking at the same point as the caster
	caster.Earth:SetForwardVector(forwardV)
	caster.Storm:SetForwardVector(forwardV)
	caster.Fire:SetForwardVector(forwardV)

	-- Learn all abilities on the units
	LearnAllAbilities(caster.Earth, 1)
	LearnAllAbilities(caster.Storm, 1)
	LearnAllAbilities(caster.Fire, 1)


	-- Apply modifiers to detect units dying
	ability:ApplyDataDrivenModifier(caster, caster.Earth, "modifier_split_unit", {})
	ability:ApplyDataDrivenModifier(caster, caster.Storm, "modifier_split_unit", {})
	ability:ApplyDataDrivenModifier(caster, caster.Fire, "modifier_split_unit", {})

	-- Make them expire after the duration
	caster.Earth:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
	caster.Storm:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
	caster.Fire:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

	-- Set the Earth unit as the primary active of the split (the hero will be periodically moved to the ActiveSplit location)
	caster.ActiveSplit = caster.Earth

	-- Hide the hero underground
	local underground_position = Vector(origin.x, origin.y, origin.z - 322)
	caster:SetAbsOrigin(underground_position)

	-- Leave no corpses
	caster.Earth.no_corpse = true
	caster.Storm.no_corpse = true
	caster.Fire.no_corpse = true

end

-- When the spell ends, the Brewmaster takes Earth's place. 
-- If Earth is dead he takes Storm's place, and if Storm is dead he takes Fire's place.
function SplitUnitDied( event )
	local caster = event.caster
	local attacker = event.attacker
	local unit = event.unit

	-- Chech which spirits are still alive
	if IsValidEntity(caster.Earth) and caster.Earth:IsAlive() then
		caster.ActiveSplit = caster.Earth
	elseif IsValidEntity(caster.Storm) and caster.Storm:IsAlive() then
		caster.ActiveSplit = caster.Storm
	elseif IsValidEntity(caster.Fire) and caster.Fire:IsAlive() then
		caster.ActiveSplit = caster.Fire
	else
		-- Check if they died because the spell ended, or where killed by an attacker
		-- If the attacker is the same as the unit, it means the summon duration is over.
		if attacker == unit then
			print("Primal Split End Succesfully")
		elseif attacker ~= unit then
			-- Kill the caster with credit to the attacker.
			caster:Kill(nil, attacker)
			caster.ActiveSplit = nil
		end
	end

	if caster.ActiveSplit then
		print(caster.ActiveSplit:GetUnitName() .. " is active now")
	else
		print("All Split Units were killed!")
	end

end

-- While the main spirit is alive, reposition the hero to its position so that auras are carried over.
-- This will also help finding the current Active primal split unit with the hero hotkey
function PrimalSplitAuraMove( event )
	-- Hide the hero underground on the Active Split position
	local caster = event.caster
	local active_split_position = caster.ActiveSplit:GetAbsOrigin()
	local underground_position = Vector(active_split_position.x, active_split_position.y, active_split_position.z - 322)
	caster:SetAbsOrigin(underground_position)

end

-- Ends the the ability, repositioning the hero on the latest active split unit
function PrimalSplitEnd( event )
	local caster = event.caster

	if caster.ActiveSplit then
		local position = caster.ActiveSplit:GetAbsOrigin()
		FindClearSpaceForUnit(caster, position, true)
	end

end

-- Auxiliar Function to loop over all the abilities of the unit and set them to a level
function LearnAllAbilities( unit, level )

	for i=0,15 do
		local ability = unit:GetAbilityByIndex(i)
		if ability then
			ability:SetLevel(level)
			print("Set Level "..level.." on "..ability:GetAbilityName())
		end
	end
end


--- SUB ABILITIES ---


--[[
	Author: Noya
	Date: 08.02.2015.
	Dispel Magic purges buffs from all enemy targets near, and deals damage to units with the SUMMONED flag.
]]
function DispelMagic( event )
	local caster = event.caster
	local ability = event.ability
	local damage = ability:GetLevelSpecialValueFor( "damage" , ability:GetLevel() - 1 )
	local abilityDamageType = ability:GetAbilityDamageType()
	local targets = event.target_entities

	for _,unit in pairs(targets) do
		unit:Purge(true, false, false, false, false)

		if unit:IsSummoned() then
			ApplyDamage({ victim = unit, attacker = event.target, damage = damage, ability = ability, damage_type = abilityDamageType}) 
		end
	end
end


--[[
	Author: Noya
	Date: 08.02.2015.
	Changes the attack target of units all targets near to the caster. Doesn't force them to attack for a duration, this is just micro control.
	To force the attack for a duration, use SetForceAttackTarget to caster, and then a timer to nil.
]]
function Taunt( event )
	local caster = event.caster
	local targets = event.target_entities

	for _,unit in pairs(targets) do
		unit:MoveToTargetToAttack(caster)
		--unit:SetForceAttackTarget(caster)
	end
end

--[[
	Author: Noya
	Date: 08.02.2015.
	Progressively sends the target at a max height, then up and down between an interval, and finally back to the original ground position.
]]
function TornadoHeight( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local duration_hero = ability:GetLevelSpecialValueFor( "duration_hero" , ability:GetLevel() - 1 )
	local duration_unit = ability:GetLevelSpecialValueFor( "duration_unit" , ability:GetLevel() - 1 )
	local cyclone_height = ability:GetLevelSpecialValueFor( "cyclone_height" , ability:GetLevel() - 1 )
	local cyclone_min_height = ability:GetLevelSpecialValueFor( "cyclone_min_height" , ability:GetLevel() - 1 )
	local cyclone_max_height = ability:GetLevelSpecialValueFor( "cyclone_max_height" , ability:GetLevel() - 1 )
	local tornado_start = GameRules:GetGameTime()

	-- Position variables
	local target_initial_x = target:GetAbsOrigin().x
	local target_initial_y = target:GetAbsOrigin().y
	local target_initial_z = target:GetAbsOrigin().z
	local position = Vector(target_initial_x, target_initial_y, target_initial_z)

	-- Adjust duration to hero or unit
	local duration = duration_hero
	if not target:IsHero() then
		duration = duration_unit
	end
	
	-- Height per time calculation
	local time_to_reach_max_height = duration / 10
	local height_per_frame = cyclone_height * 0.03
	print(height_per_frame)

	-- Time to go down
	local time_to_stop_fly = duration - time_to_reach_max_height
	print(time_to_stop_fly)

	-- Loop up and down
	local going_up = true

	-- Loop every frame for the duration
	Timers:CreateTimer(function()
		local time_in_air = GameRules:GetGameTime() - tornado_start
		
		-- First send the target at max height very fast
		if position.z < cyclone_height and time_in_air <= time_to_reach_max_height then
			--print("+",height_per_frame,position.z)
			
			position.z = position.z + height_per_frame
			target:SetAbsOrigin(position)
			return 0.03

		-- Go down until the target reaches the initial z
		elseif time_in_air > time_to_stop_fly and time_in_air <= duration then
			--print("-",height_per_frame)

			position.z = position.z - height_per_frame
			target:SetAbsOrigin(position)
			return 0.03

		-- Do Up and down cycles
		elseif time_in_air <= duration then
			-- Up
			if position.z < cyclone_max_height and going_up then 
				--print("going up")
				position.z = position.z + height_per_frame/3
				target:SetAbsOrigin(position)
				return 0.03

			-- Down
			elseif position.z >= cyclone_min_height then
				going_up = false
				--print("going down")
				position.z = position.z - height_per_frame/3
				target:SetAbsOrigin(position)
				return 0.03

			-- Go up again
			else
				--print("going up again")
				going_up = true
				return 0.03
			end

		-- End
		else
			print("End TornadoHeight")
		end
	end)
end

--[[
	Author: Noya
	Date: 16.01.2015.
	Rotates by an angle degree
]]
function Spin(keys)
    local target = keys.target
    local total_degrees = keys.Angle
    target:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,total_degrees,0), target:GetForwardVector()))
end