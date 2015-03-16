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
	caster.skip_order = false

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
	local max_lumber_carried = hero.LumberCarried or 10 --20/30 with upgrade

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
		caster.skip_order = true
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
		caster.skip_order = true
		caster.target_building = building
	end

end

function CheckBuildingPosition( event )

	local caster = event.caster
	local ability = event.ability

	if not caster.target_building or not IsValidEntity(caster.target_building) then
		-- Find where to return the resources
		caster.target_building = FindClosestResourceDeposit( caster )
		print("Resource delivery position set to "..caster.target_building:GetUnitName())
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
			PopupLumber(caster, caster.lumber_gathered)

			caster:RemoveModifierByName("modifier_returning_resources")
			print("Removed modifier_returning_resources")

			player.lumber = player.lumber + caster.lumber_gathered 
    		print("Lumber Gained. Player " .. pID .. " is currently at " .. player.lumber)
    		FireGameEvent('cgm_player_lumber_changed', { player_ID = pID, lumber = player.lumber })

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


function LumberHarvesting( event )
	local hero = event.caster:GetPlayerOwner():GetAssignedHero()
	local pID = hero:GetPlayerID()
	local level = event.Level
	local extra_lumber_carried = event.ability:GetLevelSpecialValueFor("extra_lumber_carried", Level - 1)

	hero.LumberCarried = 10 + extra_lumber_carried
end