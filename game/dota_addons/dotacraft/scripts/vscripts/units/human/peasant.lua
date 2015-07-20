MIN_DISTANCE_TO_TREE = 150
MIN_DISTANCE_TO_MINE = 250
DURATION_INSIDE_MINE = 1
TREE_HEALTH = 50
DAMAGE_TO_TREE = 1
DAMAGE_TO_MINE = 10
THINK_INTERVAL = 0.5
GOLD_DEPOSITS = { 	"human_town_hall",
					"human_keep",
					"human_castle"  
				}

LUMBER_DEPOSITS = { "human_lumber_mill",
					"human_town_hall",
					"human_keep",
					"human_castle"  }

-- Gather Start - Decides what behavior to use
function Gather( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local target_class = target:GetClassname()

	caster:Interrupt() -- Stops any instance of Hold/Stop the builder might have

	-- Initialize variables to keep track of how much resource is the unit carrying
	if not caster.lumber_gathered then
		caster.lumber_gathered = 0
	end

	-- Gather Lumber
	if target_class == "ent_dota_tree" then
		
		--print("Moving to ", target_class)
		local tree = target
		local tree_pos = tree:GetAbsOrigin()
		local particleName = "particles/ui_mouseactions/ping_circle_static.vpcf"
		local particle = ParticleManager:CreateParticleForPlayer(particleName, PATTACH_CUSTOMORIGIN, caster, caster:GetPlayerOwner())
		ParticleManager:SetParticleControl(particle, 0, Vector(tree_pos.x, tree_pos.y, tree_pos.z+20))
		ParticleManager:SetParticleControl(particle, 1, Vector(0,255,0))
		Timers:CreateTimer(3, function() 
			ParticleManager:DestroyParticle(particle, true)
		end)

		caster.target_tree = tree
		ability.cancelled = false
		if not tree.health then
			tree.health = TREE_HEALTH
		end

		tree.builder = caster

		-- Fake toggle the ability, cancel if any other order is given
		if ability:GetToggleState() == false then
			ability:ToggleAbility()
		end

		-- Recieving another order will cancel this
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_on_order_cancel_lumber", {})

		Timers:CreateTimer(function() 
			-- Move towards the tree until close range
			if not ability.cancelled then
				local distance = (tree_pos - caster:GetAbsOrigin()):Length()
				
				if distance > MIN_DISTANCE_TO_TREE then
					caster:MoveToTargetToAttack(tree)
					return THINK_INTERVAL
				else
					--print("Tree Reached")
					ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_lumber", {})
					return
				end
			else
				return
			end
		end)

		-- Hide Return
		local return_ability = caster:FindAbilityByName("human_return_resources")
		return_ability:SetHidden(true)
		ability:SetHidden(false)
		--print("Gathering Lumber ON, Return OFF")

	-- Gather Gold
	elseif target_class == "npc_dota_building" then
		if target:GetUnitName() == "gold_mine" then
			local mine = target
			local mine_pos = mine:GetAbsOrigin()
			caster.gold_gathered = 0
			caster.target_mine = mine
			ability.cancelled = false

			-- Fake toggle the ability, cancel if any other order is given
			if ability:GetToggleState() == false then
				ability:ToggleAbility()
			end

			-- Recieving another order will cancel this
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_on_order_cancel_gold", {})

			local mine_entrance_pos = mine.entrance+RandomVector(75)
			Timers:CreateTimer(function() 
				-- Move towards the mine until close range
				if not ability.cancelled then
					local distance = (mine_pos - caster:GetAbsOrigin()):Length()
					
					if distance > MIN_DISTANCE_TO_MINE then
						caster:MoveToPosition(mine_entrance_pos)
						--print("Moving to Mine, distance ", distance)
						return THINK_INTERVAL
					else
						--print("Mine Reached")
						if mine.builder then
							--print("Waiting for the builder inside to leave")
							return THINK_INTERVAL
						elseif mine and IsValidEntity(mine) then
							mine.builder = caster
							ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_gold", {duration = DURATION_INSIDE_MINE})
							caster:SetAbsOrigin(mine:GetAbsOrigin()) -- Send builder inside
							return
						else
							caster:RemoveModifierByName("modifier_on_order_cancel_gold")
							CancelGather(event)
						end
					end
				else
					return
				end
			end)
				
			-- Hide Return
			local return_ability = caster:FindAbilityByName("human_return_resources")
			return_ability:SetHidden(true)
		else
			--print("Not a valid gathering target")
			return
		end

	-- Repair Building
	elseif target_class == "npc_dota_creature" then
		if IsCustomBuilding(target) and target:GetHealthDeficit() > 0 then
			local building = target
			caster.repair_building = building

			local building_pos = building:GetAbsOrigin()
			
			ability.cancelled = false

			-- Fake toggle the ability, cancel if any other order is given
			if ability:GetToggleState() == false then
				ability:ToggleAbility()
			end

			-- Recieving another order will cancel this
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_on_order_cancel_repair", {})

			local collision_size = building:GetHullRadius()*2 + 64

			Timers:CreateTimer(function() 
				-- Move towards the building until close range
				if not ability.cancelled then
					if caster.repair_building and IsValidEntity(caster.repair_building) then
						local distance = (building_pos - caster:GetAbsOrigin()):Length()
						
						if distance > collision_size then
							caster:MoveToNPC(building)
							return THINK_INTERVAL
						else
							ability:ApplyDataDrivenModifier(caster, caster, "modifier_peasant_repairing", {})

							print("Reached building, starting the Repair process")
							return
						end
					else
						print("Building was killed in the way of a peasant to repair it")
						caster:RemoveModifierByName("modifier_on_order_cancel_repair")
						CancelGather(event)
					end
				else
					return
				end
			end)
		else
			print("Not a custom building or already on full health")
		end
	else
		print("Not a valid target for this ability")
		caster:Stop()
	end
end

-- Toggles Off Gather
function CancelGather( event )
	local caster = event.caster
	local ability = event.ability
	local return_ability = caster:FindAbilityByName("human_return_resources")
	ability.cancelled = true

	local tree = caster.target_tree
	if tree then
		tree.builder = nil
	end
	
	if ability:GetToggleState() == true then
		ability:ToggleAbility()
	end
	if return_ability:GetToggleState() == true then
		return_ability:ToggleAbility()
	end
end

-- Toggles Off Return because of an order (e.g. Stop)
function CancelReturn( event )
	local caster = event.caster
	local ability = event.ability
	local gather_ability = caster:FindAbilityByName("human_gather")
	ability.cancelled = true

	local tree = caster.target_tree
	if tree then
		tree.builder = nil
	end

	local mine = caster.target_mine
	
	if ability:GetToggleState() == true then
		ability:ToggleAbility()
	end
	if gather_ability:GetToggleState() == true then
		gather_ability:ToggleAbility()
	end
end

-- Gets called every second, increases the carried lumber of the peasant by 1 until it can't carry more
-- Also does tree cutting and reacquiring of new trees when necessary.
function GatherLumber( event )
	
	local caster = event.caster
	local ability = event.ability
	local player = caster:GetPlayerOwner()
	local max_lumber_carried = 10
	local tree = caster.target_tree

	--print("Tree Health: ", tree.health)

	-- Upgraded on LumberResearchComplete
	if player.LumberCarried then 
		max_lumber_carried = player.LumberCarried
	end

	local return_ability = caster:FindAbilityByName("human_return_resources")

	caster.lumber_gathered = caster.lumber_gathered + 1
	if tree and tree.health then

		-- Hit particle
		local particleName = "particles/custom/tree_pine_01_destruction.vpcf"
		local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, tree:GetAbsOrigin())

		tree.health = tree.health - DAMAGE_TO_TREE
		if tree.health <= 0 then
			tree:CutDown(caster:GetTeamNumber())
			local a_tree = FindEmptyNavigableTreeNearby(caster, tree:GetAbsOrigin(), 200)
			if a_tree then
				caster.target_tree = a_tree
			else
				-- Increase the radius
				caster.target_tree = FindEmptyNavigableTreeNearby(caster, tree:GetAbsOrigin(), 500)
				if not caster.target_tree then
					print("LOOKS LIKE WE CANT FIND A VALID TREE IN 500 RADIUS")
					--DebugDrawCircle(tree:GetAbsOrigin(), Vector(255,0,0), 100, 500, true, 10)
					ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = false})
				end

			end
			-- Cast gather on the new tree
		end
	end
		
	-- Show the stack of resources that the unit is carrying
	if not caster:HasModifier("modifier_carrying_lumber") then
        return_ability:ApplyDataDrivenModifier( caster, caster, "modifier_carrying_lumber", nil)
    end
    caster:SetModifierStackCount("modifier_carrying_lumber", caster, caster.lumber_gathered)
 
	-- Increase up to the max, or cancel
	if caster.lumber_gathered < max_lumber_carried and tree:IsStanding() then
		caster:StartGesture(ACT_DOTA_ATTACK)

		-- Show the return ability
		if return_ability:IsHidden() then
			caster:SwapAbilities("human_gather", "human_return_resources", false, true)
		end
	else
		-- RETURN
		local player = caster:GetOwner():GetPlayerID()
		caster:RemoveModifierByName("modifier_gathering_lumber")

		-- Cast Return Resources	
		caster:CastAbilityNoTarget(return_ability, player)
	end
end

-- Gets called after the peasant goes outside the mine
-- Takes DAMAGE_TO_MINE hit points away from the gold mine and starts the return
function GatherGold( event )
	local caster = event.caster
	local ability = event.ability
	local mine = caster.target_mine

	mine:SetHealth( mine:GetHealth() - DAMAGE_TO_MINE )
	caster.gold_gathered = DAMAGE_TO_MINE
	mine.builder = nil --Set the mine free for other builders to enter

	-- If the gold mine has no health left for another harvest
	if mine:GetHealth() < DAMAGE_TO_MINE then

		-- Destroy the nav blockers associated with it
		for k, v in pairs(mine.blockers) do
	      DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
	      DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
	    end

	    mine:RemoveSelf()

		caster.target_mine = nil
	end

	local return_ability = caster:FindAbilityByName("human_return_resources")
	return_ability:SetHidden(false)
	ability:SetHidden(true)

	return_ability:ApplyDataDrivenModifier( caster, caster, "modifier_carrying_gold", nil)
	caster:SetModifierStackCount("modifier_carrying_gold", caster, DAMAGE_TO_MINE)

	local player = caster:GetOwner():GetPlayerID()
					
	-- Find where to put the builder outside the mine
	local position = mine.entrance
	FindClearSpaceForUnit(caster, position, true)

	-- Cast ReturnResources
	caster:CastAbilityNoTarget(return_ability, player)
end

-- Called when the race_return_resources ability is cast
function ReturnResources( event )
	local caster = event.caster
	local ability = event.ability
	local hero = caster:GetOwner()
	local player = caster:GetPlayerOwner()
	local pID = hero:GetPlayerID()
	
	caster:Interrupt() -- Stops any instance of Hold/Stop the builder might have
	
	-- Return Ability On
	ability.cancelled = false
	if ability:GetToggleState() == false then
		ability:ToggleAbility()
	end

	local gather_ability = caster:FindAbilityByName("human_gather")

	-- LUMBER
	if caster:HasModifier("modifier_carrying_lumber") then

		-- Find where to return the resources
		local building = FindClosestResourceDeposit( caster, "lumber" )
		caster.target_building = building
		local collision_size = building:GetHullRadius()*2 + 64

		-- Move towards it
		Timers:CreateTimer(function() 
			if not ability.cancelled then
				if caster.target_building and IsValidEntity(caster.target_building) then
					local building_pos = building:GetAbsOrigin()
					local distance = (building_pos - caster:GetAbsOrigin()):Length()
				
					if distance > collision_size then
						caster:MoveToNPC(building)					
						return THINK_INTERVAL
					elseif caster.lumber_gathered and caster.lumber_gathered > 0 then
						--print("Building Reached at ",distance)
						caster:RemoveModifierByName("modifier_carrying_lumber")
						PopupLumber(caster, caster.lumber_gathered)
						ModifyLumber(player, caster.lumber_gathered)

						-- Also handle possible gold leftovers if its being deposited in a city center
						if caster:HasModifier("modifier_carrying_gold") then
							caster:RemoveModifierByName("modifier_carrying_gold")
							local upkeep = GetUpkeep( player )
							local gold_gain = caster.gold_gathered * upkeep
							hero:ModifyGold(gold_gain, false, 0)
							PopupGoldGain(caster, gold_gain)
							caster.gold_gathered = 0
						end

						caster.lumber_gathered = 0
						--print("Back to the trees")
						if caster.target_tree and caster.target_tree:IsStanding() then
							caster:CastAbilityOnTarget(caster.target_tree, gather_ability, pID)
						else
							-- Tree was cut down, find another
							-- Potential problem here, probably add a recursive check to always get one
							caster.target_tree = FindEmptyNavigableTreeNearby(caster, caster.target_tree:GetAbsOrigin(), 200)
							if caster.target_tree then
								caster:CastAbilityOnTarget(caster.target_tree, gather_ability, pID)
							else
								-- Cancel ability, couldn't find moar trees...
								print("NO MOAR TREES IN 200 RADIUS")
								if gather_ability:GetToggleState() == true then
									gather_ability:ToggleAbility()
								end

								caster:SwapAbilities("human_gather", "human_return_resources", true, false)
							end
						end
						return
					end
				else
					-- Find a new building deposit
					building = FindClosestResourceDeposit( caster, "lumber" )
					caster.target_building = building
					return THINK_INTERVAL
				end
			else
				return
			end
		end)

	-- GOLD
	elseif caster:HasModifier("modifier_carrying_gold") then

		-- Find where to return the resources
		local building = FindClosestResourceDeposit( caster, "gold" )
		caster.target_building = building
		local collision_size = building:GetHullRadius()*2 + 64

		-- Move towards it
		Timers:CreateTimer(function() 
			if not ability.cancelled then
				if caster.target_building and IsValidEntity(caster.target_building) then
					local building_pos = building:GetAbsOrigin()
					local distance = (building_pos - caster:GetAbsOrigin()):Length()
				
					if distance > collision_size then
						caster:MoveToNPC(building)
						return THINK_INTERVAL
					elseif caster.gold_gathered and caster.gold_gathered > 0 then
						--print("Building Reached at ",distance)
						local upkeep = GetUpkeep( player )
						local gold_gain = caster.gold_gathered * upkeep

						hero:ModifyGold(gold_gain, false, 0)
						PopupGoldGain(caster, gold_gain)

						caster:RemoveModifierByName("modifier_carrying_gold")

						-- Also handle possible lumber leftovers
						if caster:HasModifier("modifier_carrying_lumber") then
							caster:RemoveModifierByName("modifier_carrying_lumber")
							PopupLumber(caster, caster.lumber_gathered)
							ModifyLumber(player, caster.lumber_gathered)
							caster.lumber_gathered = 0
						end

						caster.gold_gathered = 0

						if caster.target_mine and IsValidEntity(caster.target_mine) then
							--print("Back to the Mine")

							caster:SwapAbilities("human_gather","human_return_resources", true, false)

							caster:CastAbilityOnTarget(caster.target_mine, gather_ability, pID)
						else
							--print("Mine Collapsed")
							if gather_ability:GetToggleState() == true then
								gather_ability:ToggleAbility()
							end
							caster:SwapAbilities("human_gather","human_return_resources", true, false)
							caster:RemoveModifierByName("modifier_on_order_cancel_gold")
						end
						return
					end
				else
					-- Find a new building deposit
					building = FindClosestResourceDeposit( caster, "gold" )
					caster.target_building = building
					return THINK_INTERVAL
				end
			else
				return
			end
		end)
	
	-- No resources to return, give the gather ability back
	else
		--print("TRIED TO RETURN NO RESOURCES")
		if gather_ability:GetToggleState() == true then
			gather_ability:ToggleAbility()
		end
		caster:SwapAbilities("human_gather","human_return_resources", true, false)
		caster:RemoveModifierByName("modifier_on_order_cancel_gold")
	end
end

-- Goes through the structures of the player finding the closest valid resource deposit
function FindClosestResourceDeposit( caster, resource_type )
	local position = caster:GetAbsOrigin()
	
	-- Find a building to deliver
	local player = caster:GetPlayerOwner()
	if not player then print("ERROR, NO PLAYER") return end
	local buildings = player.structures
	local distance = 20000
	local closest_building = nil

	if resource_type == "gold" then
		for _,building in pairs(buildings) do
			if IsValidGoldDepositName( building:GetUnitName() ) and not building:HasModifier("modifier_construction") then
			   
				local this_distance = (position - building:GetAbsOrigin()):Length()
				if this_distance < distance then
					distance = this_distance
					closest_building = building
				end
			end
		end

	elseif resource_type == "lumber" then
		for _,building in pairs(buildings) do
			if IsValidLumberDepositName( building:GetUnitName() ) and not building:HasModifier("modifier_construction") then
			   
				local this_distance = (position - building:GetAbsOrigin()):Length()
				if this_distance < distance then
					distance = this_distance
					closest_building = building
				end
			end
		end
	end
	
	return closest_building		

end

function IsValidGoldDepositName( name )
	
	for i=1,#GOLD_DEPOSITS do 
		if name == GOLD_DEPOSITS[i] then
			return true
		end
	end

	return false
end

function IsValidLumberDepositName( name )
	
	for i=1,#LUMBER_DEPOSITS do 
		if name == LUMBER_DEPOSITS[i] then
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

--------------------------------
--       Repair Scripts       --
--------------------------------

-- These are the Repair ratios for any race
-- Repair Cost Ratio = 0.35 - Takes 105g to fully repair a building that costs 300. Also applies to lumber
-- Repair Time Ratio = 1.5 - Takes 150 seconds to fully repair a building that took 100seconds to build

-- Humans can assist the construction with multiple peasants
-- In that case, extra resources are consumed
-- Powerbuild Cost = THINK_INTERVAL5 - Added for every extra builder repairing the same building
-- Powerbuild Rate = 0.60 - Fastens the ratio by 60%?
	
-- Values are taken from the UnitKV GoldCost LumberCost and BuildTime

function Repair( event )
	local caster = event.caster -- The builder
	local ability = event.ability
	local building = event.target -- The building to repair

	local hero = caster:GetOwner()
	local player = caster:GetPlayerOwner()
	local pID = hero:GetPlayerID()

	local building_name = building:GetUnitName()
	local building_info = GameRules.UnitKV[building_name]
	local gold_cost = building_info.GoldCost
	local lumber_cost = building_info.LumberCost
	local build_time = building_info.BuildTime

	local state = building.state -- "completed" or "building"
	local health_deficit = building:GetHealthDeficit()

	if ability:GetToggleState() == false then
		ability:ToggleAbility()
	end 

	-- If its an unfinished building, keep track of how much does it require to mark as finished
	if not building.constructionCompleted and not building.health_deficit then
		building.missingHealthToComplete = health_deficit
	end

	-- Scale costs/time according to the stack count of builders reparing this
	if health_deficit > 0 then
		-- Initialize the tracking
		if not building.health_deficit then
			building.health_deficit = health_deficit
			building.gold_used = 0
			building.lumber_used = 0
			building.HPAdjustment = 0
			building.GoldAdjustment = 0
			building.time_started = GameRules:GetGameTime()
		end
		
		local stack_count = building:GetModifierStackCount( "modifier_repairing_building", ability )

		-- HP
		local health_per_second = building:GetMaxHealth() /  ( build_time * 1.5 ) * stack_count
		local health_float = health_per_second - math.floor(health_per_second) -- floating point component
		health_per_second = math.floor(health_per_second) -- round down

		-- Don't expend resources for the first peasant repairing the building if its a construction
		if not building.constructionCompleted then
			stack_count = stack_count - 1
		end

		-- Gold
		local gold_per_second = gold_cost / ( build_time * 1.5 ) * 0.35 * stack_count
		local gold_float = gold_per_second - math.floor(gold_per_second) -- floating point component
		gold_per_second = math.floor(gold_per_second) -- round down

		-- Lumber takes floats just fine
		local lumber_per_second = lumber_cost / ( build_time * 1.5 ) * 0.35 * stack_count

		--[[print("Building is repaired for "..health_per_second)
		if gold_per_second > 0 then
			print("Cost is "..gold_per_second.." gold and "..lumber_per_second.." lumber per second")
		else
			print("Cost is "..gold_float.." gold and "..lumber_per_second.." lumber per second")
		end]]
			
		local healthGain = 0
		if PlayerHasEnoughGold( player, math.ceil(gold_per_second+gold_float) ) and PlayerHasEnoughLumber( player, lumber_per_second ) then
			-- Health
			building.HPAdjustment = building.HPAdjustment + health_float
			if building.HPAdjustment > 1 then
				healthGain = health_per_second + 1
				building:SetHealth(building:GetHealth() + healthGain)
				building.HPAdjustment = building.HPAdjustment - 1
			else
				healthGain = health_per_second
				building:SetHealth(building:GetHealth() + health_per_second)
			end
			
			-- Consume Resources
			building.GoldAdjustment = building.GoldAdjustment + gold_float
			if building.GoldAdjustment > 1 then
				hero:ModifyGold( -gold_per_second - 1, false, 0)
				building.GoldAdjustment = building.GoldAdjustment - 1
				building.gold_used = building.gold_used + gold_per_second + 1
			else
				hero:ModifyGold( -gold_per_second, false, 0)
				building.gold_used = building.gold_used + gold_per_second
			end
			
			ModifyLumber( player, -lumber_per_second )
			building.lumber_used = building.lumber_used + lumber_per_second
		else
			-- Remove the modifiers on the building and the builders
			building:RemoveModifierByName("modifier_repairing_building")
			for _,builder in pairs(building.units_repairing) do
				if builder and IsValidEntity(builder) then
					builder:RemoveModifierByName("modifier_peasant_repairing_animation")
					builder:RemoveModifierByName("modifier_peasant_repairing")
				end
			end
			print("Repair Ended, not enough resources!")
			building.health_deficit = nil
			building.missingHealthToComplete = nil
		end

		-- Decrease the health left to finish construction and mark building as complete
		if building.missingHealthToComplete then
			building.missingHealthToComplete = building.missingHealthToComplete - healthGain
		end

	-- Building Fully Healed
	else
		-- Remove the modifiers on the building and the builders
		building:RemoveModifierByName("modifier_repairing_building")
		for _,builder in pairs(building.units_repairing) do
			if builder and IsValidEntity(builder) then
				builder:RemoveModifierByName("modifier_peasant_repairing_animation")
				builder:RemoveModifierByName("modifier_peasant_repairing")
			end
		end
		print("Repair End")
		print("Start HP/Gold/Lumber/Time: ", building.health_deficit, gold_cost, lumber_cost, build_time)
		print("Final HP/Gold/Lumber/Time: ", building:GetHealth(), building.gold_used, math.floor(building.lumber_used), GameRules:GetGameTime() - building.time_started)
		building.health_deficit = nil
	end

	-- Construction Ended
	if building.missingHealthToComplete and building.missingHealthToComplete <= 0 then
		building.missingHealthToComplete = nil
		building.constructionCompleted = true -- BuildingHelper will track this and know the building ended
	else
		--print("Missing Health to Complete building: ",building.missingHealthToComplete)
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
		table.insert(target.units_repairing, caster)
	else
		table.insert(target.units_repairing, caster)
	end
end

function PeasantStopRepairing( event )
	local caster = event.caster
	local ability = event.ability
	local building = caster.repair_building
	
	-- Apply a modifier stack to the building, to show how many peasants are working on it (and scale the Powerbuild costs)
	local modifierName = "modifier_repairing_building"
	if building and IsValidEntity(building) and building:HasModifier(modifierName) then
		local current_stack = building:GetModifierStackCount( modifierName, ability )
		if current_stack > 1 then
			building:SetModifierStackCount( modifierName, ability, current_stack - 1 )
		else
			building:RemoveModifierByName( modifierName )
		end
	end

	-- Remove the builder from the list of units repairing the building
	local builder = getIndex(building.units_repairing, caster)
	if builder and builder ~= -1 then
		table.remove(building.units_repairing, builder)
	end
end