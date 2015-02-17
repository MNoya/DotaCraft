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
			caster.gold_gathered = nil

			caster:MoveToTargetToAttack(target)
			print("Moving to Gold Mine")
			caster.target_mine = target

			ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_gold", {})

			-- Visual fake toggle
			if ability:GetToggleState() == false then
				ability:ToggleAbility()
			end

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

	local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length()
	local collision = distance < 250
	if not collision then
		print("Moving to mine, distance: ",distance)
	else
		caster:RemoveModifierByName("modifier_gathering_gold")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_mining_gold", {})
		print("Reached mine, send builder inside")
		caster:SetAbsOrigin(target:GetAbsOrigin())
		caster.gold_gathered = 10 --this is instant and uncancellable, no reason to increase it progressively
		local return_ability = caster:FindAbilityByName("human_return_resources")
		return_ability:ApplyDataDrivenModifier( caster, caster, "modifier_returning_resources", nil)

		-- Fake Toggle the Return ability
		if return_ability:GetToggleState() == false or return_ability:IsHidden() then
			print("Gather OFF, Return ON")
			return_ability:SetHidden(false)
			if return_ability:GetToggleState() == false then
				return_ability:ToggleAbility()
			end
			ability:SetHidden(true)
		end

	end
end


function Gather1Lumber( event )
	
	local caster = event.caster
	local ability = event.ability
	local max_lumber_carried = 5 --20 with upgrade

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

function ReturnResources( event )

	local caster = event.caster
	local ability = event.ability

	print("Return Resources")

	-- LUMBER
	if caster.lumber_gathered and caster.lumber_gathered > 0 then
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

		-- Set On, Wait one frame, as OnOrder gets executed before this is applied.
		Timers:CreateTimer(0.03, function() 
			if ability:GetToggleState() == false then
				ability:ToggleAbility()
				print("Return Ability Toggled On")
			end
		end)

		-- Get closest point from target_mine to building, to make the peasant appear
		caster:SetAbsOrigin(caster.target_mine:GetAbsOrigin() + RandomVector(300) )

		ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, TargetIndex = building:GetEntityIndex(), Position = building:GetAbsOrigin(), Queue = false}) 
		caster.skip_order = true
		caster.target_building = building
	end

end

function CheckBuildingPosition( event )

	local caster = event.caster
	local target = caster.target_building -- Index building so we know which target to start with
	local ability = event.ability

	if not target then
		return
	end

	local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length()
	local collision = distance <= (caster.target_building:GetHullRadius()+100)
	if not collision then
		print("Moving to building, distance: ",distance)
	else
		local hero = caster:GetOwner()
		local pID = hero:GetPlayerID()

		local returned_type = nil

		caster:RemoveModifierByName("modifier_returning_resources")
		print("Removed modifier_returning_resources")

		if caster.lumber_gathered > 0 then
			print("Reached building, give resources")
			PopupLumber(caster, caster.lumber_gathered)

			hero.lumber = hero.lumber + caster.lumber_gathered 
    		print("Lumber Gained. " .. hero:GetUnitName() .. " is currently at " .. hero.lumber)
    		FireGameEvent('cgm_player_lumber_changed', { player_ID = pID, lumber = hero.lumber })

			caster.lumber_gathered = 0

			returned_type = "lumber"
		
		elseif caster.gold_gathered > 0 then
			print("Reached building, give resources")
			PopupGoldGain(caster, caster.gold_gathered)

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
	local barracks = Entities:FindAllByModel("models/props_structures/good_barracks_melee001.vmdl")	
	local distance = 9999
	local closest_building = nil

	if barracks then
		print("barrack found")
		for _,building in pairs(barracks) do
			-- Ensure the same owner
			if building:GetOwner() == caster:GetOwner() then
				local this_distance = (position - building:GetAbsOrigin()):Length()
				if this_distance < distance then
					distance = this_distance
					closest_building = building
				end
			end
		end
		return closest_building

	elseif lumber_mill then
		return lumber_mill

	elseif town_hall then
		return town_hall
	end

end