function build( keys )
	BuildingHelper:AddBuilding(keys)
	keys:OnConstructionStarted(function(unit)
		print("Started construction of " .. unit:GetUnitName())
		-- Unit is the building be built.
		-- Play construction sound
		-- FindClearSpace for the builder

		-- Substract custom resource
		local caster = keys.caster
		local hero = caster:GetPlayerOwner():GetAssignedHero()
		local playerID = hero:GetPlayerID()
		local player = PlayerResource:GetPlayer(playerID)
		local building_name = unit:GetUnitName()

		local unit_table = GameRules.UnitKV[building_name]
		print(unit_table.LumberCost)
		player.lumber = player.lumber - unit_table.LumberCost
    	print("Lumber Spend. Player "..playerID.." is currently at " .. player.lumber)
    	FireGameEvent('cgm_player_lumber_changed', { player_ID = playerID, lumber = player.lumber })

    	-- Remove invulnerability on npc_dota_building baseclass
    	unit:RemoveModifierByName("modifier_invulnerable")


	end)

	keys:OnConstructionCompleted(function(unit)
		print("Completed construction of " .. unit:GetUnitName())
		-- Play construction complete sound.
		-- Give building its abilities

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

		-- Update the abilities of the builders
    	for k,builder in pairs(player.builders) do
    		print("=Checking Requirements on "..builder:GetUnitName()..k)
    		CheckAbilityRequirements( builder, player )
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







