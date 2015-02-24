function build( keys )

	-- Checks if there is enough custom resources to start the building, else stop.
	local caster = keys.caster
	local ability_name = keys.ability:GetAbilityName()
	local AbilityKV = GameRules.AbilityKV
	local UnitKV = GameRules.UnitKV
	
	-- Handle the resource for item-ability build
	local building_name
	if keys.ItemUnitName then
		building_name = keys.ItemUnitName
	else
		building_name = AbilityKV[ability_name].UnitName --Building Helper value, could just be a parameter of the RunScript but w/e
	end

	local unit_table = UnitKV[building_name]
	local lumber_cost = unit_table.LumberCost

	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	local player = PlayerResource:GetPlayer(playerID)	

	print(playerID,player,building_name,unit_table,lumber_cost)

	if player.lumber < lumber_cost then
		FireGameEvent( 'custom_error_show', { player_ID = playerID, _error = "Need more Lumber" } )		
		return
	end

	BuildingHelper:AddBuilding(keys)
	keys:OnConstructionStarted(function(unit)
		print("Started construction of " .. unit:GetUnitName())
		-- Unit is the building be built.
		-- Play construction sound
		-- FindClearSpace for the builder

		player.lumber = player.lumber - lumber_cost
    	print("Lumber Spend. Player "..playerID.." is currently at " .. player.lumber)
    	FireGameEvent('cgm_player_lumber_changed', { player_ID = playerID, lumber = player.lumber })

    	-- Remove invulnerability on npc_dota_building baseclass
    	unit:RemoveModifierByName("modifier_invulnerable")

    	-- Silence the building. Temp solution for not having building_abilities.kv and having them in the npc_unit_custom instead.
    	local item = CreateItem("item_apply_modifiers", nil, nil)
    	item:ApplyDataDrivenModifier(caster, unit, "modifier_construction", {})

    	-- Check the abilities of this building, disabling those that don't meet the requirements
    	print("=Checking Requirements on "..unit:GetUnitName())
    	CheckAbilityRequirements( unit, player )

    	-- Some units with multiple upgrade ranks might require an additional ability requirement loop because I suck at programming
    	if unit:GetUnitName() == "human_lumber_mill" or unit:GetUnitName() == "human_blacksmith" then
    		CheckAbilityRequirements( unit, player )
    	end


	end)

	keys:OnBuildingPosChosen(function(vPos)
		--print("OnBuildingPosChosen")
		-- in WC3 some build sound was played here.
	end)

	keys:OnConstructionCompleted(function(unit)
		print("[BH] Completed construction of " .. unit:GetUnitName())
		-- Play construction complete sound.
		-- Give building its abilities

		-- Let the building cast abilities
		unit:RemoveModifierByName("modifier_construction")

		local caster = keys.caster
		local hero = caster:GetPlayerOwner():GetAssignedHero()
		local playerID = hero:GetPlayerID()
		local player = PlayerResource:GetPlayer(playerID)
		local building_name = unit:GetUnitName()

		-- Add 1 to the player building tracking table for that name
		if not player.buildings[building_name] then
			player.buildings[building_name] = 1
		else
			player.buildings[building_name] = player.buildings[building_name] + 1
		end

		-- Add the building handle to the list of constructed structures
		table.insert(player.structures, unit)

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
	end)

	keys:OnAboveHalfHealth(function(unit)
		print(unit:GetUnitName() .. " is above half health.")
	end)

	--[[keys:OnCanceled(function()
		print(keys.ability:GetAbilityName() .. " was canceled.")
	end)]]

	-- Have a fire effect when the building goes below 50% health.
	-- It will turn off it building goes above 50% health again.
	keys:EnableFireEffect("modifier_jakiro_liquid_fire_burn")
end

function create_building_entity( keys )
	BuildingHelper:InitializeBuildingEntity(keys)
end

function building_canceled( keys )
	BuildingHelper:CancelBuilding(keys)
end






