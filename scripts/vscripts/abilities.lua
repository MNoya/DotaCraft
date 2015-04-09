function build( keys )

	-- Checks if there is enough custom resources to start the building, else stop.
	local caster = keys.caster
	local ability = keys.ability
	local ability_name = ability:GetAbilityName()
	local AbilityKV = GameRules.AbilityKV
	local UnitKV = GameRules.UnitKV

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

	if not PlayerHasEnoughLumber( player, lumber_cost ) then
		return
	end

	BuildingHelper:AddBuilding(keys)
	keys:OnConstructionStarted(function(unit)
		print("Started construction of " .. unit:GetUnitName())
		-- Unit is the building be built.
		-- Play construction sound

		-- FindClearSpace for the builder
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		caster:AddNewModifier(caster, nil, "modifier_phased", {duration=0.03})

    	ModifyLumber( player, -lumber_cost)

    	-- Remove invulnerability on npc_dota_building baseclass
    	unit:RemoveModifierByName("modifier_invulnerable")

    	-- Silence the building. Temp solution for not having building_abilities.kv and having them in the npc_unit_custom instead.
    	local item = CreateItem("item_apply_modifiers", nil, nil)
    	item:ApplyDataDrivenModifier(caster, unit, "modifier_construction", {})
    	item = nil

    	-- Check the abilities of this building, disabling those that don't meet the requirements
    	--print("=Checking Requirements on "..unit:GetUnitName())
    	CheckAbilityRequirements( unit, player )

    	--[[ Some units with multiple upgrade ranks might require an additional ability requirement loop because I suck at programming
    	if unit:GetUnitName() == "human_lumber_mill" or unit:GetUnitName() == "human_blacksmith" then
    		CheckAbilityRequirements( unit, player )
    	end]]

    	-- Apply the current level of Masonry to the newly upgraded building
		local masonry_rank = GetCurrentResearchRank(player, "human_research_masonry1")
		if masonry_rank and masonry_rank > 0 then
			print("Applying masonry rank "..masonry_rank.." to this building construction")
			UpdateUnitUpgrades( unit, player, "human_research_masonry"..masonry_rank )
		end

		-- Add the building handle to the list of structures
		table.insert(player.structures, unit)


	end)

	keys:OnBuildingPosChosen(function(vPos)
		--print("OnBuildingPosChosen")
		-- in WC3 some build sound was played here.

		local hull = unit_table.CollisionSize*2
		local units = FindUnitsInRadius(caster:GetTeamNumber(), vPos, nil, hull, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)

		-- Move the units away from the building place
		for _,unit in pairs(units) do
			if unit ~= caster then
				print(unit:GetUnitName())
				local front_position = unit:GetAbsOrigin() + unit:GetForwardVector() * hull
				ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = front_position, Queue = false})
				unit:AddNewModifier(caster, nil, "modifier_phased", {duration=1})
			end
		end

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
	print("create_building_entity")
	BuildingHelper:InitializeBuildingEntity(keys)
end

function building_canceled( keys )
	BuildingHelper:CancelBuilding(keys)
end






