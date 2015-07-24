--------------------------------
--    Call To Arms Scripts    --
--------------------------------

-- NOTE: There should be a separate Call To Arms ability on each peasant but it's
-- 		 currently not possible because there's not enough ability slots visible

function CallToArms( event )
	local caster = event.caster
	local hero = caster:GetOwner()
	local ability = event.ability
	local player = caster:GetPlayerOwner()
	local pID = hero:GetPlayerID()

	print("CALL TO ARMS!")

	local allUnits = player.units
	for _,unit in pairs(allUnits) do
		if IsValidEntity(unit) and unit:GetUnitName() == "human_peasant" then
			local building = FindClosestCityCenter( unit )
			if building then
				unit.target_building = building
			else
				print("ERROR, No City Center Found")
				return
			end

			-- Send a move order to the closest city center.
			ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), 
									OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, 
									TargetIndex = building:GetEntityIndex(), 
									Position = building:GetAbsOrigin(), Queue = false})

			-- Apply the modifier to check position while moving to the building
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_calling_to_arms", {})

		end
	end
end

function CheckCityCenterPosition( event )
	local target = event.target -- The peasant
	local ability = event.ability
	local building = target.target_building

	if not building or not IsValidEntity(building) then
		-- Find where to return the resources
		target.target_building = FindClosestCityCenter( target )
		building = target.target_building
		print("Resource delivery position set to "..building:GetUnitName())
	end

	local player = building:GetPlayerOwner()

	local distance = (target:GetAbsOrigin() - building:GetAbsOrigin()):Length()
	local collision_size = building:GetHullRadius()*2 + 64
	local collision = distance <= collision_size
	if not collision then
		--print("Moving to building, distance: ",distance)
	else
		print(building:GetUnitName().." reached!")
		if target:GetUnitName() == "human_peasant" then
			
			local militia = ReplaceUnit(target, "human_militia")
			ability:ApplyDataDrivenModifier(militia, militia, "modifier_militia", {})

			-- Add the units to a table so they are easier to find later
			if not player.militia then
				player.militia = {}
			else
				table.insert(player.militia, militia)
			end
			print(#player.militia)
		elseif target:GetUnitName() == "human_militia" then
			CallToArmsEnd( event )
		end
	end
end


function BackToWork( event )
	local caster = event.caster -- The militia unit
	local ability = event.ability
	local pID = caster:GetOwner():GetPlayerID()

	local building = FindClosestCityCenter( caster )
	if building then
		caster.target_building = building
	else
		print("ERROR, No City Center Found")
		return
	end

	-- Send a move order to the closest city center.
	ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), 
							OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, 
							TargetIndex = building:GetEntityIndex(), 
							Position = building:GetAbsOrigin(), Queue = false})

	-- Apply the modifier to check position while moving to the building
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_back_to_work", {})
end

-- Aux to find Town Hall
function FindClosestCityCenter( caster )
	local position = caster:GetAbsOrigin()
	local player = caster:GetPlayerOwner()

	-- Find closest Town Hall building
	local buildings = player.structures
	local distance = 20000
	local closest_building = nil

	for _,building in pairs(buildings) do
		if IsValidMainBuildingName( building:GetUnitName() ) then
		   
			local this_distance = (position - building:GetAbsOrigin()):Length()
			if this_distance < distance then
				distance = this_distance
				closest_building = building
			end
		end
	end	
	return closest_building
end

function IsValidMainBuildingName( name )
	
	-- Possible Main Buildings are:
	local possible_buildings = { "human_town_hall",
								"human_keep",
								"human_castle"
							  }

	for i=1,#possible_buildings do 
		if name == possible_buildings[i] then
			return true
		end
	end

	return false
end

function CallToArmsEnd( event )
	local target = event.target
	local player = target:GetPlayerOwner()
	local peasant = ReplaceUnit( event.target, "human_peasant" )
	CheckAbilityRequirements(peasant, player)
	table.insert(player.units, peasant)
end

function ReplaceUnit( unit, new_unit_name )
	print("Replacing "..unit:GetUnitName().." with "..new_unit_name)

	local hero = unit:GetOwner()
	local player = unit:GetPlayerOwner()
	local pID = hero:GetPlayerID()

	local position = unit:GetAbsOrigin()
	local health = unit:GetHealth()
	unit:RemoveSelf()

	local new_unit = CreateUnitByName(new_unit_name, position, true, hero, hero, hero:GetTeamNumber())
	new_unit:SetOwner(hero)
	new_unit:SetControllableByPlayer(pID, true)
	new_unit:SetAbsOrigin(position)
	new_unit:SetHealth(health)
	FindClearSpaceForUnit(new_unit, position, true)

	return new_unit
end