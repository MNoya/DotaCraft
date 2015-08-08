function build( keys )

	-- Checks if there is enough custom resources to start the building, else stop.
	local caster = keys.caster
	local ability = keys.ability
	local ability_name = ability:GetAbilityName()
	local AbilityKV = GameRules.AbilityKV
	local UnitKV = GameRules.UnitKV

	caster:Interrupt() -- Stops any instance of Hold/Stop the builder might have

	-- Handle the name for item-ability build
	local building_name
	if keys.ItemUnitName then
		building_name = keys.ItemUnitName
	else
		building_name = AbilityKV[ability_name].UnitName --Building Helper value, could just be a parameter of the RunScript but w/e
	end

	local unit_table = UnitKV[building_name]
	local gold_cost = ability:GetSpecialValueFor("gold_cost")
	local lumber_cost = ability:GetSpecialValueFor("lumber_cost")

	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	local player = PlayerResource:GetPlayer(playerID)	

	-- Refund the gold, as the building hasn't been placed yet
	hero:ModifyGold(gold_cost, false, 0)

	if not PlayerHasEnoughLumber( player, lumber_cost ) then
		return
	end

	BuildingHelper:AddBuilding(keys)

	keys:OnPreConstruction(function(vPos)

		print('preconstruction')

       	-- Blight check
       	if string.match(building_name, "undead") and building_name ~= "undead_necropolis" then
       		local bHasBlight = HasBlight(vPos)
       		print("Blight check for "..building_name..":", bHasBlight)
       		if not bHasBlight then
       			SendErrorMessage(caster:GetPlayerOwnerID(), "#error_must_build_on_blight")
       			return false
       		end
       	end

       	-- Proximity to gold mine check for Human/Orc: Main Buildings can be as close as 768.015 towards the center of the Gold Mine.
       	if HasGoldMineDistanceRestriction(building_name) then
			local nearby_mine = Entities:FindAllByNameWithin("*gold_mine", vPos, 768)
			if #nearby_mine > 0 then
				SendErrorMessage(caster:GetPlayerOwnerID(), "#error_too_close_to_goldmine")
       			return false
			end
       	end
    end)

	keys:OnConstructionStarted(function(unit)
		print("Started construction of " .. unit:GetUnitName())
		-- Unit is the building be built.
		-- Play construction sound

		  -- Give item to cancel
		  local item = CreateItem("item_building_cancel", playersHero, playersHero)
		  unit:AddItem(item)

		-- FindClearSpace for the builder
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		caster:AddNewModifier(caster, nil, "modifier_phased", {duration=0.03})

		hero:ModifyGold(-gold_cost, false, 0)
    	ModifyLumber( player, -lumber_cost)

    	-- Remove invulnerability on npc_dota_building baseclass
    	unit:RemoveModifierByName("modifier_invulnerable")

    	-- Particle effect
    	local item = CreateItem("item_apply_modifiers", nil, nil)
    	item:ApplyDataDrivenModifier(caster, unit, "modifier_construction", {})
    	item = nil

    	-- Check the abilities of this building, disabling those that don't meet the requirements
    	--print("=Checking Requirements on "..unit:GetUnitName())
    	CheckAbilityRequirements( unit, player )

    	-- Apply the current level of Masonry to the newly upgraded building
		local masonry_rank = GetCurrentResearchRank(player, "human_research_masonry1")
		if masonry_rank and masonry_rank > 0 then
			print("Applying masonry rank "..masonry_rank.." to this building construction")
			UpdateUnitUpgrades( unit, player, "human_research_masonry"..masonry_rank )
		end

		-- Apply altar linking
		if string.find( unit:GetUnitName(), "altar") then
			unit:AddAbility("ability_altar")
			local ability = unit:FindAbilityByName("ability_altar")
			ability:SetLevel(1)
		end

		-- Add the building handle to the list of structures
		table.insert(player.structures, unit)


	end)

	keys:OnBuildingPosChosen(function(vPos)
		-- in WC3 some build sound was played here.

		local hull = unit_table.CollisionSize*2
		local units = FindUnitsInRadius(caster:GetTeamNumber(), vPos, nil, hull, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)

		-- Move the units away from the building place
		for _,unit in pairs(units) do
			if unit ~= caster and not IsCustomBuilding(unit) then
				print(unit:GetUnitName().." moving")
				local front_position = unit:GetAbsOrigin() + unit:GetForwardVector() * hull
				ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = front_position, Queue = false})
				unit:AddNewModifier(caster, nil, "modifier_phased", {duration=1})
			end
		end

	end)

	keys:OnConstructionFailed(function(unit)
		SendErrorMessage(caster:GetPlayerOwnerID(), "#error_invalid_build_position")
	end)

	-- This needs fixing
	keys:OnConstructionCancelled(function(unit)
		--print("Construction Cancelled")
	end)

	keys:OnConstructionCompleted(function(unit)
		print("[BH] Completed construction of " .. unit:GetUnitName())
		-- Play construction complete sound.
		-- Give building its abilities

		-- Let the building cast abilities
		unit:RemoveModifierByName("modifier_construction")

		-- Remove item_building_cancel
        for i=0,5 do
            local item = unit:GetItemInSlot(i)
            if item then
            	print(i,item:GetAbilityName())
            	if item:GetAbilityName() == "item_building_cancel" then
            		item:RemoveSelf()
                end
            end
        end

		local caster = keys.caster
		local hero = caster:GetPlayerOwner():GetAssignedHero()
		local playerID = hero:GetPlayerID()
		local player = PlayerResource:GetPlayer(playerID)
		local building_name = unit:GetUnitName()
		local builders = {}
		if unit.builder then
			table.insert(builders, unit.builder)
		elseif unit.units_repairing then
			builders = unit.units_repairing
		end

		-- When building one of the lumber-only buildings, send the builder(s) to auto-gather lumber after the building is done
		Timers:CreateTimer(0.5, function() 
		if builders and building_name == "human_lumber_mill" or building_name == "orc_war_mill" then
			print("Sending "..#builders.." builders to gather lumber after finishing "..building_name)
			
			for k,builder in pairs(builders) do
				print("Builder ",k)
				local race = GetUnitRace(builder)
				local gather_ability = builder:FindAbilityByName(race.."_gather")
				if gather_ability and gather_ability:IsFullyCastable() and not gather_ability:IsHidden() then
	                local empty_tree = FindEmptyNavigableTreeNearby(builder, unit:GetAbsOrigin(), 2000)
	                if empty_tree then
	                	print(" gathering")
	                    local tree_index = GetTreeIdForEntityIndex( empty_tree:GetEntityIndex() )
	                    ExecuteOrderFromTable({ UnitIndex = builder:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
	                end
	            elseif gather_ability and gather_ability:IsFullyCastable() and gather_ability:IsHidden() then
	                -- Can the unit still gather more resources?
	                if (builder.lumber_gathered and builder.lumber_gathered < 10) and not builder:HasModifier("modifier_returning_gold") then
	                    local empty_tree = FindEmptyNavigableTreeNearby(builder, unit:GetAbsOrigin(), 2000)
	                    if empty_tree then
	                    	print(" gathering")
	                        local tree_index = GetTreeIdForEntityIndex( empty_tree:GetEntityIndex() )
	                        builder:SwapAbilities(race.."_gather", race.."_return_resources", true, false)
	                        ExecuteOrderFromTable({ UnitIndex = builder:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_TARGET_TREE, TargetIndex = tree_index, AbilityIndex = gather_ability:GetEntityIndex(), Queue = false})
	                    end
	                else
	                    -- Return
	                    print(" returning")
	                    local return_ability = builder:FindAbilityByName(race.."_return_resources")
	                    local empty_tree = FindEmptyNavigableTreeNearby(builder, point, TREE_RADIUS)
	                    builder.target_tree = empty_tree --The new selected tree
	                    ExecuteOrderFromTable({ UnitIndex = builder:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = return_ability:GetEntityIndex(), Queue = false})
	                end
	            end
	        end
            return false
		end
		end)

		-- Add 1 to the player building tracking table for that name
		if not player.buildings[building_name] then
			player.buildings[building_name] = 1
		else
			player.buildings[building_name] = player.buildings[building_name] + 1
		end

		-- Add blight if its an undead building
		if IsUndead(unit) then
			local size = "small"
			if unit:GetUnitName() == "undead_necropolis" then
				radius = "large"
			end
			CreateBlight(unit:GetAbsOrigin(), radius)
		end

		-- Add to the Food Limit if possible
		local food_produced = GetFoodProduced(unit)
		if food_produced ~= 0 then
			ModifyFoodLimit(player, food_produced)
		end

		-- Update the abilities of the builders and buildings
    	for k,units in pairs(player.units) do
    		CheckAbilityRequirements( units, player )
    	end

    	for k,structure in pairs(player.structures) do
    		CheckAbilityRequirements( structure, player )
    	end

	end)

	-- These callbacks will only fire when the state between below half health/above half health changes.
	-- i.e. it won't fire multiple times unnecessarily.
	keys:OnBelowHalfHealth(function(unit)
		print(unit:GetUnitName() .. " is below half health.")
				
		local item = CreateItem("item_apply_modifiers", nil, nil)
    	item:ApplyDataDrivenModifier(unit, unit, "modifier_onfire", {})
    	item = nil

	end)

	keys:OnAboveHalfHealth(function(unit)
		print(unit:GetUnitName() .. " is above half health.")

		unit:RemoveModifierByName("modifier_onfire")
		
	end)

	--[[keys:OnCanceled(function()
		print(keys.ability:GetAbilityName() .. " was canceled.")
	end)]]

end

function create_building_entity( keys )
	BuildingHelper:InitializeBuildingEntity(keys)
end

function building_canceled( keys )
	BuildingHelper:CancelBuilding(keys)
end

function builder_queue( keys )
	local ability = keys.ability
  local caster = keys.caster  

  if caster.ProcessingBuilding ~= nil then
    -- caster is probably a builder, stop them
    player = PlayerResource:GetPlayer(caster:GetMainControllingPlayer())
    player.activeBuilding = nil
    if player.activeBuilder and IsValidEntity(player.activeBuilder) then
    	player.activeBuilder:ClearQueue()
    	player.activeBuilder:Stop()
    	player.activeBuilder.ProcessingBuilding = false
    end
  end
end