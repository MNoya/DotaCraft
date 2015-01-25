--[[
	Author:
	Date: 25.01.2015.
	Takes control over a unit
]]
function Charm( event )
	-- Variables
	local caster = event.caster
	local target = event.target

	print("Charm")

	-- Change ownership
	if target:GetLevel() < 6 then
		target:Stop()
        target:SetTeam( caster:GetTeamNumber() )
        target:SetOwner(caster)
        target:SetControllableByPlayer( caster:GetPlayerOwnerID(), true )
        target:RespawnUnit()
        target:SetHealth(target:GetHealth())
	end
end