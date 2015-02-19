--[[
	Author: Noya
	Date: 12.02.2015.
	Checks if there is enough custom resources to start the building, else stops.
]]
function CheckCustomResources( event )
	local caster = event.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	local player = PlayerResource:GetPlayer(playerID)
	local building_name = event.BuildingName
	local unit_table = GameRules.UnitKV[building_name]
	local lumber_cost = unit_table.LumberCost

	--DeepPrintTable(unit_table)

	if player.lumber < lumber_cost then
		caster:Interrupt()
		FireGameEvent( 'custom_error_show', { player_ID = playerID, _error = "Need more Lumber" } )		
	end
end


--[[
	Starts building
	Different behaviors:
		Human - Multiple Peasants can actively help in the construction, making it faster. If no peasants building, it stays at the same HP. Extra peasants use +gold/+lumber, counts as Repairing
		Orc - Single Peon, actively builds. Builder is hidden inside.
		NightElf - Wisp is hidden during the construction process. Ancient buildings will consume the unit.
		Undead - Building is queued and autobuilt without the Acolyte being there.

	Building being constructed can't be the same unit, or at least would need to be stunned/silenced to deny spell casting while its being constructed.
	Buildings start at 10% HP. 
	The ghost building and cost is used just after the spell is queued (= no AbilityCastRange) but the building only starts when the builder comes near/inside.

]]
function Build( event )
	local caster = event.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	local building_name = event.BuildingName
	print("Start building "..building_name)

	-- Get key values
	local unit_table = GameRules.UnitKV[building_name]
	local build_time = unit_table.BuildTime
	local gold_cost = unit_table.GoldCost
	local lumber_cost = unit_table.LumberCost

	local point = BuildingHelper:AddBuildingToGrid( event.target_points[1], 2, hero )
	if point ~= -1 then
		local building = CreateUnitByName(building_name, point, false, nil, nil, caster:GetTeam())
		if building:HasModifier("modifier_invulnerable") then
			building:RemoveModifierByName("modifier_invulnerable")
		end

		BuildingHelper:AddBuilding(building)
		building:Pack()
		building:UpdateHealth(20.0,true,.85)
		building:SetControllableByPlayer( playerID, true )
		building:SetOwner( hero )

		-- Pay custom resource
		hero.lumber = hero.lumber - lumber_cost
	else
		--Fire a game event here and use Actionscript to let the player know he can't place a building at this spot.
		FireGameEvent( 'custom_error_show', { player_ID = playerID, _error = "You can't build there" } )

		-- Refund the gold cost.
		hero:ModifyGold(gold_cost, false, 0)
	end
end

-- Refunding: 75% of the cost.