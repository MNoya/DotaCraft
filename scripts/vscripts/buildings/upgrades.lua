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

	caster:RemoveSelf()
	local building = CreateUnitByName(new_unit, position, true, hero, hero, hero:GetTeamNumber())
	building:SetOwner(hero)
	building:SetControllableByPlayer(playerID, true)
	building:SetAbsOrigin(position)
	building:RemoveModifierByName("modifier_invulnerable")

	if not player.buildings[new_unit] then
		player.buildings[new_unit] = 1
	else
		player.buildings[new_unit] = player.buildings[new_unit] + 1
	end
end

-- Hides an ability by its name
function DisableAbility( event )
	
	local ability_name = event.AbilityName
	local caster = event.caster

	print("Disabling ability"..ability_name)

	local ability = caster:FindAbilityByName(ability_name)
	ability:SetHidden(true)
end

-- Shows an ability by its name
function EnableAbility( event )
	
	local ability_name = event.AbilityName
	local caster = event.caster

	print("Enabling ability"..ability_name)

	local ability = caster:FindAbilityByName(ability_name)
	ability:SetHidden(false)
end