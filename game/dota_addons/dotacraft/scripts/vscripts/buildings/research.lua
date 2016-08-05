-- Adds the search to the player research list
function ResearchComplete( event )
	local caster = event.caster
	local playerID = caster:GetPlayerOwnerID()
	local ability = event.ability
	local ability_name = ability:GetAbilityName()
	local research_name = Upgrades:GetBaseResearchName(ability_name)

	--print("ResearchComplete",research_name,ability:GetLevel())
	Players:SetResearchLevel(playerID, research_name, ability:GetLevel())

	--[[print("Player current upgrades list:")
	DeepPrintTable(Players:GetUpgradeTable(playerID))
	print("==========================")]]
	
	-- Go through all the upgradeable units and upgrade with the research
	-- These are just abilities set as lvl 0 _disabled until the tech is researched
	-- Some show as passives, while wc3 showed them as 0-1-2-3 ranks on the damage/armor indicator	
	local playerUnits = Players:GetUnits(playerID)
	for _,unit in pairs(playerUnits) do
		CheckAbilityRequirements( unit, playerID )
		UpdateUnitUpgrades(unit, playerID, research_name)
	end

	-- Also, on the buildings that have the upgrade, disable the upgrade and/or apply the next rank.
	local playerStructures = Players:GetStructures(playerID)
	for _,structure in pairs(playerStructures) do
		CheckAbilityRequirements( structure, playerID )
		UpdateUnitUpgrades(structure, playerID, research_name)
	end

	Scores:IncrementTechPercentage( playerID )
end

-- When queing a research, disable it to prevent from being queued again
function DisableResearch( event )
	local ability = event.ability
	ability:SetHidden(true)
end

-- Reenable the parent ability without item_ in its name
function ReEnableResearch( event )
	local caster = event.caster
	local ability = event.ability
	local item_name = ability:GetAbilityName()
	local research_ability_name = string.gsub(item_name, "item_", "")

	local research_ability = caster:FindAbilityByName(research_ability_name)
	research_ability:SetHidden(false)
end