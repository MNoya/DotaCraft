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