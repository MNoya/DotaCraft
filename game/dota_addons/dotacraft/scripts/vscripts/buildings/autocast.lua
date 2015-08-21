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
	if ability and ability:GetAutoCastState() and not caster:HasModifier("modifier_construction") then
		if not IsChanneling( caster ) then
			if ability:IsOwnersGoldEnough( player ) and #caster.queue < 5 then
				caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())
				print("Autocasting ",ability:GetAbilityName())
			end
		end
	end	
end