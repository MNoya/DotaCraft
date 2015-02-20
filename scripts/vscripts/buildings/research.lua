--[[
	Author: Noya
	Date: 20.02.2015.
	Adds the search to the player research list
]]
function ResearchComplete( event )
	local caster = event.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	local player = PlayerResource:GetPlayer(playerID)
	local ability = event.ability
	local research_name = ability:GetAbilityName()

	-- It shouldn't be possible to research the same upgrade more than once.
	player.upgrades[research_name] = 1

	print("==Current Research Table==")
	DeepPrintTable(player.upgrades)
	print("==========================")

end


-- When queing a research, disable it to prevent from being queued again
function DisableResearch( event )
	local ability = event.ability
	print("Set Hidden "..ability:GetAbilityName())
	ability:SetHidden(true)

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
end