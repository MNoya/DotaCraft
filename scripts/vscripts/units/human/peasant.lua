--[[
  TODO
	- Destroy Tree and FindNewTree when the tree is destroyed or when the peasant cant reach the targeted tree after a duration
	- Make the functions a bit cleaner for multiple resources
--]]

function Gather( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local target_class = target:GetClassname()

	print("Gather OnAbilityPhaseStart")

	-- Initialize variable to keep track of how much resource is the unit carrying
	if not caster.lumber_gathered then
		caster.lumber_gathered = 0
	end

	-- Intialize the variable to stop the return (workaround for ExecuteFromOrder being good and MoveToNPC now working after a Stop)
	caster.manual_order = false

	-- Gather Lumber
	if target_class == "ent_dota_tree" then
		caster:MoveToTargetToAttack(target)
		print("Moving to ", target_class)
		caster.target_tree = target

		ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_lumber", {})

		-- Visual fake toggle
		if ability:GetToggleState() == false then
			ability:ToggleAbility()
		end

		-- Hide Return
		local return_ability = caster:FindAbilityByName("human_return_resources")
		return_ability:SetHidden(true)
		ability:SetHidden(false)
		print("Gathering Lumber ON, Return OFF")

	-- Gather Gold
	elseif target_class == "npc_dota_building" then
		if target:GetUnitName() == "gold_mine" then
			print("Gathering Gold On")
			caster.gold_gathered = 0

			caster:MoveToTargetToAttack(target)
			print("Moving to Gold Mine")
			caster.target_mine = target

			ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_gold", {})

			-- Visual fake toggle
			if ability:GetToggleState() == false then
				ability:ToggleAbility()
			end

			-- Hide Return
			local return_ability = caster:FindAbilityByName("human_return_resources")
			return_ability:SetHidden(true)
			ability:SetHidden(false)
			print("Gathering Lumber ON, Return OFF")

		else
			print("Not a valid gathering target")
			return
		end

	-- Repair Building
	elseif target_class == "npc_dota_creature" then
		if target:HasAbility("ability_building") then
			if target:GetHealthDeficit() ~= 0 then
				print("Repair Building On")
				caster:MoveToNPC(target)

				caster.repair_building = target
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_moving_to_repair", {})

			else
				print("Building already on full health")
			end
		end
	end	
end

-- Toggles Off Gather
function ToggleOffGather( event )
	local caster = event.caster
	local gather_ability = caster:FindAbilityByName("human_gather")

	if gather_ability:GetToggleState() == true then
		gather_ability:ToggleAbility()
		print("Toggled Off Gather")
	end

end

-- Toggles Off Return because of an order (e.g. Stop)
function ToggleOffReturn( event )
	local caster = event.caster
	local return_ability = caster:FindAbilityByName("human_return_resources")

	if return_ability:GetToggleState() == true then 
		return_ability:ToggleAbility()
		print("Toggled Off Return")
	end
end


function CheckTreePosition( event )

	local caster = event.caster
	local target = caster.target_tree -- Index tree so we know which target to start with
	local ability = event.ability
	local target_class = target:GetClassname()

	if target_class == "ent_dota_tree" then
		caster:MoveToTargetToAttack(target)
		--print("Moving to "..target_class)
	end

	local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length()
	local collision = distance < 100
	if not collision then
		--print("Moving to tree, distance: ",distance)
	elseif not caster:HasModifier("modifier_chopping_wood") then
		caster:RemoveModifierByName("modifier_gathering_lumber")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_chopping_wood", {})
		print("Reached tree")
	end
end

function CheckMinePosition( event )

	local caster = event.caster
	local target = caster.target_mine 
	local ability = event.ability

	local targetLoc = target:GetAbsOrigin()
	local casterLoc = caster:GetAbsOrigin()
	local distance = (targetLoc - casterLoc):Length()
	local collision = distance < 200
	if not collision then
		--print("Moving to mine, distance: ",distance)
	else
		caster:RemoveModifierByName("modifier_gathering_gold")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_mining_gold", {duration = 2})
		print("Reached mine, send builder inside")
		caster:SetAbsOrigin(target:GetAbsOrigin())
		caster.gold_gathered = 10 --this is instant and uncancellable, no reason to increase it progressively like lumber
		
		local return_ability = caster:FindAbilityByName("human_return_resources")
		return_ability:ApplyDataDrivenModifier( caster, caster, "modifier_returning_gold", nil)

		-- Fake Toggle the Return ability
		if return_ability:GetToggleState() == false or return_ability:IsHidden() then
			print("Gather OFF, Return ON")
			return_ability:SetHidden(false)
			if return_ability:GetToggleState() == false then
				return_ability:ToggleAbility()
			end
			ability:SetHidden(true)			
		end

		Timers:CreateTimer(2.1, function() 
			local player = caster:GetOwner():GetPlayerID()
			
			-- Find where to return the resources
			local building = FindClosestResourceDeposit( caster )
			local targetLoc = building:GetAbsOrigin()
			local casterLoc = caster:GetAbsOrigin()
			
			-- Get closest point from target_mine to building, to make the peasant appear outside
			-- Find forward vector
			local forwardVec = (targetLoc - casterLoc):Normalized()
			local entrance_position = casterLoc + forwardVec * 220
			--DebugDrawLine(targetLoc, casterLoc, 255, 0, 0, false, 2)
			--DebugDrawCircle(entrance_position, Vector(0,255,0), 255, 10, true, 2)
		
			caster:SetAbsOrigin( entrance_position )
			caster:CastAbilityNoTarget(return_ability, player)

			print("Builder is now outside the mine on ", entrance_position)
		end)
	end
end

function Gather1Lumber( event )
	
	local caster = event.caster
	local ability = event.ability
	local player = caster:GetPlayerOwner()
	local max_lumber_carried = 10

	-- Upgraded on LumberResearchComplete
	if player.LumberCarried then 
		max_lumber_carried = player.LumberCarried
	end

	local return_ability = caster:FindAbilityByName("human_return_resources")

	caster.lumber_gathered = caster.lumber_gathered + 1
	print("Gathered "..caster.lumber_gathered)

	-- Show the stack of resources that the unit is carrying
	if not caster:HasModifier("modifier_returning_resources") then
        return_ability:ApplyDataDrivenModifier( caster, caster, "modifier_returning_resources", nil)
    end
    caster:SetModifierStackCount("modifier_returning_resources", caster, caster.lumber_gathered)
 
	-- Increase up to the max, or cancel
	if caster.lumber_gathered < max_lumber_carried then

		-- Fake Toggle the Return ability
		if return_ability:GetToggleState() == false or return_ability:IsHidden() then
			print("Gather OFF, Return ON")
			return_ability:SetHidden(false)
			if return_ability:GetToggleState() == false then
				return_ability:ToggleAbility()
			end
			ability:SetHidden(true)
		end
	else
		local player = caster:GetOwner():GetPlayerID()
		caster:RemoveModifierByName("modifier_chopping_wood")

		-- Return Ability On		
		caster:CastAbilityNoTarget(return_ability, player)
		return_ability:ToggleAbility()
	end
end

-- Takes 10 hit points away from the gold mine
function GatherGold( event )
	local caster = event.caster
	local ability = event.ability
	local target = caster.target_mine

	target:SetHealth( target:GetHealth() - 10 )

	if target:GetHealth() < 10 then
		target:RemoveSelf()
		caster.target_mine = nil

		-- Swap the gather ability back
		-- Hide Return
		local return_ability = caster:FindAbilityByName("human_return_resources")
		return_ability:SetHidden(true)
		ability:SetHidden(false)
		print("Gathering Lumber ON, Return OFF")
	end
end

function DestroyMine( event )
	print("RIP MINE")
	event.caster:RemoveSelf()
end

function ReturnResources( event )

	local caster = event.caster
	local ability = event.ability

	print("Return Resources")

	-- LUMBER
	if caster.lumber_gathered and caster.lumber_gathered > 0 then

		ability:ApplyDataDrivenModifier(caster, caster, "modifier_returning_resources", {})

		-- Find where to return the resources
		local building = FindClosestResourceDeposit( caster )
		print("Returning "..caster.lumber_gathered.." Lumber back to "..building:GetUnitName())

		-- Set On, Wait one frame, as OnOrder gets executed before this is applied.
		Timers:CreateTimer(0.03, function() 
			if ability:GetToggleState() == false then
				ability:ToggleAbility()
				print("Return Ability Toggled On")
			end
		end)

		ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, TargetIndex = building:GetEntityIndex(), Position = building:GetAbsOrigin(), Queue = false}) 
		caster.target_building = building
	

	-- GOLD
	elseif caster.gold_gathered and caster.gold_gathered > 0 then

		-- Find where to return the resources
		local building = FindClosestResourceDeposit( caster )
		print("Returning "..caster.gold_gathered.." Gold back to "..building:GetUnitName())

		ability:ApplyDataDrivenModifier(caster, caster, "modifier_returning_gold", {})

		-- Set On, Wait one frame, as OnOrder gets executed before this is applied.
		Timers:CreateTimer(0.03, function() 
			if ability:GetToggleState() == false then
				ability:ToggleAbility()
				print("Return Ability Toggled On")
			end
		end)

		ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, TargetIndex = building:GetEntityIndex(), Position = building:GetAbsOrigin(), Queue = false}) 
		caster.target_building = building
	end

end

function CheckBuildingPosition( event )

	local caster = event.caster
	local ability = event.ability

	if not caster.target_building or not IsValidEntity(caster.target_building) then
		-- Find where to return the resources
		caster.target_building = FindClosestResourceDeposit( caster )
		if caster.target_building then
			print("Resource delivery position set to "..caster.target_building:GetUnitName())
		else
			print("ERROR finding the closest resource deposit")
			return
		end
	end

	local target = caster.target_building

	local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length()
	local collision = distance <= (target:GetHullRadius()+100)
	if not collision then
		--print("Moving to building, distance: ",distance)
	else
		local hero = caster:GetOwner()
		local player = caster:GetPlayerOwner()
		local pID = hero:GetPlayerID()

		local returned_type = nil

		if caster.lumber_gathered and caster.lumber_gathered > 0 then
			print("Reached building, give resources")
			
			caster:RemoveModifierByName("modifier_returning_resources")
			print("Removed modifier_returning_resources")
			PopupLumber(caster, caster.lumber_gathered)
    		ModifyLumber(player, caster.lumber_gathered)

			caster.lumber_gathered = 0

			returned_type = "lumber"
		
		elseif caster.gold_gathered and caster.gold_gathered > 0 then
			print("Reached building, give resources")
			PopupGoldGain(caster, caster.gold_gathered)

			caster:RemoveModifierByName("modifier_returning_gold")
			print("Removed modifier_returning_gold")

			hero:ModifyGold(caster.gold_gathered, false, 0)

			caster.gold_gathered = 0

			returned_type = "gold"
		end

		-- Return Ability Off
		if ability:ToggleAbility() == true then
			ability:ToggleAbility()
			print("Return Ability Toggled Off")
		end

		-- Gather Ability
		local gather_ability = caster:FindAbilityByName("human_gather")
		if gather_ability:ToggleAbility() == false then
			-- Fake toggle On
			gather_ability:ToggleAbility() 
			print("Gather Ability Toggled On")
		end

		if returned_type == "lumber" then
			caster:CastAbilityOnTarget(caster.target_tree, gather_ability, pID)
			print("Casting ability to target tree")
		elseif returned_type == "gold" then
			caster:CastAbilityOnTarget(caster.target_mine, gather_ability, pID)
			print("Casting ability to target mine")
		end
		

	end
end


-- Aux to find resource deposit
function FindClosestResourceDeposit( caster )
	local position = caster:GetAbsOrigin()

	-- Find a Lumber Mill, a Town Hall and Barracks
	--local lumber_mill = Entities:FindByModel(nil, "models/buildings/building_plain_reference.vmdl")
	--local town_hall = Entities:FindByModel(nil, "models/props_garden/building_garden005.vmdl")
	
	-- Find a building to deliver
	local player = caster:GetPlayerOwner()
	if not player then print("ERROR, NO PLAYER") return end
	local buildings = player.structures
	local distance = 9999
	local closest_building = nil

	for _,building in pairs(buildings) do
		if IsValidDepositName( building:GetUnitName() ) then
		   
			local this_distance = (position - building:GetAbsOrigin()):Length()
			if this_distance < distance then
				distance = this_distance
				closest_building = building
			end
		end
	end
	
	return closest_building		

end

function IsValidDepositName( name )
	
	-- Possible Delivery Buildings are:
	local possible_deposits = { "human_town_hall",
								"human_keep",
								"human_castle",
								"human_barracks",
								"human_lumber_mill"
							  }

	for i=1,#possible_deposits do 
		if name == possible_deposits[i] then
			return true
		end
	end

	return false
end


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
	local collision = distance <= (building:GetHullRadius()+100)
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
	local distance = 9999
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

--------------------------------
--       Repair Scripts       --
--------------------------------

-- These are the Repair ratios for any race
-- Repair Cost Ratio = 0.35 - Takes 105g to fully repair a building that costs 300. Also applies to lumber
-- Repair Time Ratio = 1.5 - Takes 150 seconds to fully repair a building that took 100seconds to build

-- Humans can assist the construction with multiple peasants
-- In that case, extra resources are consumed
-- Powerbuild Cost = 0.15 - Added for every extra builder repairing the same building
-- Powerbuild Rate = 0.60 - Fastens the ratio by 60%?
	
-- Values are taken from the UnitKV GoldCost LumberCost and BuildTime

function Repair( event )
	local caster = event.caster
	local target = event.target -- The building to repair

	local hero = caster:GetOwner()
	local player = caster:GetPlayerOwner()
	local pID = hero:GetPlayerID()

	local building_name = target:GetUnitName()
	local building_info = GameRules.UnitKV[building_name]
	local gold_cost = building_info.GoldCost
	local lumber_cost = building_info.LumberCost
	local build_time = building_info.BuildTime

	-- Scale costs/time according to the stack count of builders reparing this
	if target:GetHealthDeficit() > 0 then
		-- Initialize the tracking
		if not target.health_deficit then
			target.health_deficit = target:GetHealthDeficit()
			target.gold_used = 0
			target.lumber_used = 0
			target.HPAdjustment = 0
			target.GoldAdjustment = 0
			target.time_started = GameRules:GetGameTime()
		end
		
		local stack_count = target:GetModifierStackCount( "modifier_repairing_building", ability )

		-- HP
		local health_per_second = target:GetMaxHealth() /  ( build_time * 1.5 ) * stack_count
		local health_float = health_per_second - math.floor(health_per_second) -- floating point component
		health_per_second = math.floor(health_per_second) -- round down

		-- Gold
		local gold_per_second = gold_cost / ( build_time * 1.5 ) * 0.35 * stack_count
		local gold_float = gold_per_second - math.floor(gold_per_second) -- floating point component
		gold_per_second = math.floor(gold_per_second) -- round down

		-- Lumber takes floats just fine
		local lumber_per_second = lumber_cost / ( build_time * 1.5 ) * 0.35 * stack_count

		print("Building is repaired for "..health_per_second)
		if gold_per_second > 0 then
			print("Cost is "..gold_per_second.." gold and "..lumber_per_second.." lumber per second")
		else
			print("Cost is "..gold_float.." gold and "..lumber_per_second.." lumber per second")
		end
			
		if PlayerHasEnoughGold( player, math.ceil(gold_per_second+gold_float) ) and PlayerHasEnoughLumber( player, lumber_per_second ) then
			--target:SetHealth( target:GetHealth() +  health_per_second)
			target.HPAdjustment = target.HPAdjustment + health_float
			if target.HPAdjustment > 1 then
				target:SetHealth(target:GetHealth() + health_per_second + 1)
				target.HPAdjustment = target.HPAdjustment - 1
			else
				target:SetHealth(target:GetHealth() + health_per_second)
			end
			
			--hero:ModifyGold( -gold_per_second, false, 0)
			target.GoldAdjustment = target.GoldAdjustment + gold_float
			if target.GoldAdjustment > 1 then
				hero:ModifyGold( -gold_per_second - 1, false, 0)
				target.GoldAdjustment = target.GoldAdjustment - 1
				target.gold_used = target.gold_used + gold_per_second + 1
			else
				hero:ModifyGold( -gold_per_second, false, 0)
				target.gold_used = target.gold_used + gold_per_second
			end
			
			ModifyLumber( player, -lumber_per_second )
			target.lumber_used = target.lumber_used + lumber_per_second
		else
			-- Remove the modifiers on the building and the builders
			target:RemoveModifierByName("modifier_repairing_building")
			for _,builder in pairs(target.units_repairing) do
				if builder and IsValidEntity(builder) then
					builder:RemoveModifierByName("modifier_repairing_animation")
					builder:RemoveModifierByName("modifier_repair_peasant")
				end
			end
			print("Repair Ended, not enough resources!")
			target.health_deficit = nil
		end
	else
		-- Remove the modifiers on the building and the builders
		target:RemoveModifierByName("modifier_repairing_building")
		for _,builder in pairs(target.units_repairing) do
			if builder and IsValidEntity(builder) then
				builder:RemoveModifierByName("modifier_repairing_animation")
				builder:RemoveModifierByName("modifier_repair_peasant")
			end
		end
		print("Repair End")
		print("Start HP/Gold/Lumber/Time: ", target.health_deficit, gold_cost, lumber_cost, build_time)
		print("Final HP/Gold/Lumber/Time: ", target:GetHealth(), target.gold_used, math.floor(target.lumber_used), GameRules:GetGameTime() - target.time_started)
		target.health_deficit = nil
	end
end

function PeasantRepairing( event )
	local caster = event.caster
	local ability = event.ability
	local target = caster.repair_building
	
	-- Apply a modifier stack to the building, to show how many peasants are working on it (and scale the Powerbuild costs)
	local modifierName = "modifier_repairing_building"
	if target:HasModifier(modifierName) then
		target:SetModifierStackCount( modifierName, ability, target:GetModifierStackCount( modifierName, ability ) + 1 )
	else
		ability:ApplyDataDrivenModifier( caster, target, modifierName, { Duration = duration } )
		target:SetModifierStackCount( modifierName, ability, 1 )
	end

	-- Keep a list of the units repairing this building
	if not target.units_repairing then
		target.units_repairing = {}
	else
		table.insert(target.units_repairing, caster)
	end
end

function PeasantStopRepairing( event )
	local caster = event.caster
	local ability = event.ability
	local target = caster.repair_building
	
	-- Apply a modifier stack to the building, to show how many peasants are working on it (and scale the Powerbuild costs)
	local modifierName = "modifier_repairing_building"
	if target:HasModifier(modifierName) then
		local current_stack = target:GetModifierStackCount( modifierName, ability )
		if current_stack > 1 then
			target:SetModifierStackCount( modifierName, ability, current_stack - 1 )
		else
			target:RemoveModifierByName( modifierName )
		end
	end

	-- Remove the builder from the list of units repairing the building
	local builder = getIndex(target.units_repairing, caster)
	if builder and builder ~= -1 then
		table.remove(target.units_repairing, builder)
	end
end

function CheckRepairPosition( event )
	local caster = event.caster
	local ability = event.ability
	local target = caster.repair_building

	if not target or not IsValidEntity(target) then
		print("ERROR, building can't be found")
		return
	end

	local distance = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length()
	local collision = distance <= (target:GetHullRadius()+100)
	if not collision then
		--print("Moving to building, distance: ",distance)
	else
		local hero = caster:GetOwner()
		local player = caster:GetPlayerOwner()
		local pID = hero:GetPlayerID()

		-- Apply a modifier on the caster to start repairing
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_repair_peasant", {})

		print("Reached building, starting the Repair process")
		caster:RemoveModifierByName("modifier_moving_to_repair")
	end
		
end