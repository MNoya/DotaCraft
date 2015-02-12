--[[
	Author: Noya
	Date: 11.02.2015.
	Handles the Autocast logic for buildings unit spawn
]]
function BuildingAutocast( event )
	local caster = event.caster
	local ability = event.ability
	local hero = caster:GetPlayerOwner()
	local player
	if hero then
		player = hero:GetPlayerID()
	end

	-- Get if the ability is on autocast mode and cast the ability if it doesn't have the modifier
	if ability:GetAutoCastState() then
		if not IsChanneling( caster ) then
			if ability:IsOwnersGoldEnough( player ) then
				caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())
				print("Autocasting ",ability:GetAbilityName())
			end
		end
	end	
end


-- Auxiliar function that goes through every ability and item, checking for any ability being channelled
function IsChanneling ( unit )
	
	for abilitySlot=0,15 do
		local ability = unit:GetAbilityByIndex(abilitySlot)
		if ability ~= nil and ability:IsChanneling() then 
			return true
		end
	end

	for itemSlot=0,5 do
		local item = unit:GetItemInSlot(itemSlot)
		if item ~= nil and item:IsChanneling() then
			return true
		end
	end

	return false
end