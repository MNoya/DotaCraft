--[[
	Author: Noya
	Date: 20.02.2015.
	Adds the search to the player research list
]]
function ResearchComplete( event )
	local caster = event.caster
	local player = caster:GetPlayerOwner()
	local ability = event.ability
	local research_name = ability:GetAbilityName()

	-- It shouldn't be possible to research the same upgrade more than once.
	player.upgrades[research_name] = 1

	print("Player current upgrades list:")
	DeepPrintTable(player.upgrades)
	print("==========================")
	
	-- Upgrade 1 -> 2, if the research name contains "1"
	local name = nil
	local level = 0
	if string.find(research_name, "1") then
		name = string.gsub(research_name, "1" , "2")
		level = 2	

	-- Upgrade 2 -> 3, if the research name contains "1"
	elseif string.find(research_name, "2") then		
		name = string.gsub(research_name, "2" , "3")
		level = 3
	end

	if name then
		caster:AddAbility(name)
		local new_rank = caster:FindAbilityByName(name)
		if new_rank then
			new_rank:SetLevel(1)
			print("New rank "..level.." unlocked",name)
		else
			print("Upgrade at max rank "..level)
		end
	end

	-- Go through all the upgradeable units and upgrade with the research
	-- These are just abilities set as lvl 0 _disabled until the tech is researched
	-- Some show as passives, while wc3 showed them as 0-1-2-3 ranks on the damage/armor indicator
	--for _,unit in pairs(player.units) do
		CheckAbilityRequirements( caster, player )
	--end	

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

-- 