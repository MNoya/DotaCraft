MIN_DISTANCE_TO_TREE = 150
MIN_DISTANCE_TO_MINE = 250
DURATION_INSIDE_MINE = 2
TREE_HEALTH = 50
DAMAGE_TO_TREE = 1
DAMAGE_TO_MINE = 10
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

	-- Initialize variables to keep track of how much resource is the unit carrying
	if not caster.lumber_gathered then
		caster.lumber_gathered = 0
	end

	-- Intialize the variable to stop the return (workaround for ExecuteFromOrder being good and MoveToNPC now working after a Stop)
	caster.manual_order = false

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
					if not caster.moving_to_tree then
						caster.moving_to_tree = true
						caster:MoveToTargetToAttack(tree)
					end
					--print("Moving to Tree, distance ", distance)
					return 0.1
				else
					--print("Tree Reached")
					caster.moving_to_tree = nil
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

			Timers:CreateTimer(function() 
				-- Move towards the mine until close range
				if not ability.cancelled then
					local distance = (mine_pos - caster:GetAbsOrigin()):Length()
					
					if distance > MIN_DISTANCE_TO_MINE then
						if not caster.moving_to_mine then
							caster.moving_to_mine = true
							caster:MoveToPosition(mine.entrance+RandomVector(75))
						end
						--print("Moving to Mine, distance ", distance)
						return 0.1
					else
						--print("Mine Reached")
						caster.moving_to_mine = nil
						if mine.builder then
							--print("Waiting for the builder inside to leave")
							return 0.1
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
		if target:HasAbility("ability_building") then
			if target:GetHealthDeficit() ~= 0 then
				--print("Repair Building On")
				caster:MoveToNPC(target)

				caster.repair_building = target
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_moving_to_repair", {})

			else
				--print("Building already on full health")
			end
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
	caster.moving_to_tree = nil
	caster.moving_to_mine = nil

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

		-- Fake Toggle the Return ability
		if return_ability:GetToggleState() == false or return_ability:IsHidden() then
			--print("Gather OFF, Return ON")
			return_ability:SetHidden(false)
			if return_ability:GetToggleState() == false then
				return_ability:ToggleAbility()
			end
			ability:SetHidden(true)
		end
	else
		-- RETURN
		local player = caster:GetOwner():GetPlayerID()
		caster:RemoveModifierByName("modifier_gathering_lumber")

		-- Return Ability On		
		caster:CastAbilityNoTarget(return_ability, player)
		return_ability:ToggleAbility()
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
		local collision_size = math.ceil(math.sqrt(#building.blockers)) * 64 --4 for size 3, 8 for size 4, 16 for size 5

		-- Move towards it
		Timers:CreateTimer(function() 
			if not ability.cancelled then
				if caster.target_building and IsValidEntity(caster.target_building) then
					local building_pos = building:GetAbsOrigin()
					local distance = (building_pos - caster:GetAbsOrigin()):Length()
				
					if distance > collision_size then
						caster:MoveToNPC(building)
						return 0.1
					else
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
					return 0.1
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
		local collision_size = math.ceil(math.sqrt(#building.blockers)) * 64 --4 for size 3, 8 for size 4, 16 for size 5

		-- Move towards it
		Timers:CreateTimer(function() 
			if not ability.cancelled then
				if caster.target_building and IsValidEntity(caster.target_building) then
					local building_pos = building:GetAbsOrigin()
					local distance = (building_pos - caster:GetAbsOrigin()):Length()
				
					if distance > collision_size then
						caster:MoveToNPC(building)
						return 0.1
					else
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
					return 0.1
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
			if IsValidGoldDepositName( building:GetUnitName() ) then
			   
				local this_distance = (position - building:GetAbsOrigin()):Length()
				if this_distance < distance then
					distance = this_distance
					closest_building = building
				end
			end
		end

	elseif resource_type == "lumber" then
		for _,building in pairs(buildings) do
			if IsValidLumberDepositName( building:GetUnitName() ) then
			   
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