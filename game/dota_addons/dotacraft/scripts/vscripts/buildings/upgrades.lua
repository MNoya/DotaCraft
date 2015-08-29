--[[
	Replaces the building to the upgraded unit name
]]--
function UpgradeBuilding( event )
	local caster = event.caster
	local new_unit = event.UnitName
	local position = caster:GetAbsOrigin()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	local player = PlayerResource:GetPlayer(playerID)
	local currentHealthPercentage = caster:GetHealthPercent() * 0.01

	-- Keep the gridnav blockers, hull radius and orientation
	local blockers = caster.blockers
	local hull_radius = caster:GetHullRadius()
	local flag = caster.flag
	local angle = caster:GetAngles()

    -- New building
	local building = BuildingHelper:PlaceBuilding(player, new_unit, position, false, 0) 
	building.blockers = blockers
	building:SetHullRadius(hull_radius)
	building:SetAngles(0, -angle.y, 0)

	-- Keep the rally flag reference if there is one
    if IsValidEntity(flag) then
		building.flag = flag
	end

	-- If the building to ugprade is selected, change the selection to the new one
	if IsCurrentlySelected(caster) then
		AddUnitToSelection(building)
	end

	-- If the upgraded building is a city center, update the city_center_level if required
	if IsCityCenter(building) then
		local level = building:GetLevel()
		if level > player.city_center_level then
			player.city_center_level = level
		end
	end

	-- Remove the old building from the structures list
	if IsValidEntity(caster) then
		local buildingIndex = getIndex(player.structures, caster)
        table.remove(player.structures, buildingIndex)
		
		-- Remove old building entity
		caster:RemoveSelf()
    end

	local newRelativeHP = building:GetMaxHealth() * currentHealthPercentage
	if newRelativeHP == 0 then newRelativeHP = 1 end --just incase rounding goes wrong
	building:SetHealth(newRelativeHP)

	-- Update the references to the new building
	if entangled_gold_mine then
		entangled_gold_mine.city_center = building
    	building.entangled_gold_mine = entangled_gold_mine
    end

	-- Add 1 to the buildings list for that name. The old name still remains
	if not player.buildings[new_unit] then
		player.buildings[new_unit] = 1
	else
		player.buildings[new_unit] = player.buildings[new_unit] + 1
	end

	-- Add the new building to the structures list
	table.insert(player.structures, building)

	-- Update the abilities of the units and structures
	for k,unit in pairs(player.units) do
		CheckAbilityRequirements( unit, player )
	end

	for k,structure in pairs(player.structures) do
		CheckAbilityRequirements( structure, player )
	end

	-- Apply the current level of Masonry to the newly upgraded building
	local masonry_rank = GetCurrentResearchRank(player, "human_research_masonry1")
	if masonry_rank and masonry_rank > 0 then
		print("Applying masonry rank "..masonry_rank.." to this building upgrade")
		UpdateUnitUpgrades( building, player, "human_research_masonry"..masonry_rank )
	end
end

--[[
	Disable any queue-able ability that the building could have, because the caster will be removed when the channel ends
	A modifier from the ability can also be passed here to attach particle effects
]]--
function StartUpgrade( event )	
	local caster = event.caster
	local ability = event.ability
	local modifier_name = event.ModifierName
	local abilities = {}

	-- Check to not disable when the queue was full
	if #caster.queue < 5 then

		-- Iterate through abilities marking those to disable
		for i=0,15 do
			local abil = caster:GetAbilityByIndex(i)
			if abil then
				local ability_name = abil:GetName()

				-- Abilities to hide include the strings train_ and research_, the rest remain available
				if string.match(ability_name, "train_") or string.match(ability_name, "research_") then
					table.insert(abilities, abil)
				end
			end
		end

		-- Keep the references to enable if the upgrade gets canceled
		caster.disabled_abilities = abilities

		for k,disable_ability in pairs(abilities) do
			disable_ability:SetHidden(true)		
		end

		-- Pass a modifier with particle(s) of choice to show that the building is upgrading. Remove it on CancelUpgrade
		if modifier_name then
			ability:ApplyDataDrivenModifier(caster, caster, modifier_name, {})
			caster.upgrade_modifier = modifier_name
		end

	end

	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	FireGameEvent( 'ability_values_force_check', { player_ID = playerID })
end

--[[
	Replaces the building to the upgraded unit name
]]--
function CancelUpgrade( event )
	
	local caster = event.caster
	local abilities = caster.disabled_abilities

	for k,ability in pairs(abilities) do
		ability:SetHidden(false)		
	end

	local upgrade_modifier = caster.upgrade_modifier
	if upgrade_modifier and caster:HasModifier(upgrade_modifier) then
		caster:RemoveModifierByName(upgrade_modifier)
	end

	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	FireGameEvent( 'ability_values_force_check', { player_ID = playerID })
end

-- Forces an ability to level 0
function SetLevel0( event )
	local ability = event.ability
	if ability:GetLevel() == 1 then
		ability:SetLevel(0)	
	end
end

-- Hides an ability
function HideAbility( event )
	local ability = event.ability
	ability:SetHidden(true)
end