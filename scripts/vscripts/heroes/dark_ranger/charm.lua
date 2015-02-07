--[[
	Author:
	Date: 25.01.2015.
	Takes control over a unit
]]
function Charm( event )
	-- Variables
	local caster = event.caster
	local target = event.target
	local pID = caster:GetPlayerID()

	-- Change ownership
	if target:GetLevel() < 6 then
		print("Charm")
		target:Stop()
        target:SetTeam( caster:GetTeamNumber() )
        target:SetOwner(caster)
        target:SetControllableByPlayer( caster:GetPlayerOwnerID(), true )
        target:RespawnUnit()
        target:SetHealth(target:GetHealth())
	end
end


-- Denies cast on creeps higher than level 5, with a message
function CharmLevelCheck( event )
	local target = event.target
	local pID = event.caster:GetPlayerID()
	
	if target:GetLevel() > 5 then
		event.caster:Interrupt()
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Can't target creeps over level 5" } )
	end
end