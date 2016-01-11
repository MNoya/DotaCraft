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
	local flag_type = caster.flag_type
	local angle = caster:GetAngles()

    -- New building
	local building = BuildingHelper:PlaceBuilding(player, new_unit, position, caster.construction_size, 0, 0)
	building.blockers = blockers
	building:SetHullRadius(hull_radius)
	building:SetAngles(0, angle.y, 0)

	-- Keep the rally flag reference if there is one
    building.flag = flag

	-- If the building to ugprade is selected, change the selection to the new one
	if IsCurrentlySelected(caster) then
		AddUnitToSelection(building)
	end

	 -- Add to the Food Limit if possible
    local old_food = GetFoodProduced(caster)
    local new_food = GetFoodProduced(building)
    if new_food ~= old_food then
        Players:ModifyFoodLimit(playerID, new_food - old_food)
    end
	
	-- If the upgraded building is a city center, update the city_center_level if required
	if IsCityCenter(building) then
		local level = building:GetLevel()
		local city_center_level = Players:GetCityLevel(playerID)
		if level > city_center_level then
			Players:SetCityCenterLevel( playerID, level )
		end
	end

	-- Remove the old building from the structures list
	local playerStructures = Players:GetStructures(playerID)
	if IsValidEntity(caster) then
		local buildingIndex = getIndex(playerStructures, caster)
        table.remove(playerStructures, buildingIndex)
		
		-- Remove old building entity
		caster:RemoveSelf()
    end

	local newRelativeHP = building:GetMaxHealth() * currentHealthPercentage
	if newRelativeHP == 0 then newRelativeHP = 1 end --just incase rounding goes wrong
	building:SetHealth(newRelativeHP)

	-- Update the references to the new building
	local entangled_gold_mine = caster.entangled_gold_mine
	if IsValidAlive(entangled_gold_mine) then
		entangled_gold_mine.city_center = building
    	building.entangled_gold_mine = caster.entangled_gold_mine
    	building:SwapAbilities("nightelf_entangle_gold_mine", "nightelf_entangle_gold_mine_passive", false, true)
    end

	-- Add 1 to the buildings list for that name. The old name still remains
	local buildingTable = Players:GetBuildingTable(playerID)
	if not buildingTable[new_unit] then
		buildingTable[new_unit] = 1
	else
		buildingTable[new_unit] = buildingTable[new_unit] + 1
	end

	-- Add the new building to the structures list
	Players:AddStructure(playerID, building)

	-- Update the abilities of the units and structures
	local playerUnits = Players:GetUnits(playerID)
	for k,unit in pairs(playerUnits) do
		CheckAbilityRequirements( unit, playerID )
	end

	for k,structure in pairs(playerStructures) do
		CheckAbilityRequirements( structure, playerID )
	end

	-- Apply the current level of Masonry to the newly upgraded building
	local masonry_rank = Players:GetCurrentResearchRank(playerID, "human_research_masonry1")
	if masonry_rank and masonry_rank > 0 then
		print("Applying masonry rank "..masonry_rank.." to this building upgrade")
		UpdateUnitUpgrades( building, playerID, "human_research_masonry"..masonry_rank )
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

	-- Units can't attack while upgrading
	caster.original_attack = caster:GetAttackCapability()
	caster:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)

	for k,disable_ability in pairs(abilities) do
		disable_ability:SetHidden(true)		
	end

	-- Pass a modifier with particle(s) of choice to show that the building is upgrading. Remove it on CancelUpgrade
	if modifier_name then
		ability:ApplyDataDrivenModifier(caster, caster, modifier_name, {})
		caster.upgrade_modifier = modifier_name
	end

	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	FireGameEvent( 'ability_values_force_check', { player_ID = playerID })
end

-- Resets any change done in StartUpgrade
function CancelUpgrade( event )
	local caster = event.caster
	local abilities = caster.disabled_abilities

	-- Give the unit their original attack capability
    caster:SetAttackCapability(caster.original_attack)

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