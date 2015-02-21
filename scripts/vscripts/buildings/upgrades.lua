--[[
	Author: Noya
	Date: 19.02.2015.
	Replaces the building to the upgraded unit name
]]
function UpgradeBuilding( event )
	local caster = event.caster
	local new_unit = event.UnitName
	local position = caster:GetAbsOrigin()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	local player = PlayerResource:GetPlayer(playerID)

	-- Remove the old building from the structures list and from the game
	local buildingIndex = getIndex(player.structures, caster)
	if IsValidEntity(caster) then
        table.remove(player.structures, buildingIndex)

        -- Remove the rally flag if there is one
        if caster.flag then
			caster.flag:RemoveSelf()
		end

        caster:RemoveSelf()
    end

	local building = CreateUnitByName(new_unit, position, true, hero, hero, hero:GetTeamNumber())
	building:SetOwner(hero)
	building:SetControllableByPlayer(playerID, true)
	building:SetAbsOrigin(position)
	building:RemoveModifierByName("modifier_invulnerable")

	-- Add 1 to the buildings list for that name. The old name still remains
	if not player.buildings[new_unit] then
		player.buildings[new_unit] = 1
	else
		player.buildings[new_unit] = player.buildings[new_unit] + 1
	end

	-- Add the new building to the structures list
	table.insert(player.structures, building)

	print("Building upgrade complete. Player current building list:")
	DeepPrintTable(player.buildings)
	print("==========================")

	-- Update the abilities of the units and structures
	for k,unit in pairs(player.units) do
		CheckAbilityRequirements( unit, player )
	end

	for k,structure in pairs(player.structures) do
		CheckAbilityRequirements( structure, player )
	end

end



-- Disable any queue-able ability that the building could have, because the caster will be removed after the channel ends.
function DisableAbilities( event )
	
	local caster = event.caster
	local ability = event.ability
	local abilities = { "human_train_peasant", 
						"human_train_keep",
						"human_train_castle" }

	-- Check to not disable when the queue was full
	if #caster.queue < 5 then

		-- Harcoded as fuck particle attachment
		if not caster:HasModifier("modifier_building_particle") then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_building_particle", {})
		else
			-- Reapply
			caster:RemoveModifierByName("modifier_building_particle")
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_building_particle", {})
		end

		for i=1,#abilities do
			local ability = caster:FindAbilityByName(abilities[i])
			if ability then
				ability:SetHidden(true)
			end			
		end
	end
end

-- Shows abilities from a list
function EnableAbilities( event )
	
	local caster = event.caster
	local abilities = { "human_train_peasant", 
						"human_train_keep",
						"human_train_castle" }

	for i=1,#abilities do
		local ability = caster:FindAbilityByName(abilities[i])
		if ability then
			ability:SetHidden(false)
		end
	end
end


-- Forces an ability to level 0
function SetLevel0( event )
	local ability = event.ability
	if ability:GetLevel() == 1 then
		ability:SetLevel(0)	
	end
end