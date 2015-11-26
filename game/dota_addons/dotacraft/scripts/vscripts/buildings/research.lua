-- Adds the search to the player research list
function ResearchComplete( event )
	local caster = event.caster
	local playerID = caster:GetPlayerOwnerID()
	local ability = event.ability
	local research_name = ability:GetAbilityName()

	-- It shouldn't be possible to research the same upgrade more than once.
	local upgrades = Players:GetUpgradeTable(playerID)
	upgrades[research_name] = 1

	print("Player current upgrades list:")
	DeepPrintTable(upgrades)
	print("==========================")
	
	-- Go through all the upgradeable units and upgrade with the research
	-- These are just abilities set as lvl 0 _disabled until the tech is researched
	-- Some show as passives, while wc3 showed them as 0-1-2-3 ranks on the damage/armor indicator	
	local playerUnits = Players:GetUnits(playerID)
	for _,unit in pairs(playerUnits) do
		CheckAbilityRequirements( unit, playerID )
		UpdateUnitUpgrades( unit, playerID, research_name)
	end

	-- Also, on the buildings that have the upgrade, disable the upgrade and/or apply the next rank.
	local playerStructures = Players:GetStructures(playerID)
	for _,structure in pairs(playerStructures) do
		CheckAbilityRequirements( structure, playerID )
		UpdateUnitUpgrades( structure, playerID, research_name)
	end
end

function LumberResearchComplete( event )
	local player = event.caster:GetPlayerOwner()
	local level = event.Level
	local extra_lumber_carried = event.ability:GetLevelSpecialValueFor("extra_lumber_carried", level - 1)

	player.LumberCarried = 10 + extra_lumber_carried
end


-- When queing a research, disable it to prevent from being queued again
function DisableResearch( event )
	local ability = event.ability
	print("Set Hidden "..ability:GetAbilityName())
	ability:SetHidden(true)

	local caster = event.caster
	local hero = caster:GetOwner()
	local pID = hero:GetPlayerID()
	print("##Firing ability_values_force_check for "..caster:GetUnitName())
	FireGameEvent( 'ability_values_force_check', { player_ID = pID })
end

-- Reenable the parent ability without item_ in its name
function ReEnableResearch( event )
	local caster = event.caster
	local ability = event.ability
	local item_name = ability:GetAbilityName()
	local research_ability_name = string.gsub(item_name, "item_", "")

	print("Unhide "..research_ability_name)
	local research_ability = caster:FindAbilityByName(research_ability_name)
	research_ability:SetHidden(false)

	local caster = event.caster
	local hero = caster:GetOwner()
	local pID = hero:GetPlayerID()
	print("##Firing ability_values_force_check for "..caster:GetUnitName())
	FireGameEvent( 'ability_values_force_check', { player_ID = pID })
end