--[[
	Author: Noya
	Date: 11.02.2015.
	Creates a rally point flag for this unit, removing the old one if there was one
]]
function RefundUnitCost( event )
	local caster = event.caster
	local player = caster:GetPlayerOwner():GetPlayerID()
	local ability = event.ability
	local gold_cost = ability:GetGoldCost( ability:GetLevel() - 1 )

	PlayerResource:ModifyGold(player, gold_cost, false, 0)
	print("Refund ",gold_cost)
end