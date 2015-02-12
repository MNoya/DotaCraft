--[[
	Some tips:
	Put BuildingHelper:BlockGridNavSquares(nMapLength) in your InitGameMode function.
	Remember to call building:RemoveBuilding before the building dies (or in the entity_killed event) to re-open the closed squares.
	If units are getting stuck put "BoundsHullName"   "DOTA_HULL_SIZE_TOWER" for buildings in npc_units_custom.txt
]]

BUILD_TIME=1.0

function getBuildingPoint(keys)
	local point = BuildingHelper:AddBuildingToGrid(keys.target_points[1], 2, keys.caster)
	if point ~= -1 then
		local farm = CreateUnitByName("npc_normal_farm", point, false, nil, nil, keys.caster:GetTeam())
		BuildingHelper:AddBuilding(farm)
		farm:Pack()
		farm:UpdateHealth(BUILD_TIME,true,.85)
		farm:SetControllableByPlayer( keys.caster:GetPlayerID(), true )
	else
		--Fire a game event here and use Actionscript to let the player know he can't place a building at this spot.
	end
end

function getHardFarmPoint(keys)
	local caster = keys.caster
	local point = BuildingHelper:AddBuildingToGrid(keys.target_points[1], 4, caster)
	if point == -1 then
		-- Refund the cost.
		caster:SetGold(caster:GetGold()+HARD_FARM_COST, false)
		--Fire a game event here and use Actionscript to let the player know he can't place a building at this spot.
		return
	else
		caster:SetGold(caster:GetGold()-5, false)
		local farm = CreateUnitByName("npc_hard_farm", point, false, nil, nil, caster:GetTeam())
		BuildingHelper:AddBuilding(farm)
		farm:UpdateHealth(BUILD_TIME,true,.8)
		farm:SetControllableByPlayer( caster:GetPlayerID(), true )
	end
end
