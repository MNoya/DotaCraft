--[[
	Building Helper for RTS-style and tower defense maps in Dota 2.
	Developed by Myll
	Version: 0.5
	Credits to Ash47 and BMD for timers.lua.
	Please give credit in your work if you use this. Thanks, and happy modding!
]]

BUILDINGHELPER_THINK = 0.03
GRIDNAV_SQUARES = {}
BUILDING_SQUARES = {}
BH_UNITS = {}
FORCE_UNITS_AWAY = false
UsePathingMap = false
AUTO_SET_HULL = true
BHGlobalDummySet = false
PACK_ENABLED = false
BH_Z=166
FIRE_EFFECTS_ENABLED = true

-- Circle packing math.
BH_A = math.pow(2,.5) --multi this by rad of building
BH_cos45 = math.pow(.5,.5) -- cos(45)

BuildingHelper = {}
BuildingGhostAbilities = {}


function BuildingHelper:Init(  )
	local abilities = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
	local items = LoadKeyValues("scripts/npc/npc_items_custom.txt")
	--PrintTable(abilities)
	for abil_name,abil_info in pairs(abilities) do
		if type(abil_info) == "table" and tostring(abil_info["UseBuildingGhost"]) == "1" then
			local modelVal = abil_info["BuildingGhostModel"]
			if modelVal ~= nil then
				BuildingGhostAbilities[tostring(abil_name)] = {["model"] = tostring(modelVal), ["toggle"] = -1}
			else
				BuildingGhostAbilities[tostring(abil_name)] = {["toggle"] = -1}
			end
		end
	end
	-- abils and items can't have the same name or the item will override the ability.
	for abil_name,abil_info in pairs(items) do
		if type(abil_info) == "table" and tostring(abil_info["UseBuildingGhost"]) == "1" then
			local modelVal = abil_info["BuildingGhostModel"]
			if modelVal ~= nil then
				BuildingGhostAbilities[tostring(abil_name)] = {["model"] = tostring(modelVal), ["toggle"] = -1}
			else
				BuildingGhostAbilities[tostring(abil_name)] = {["toggle"] = -1}
			end
		end
	end
	--print("BuildingGhostAbilities: ")
	--PrintTable(BuildingGhostAbilities)
end

-- nMapLength is 16384 if you're using the tile editor.
function BuildingHelper:BlockGridNavSquares(nMapLength)
	local halfLength = nMapLength/2
	local gridnavCount = 0
	-- Check the center of each square on the map to see if it's blocked by the GridNav.
	for x=-halfLength+32, halfLength-32, 64 do
		for y=halfLength-32, -halfLength+32,-64 do
			if GridNav:IsTraversable(Vector(x,y,0)) == false or GridNav:IsBlocked(Vector(x,y,0)) then
				GRIDNAV_SQUARES[VectorString(Vector(x,y,0))] = true
				gridnavCount=gridnavCount+1
			end
		end
	end
	--print("Total GridNav squares added: " .. gridnavCount)
end

function BuildingHelper:BlockRectangularArea(leftBorderX, rightBorderX, topBorderY, bottomBorderY)
	if leftBorderX%64 ~= 0 or rightBorderX%64 ~= 0 or topBorderY%64 ~= 0 or bottomBorderY%64 ~= 0 then
		print("[BuildingHelper] Error in BlockRectangularArea. One of the values does not divide evenly into 64.")
		return
	end
	local blockedCount = 0
	for x=leftBorderX+32, rightBorderX-32, 64 do
		for y=topBorderY-32, bottomBorderY+32,-64 do
			GRIDNAV_SQUARES[VectorString(Vector(x,y,0))] = true
			blockedCount=blockedCount+1
		end
	end
end
--[[ TODO: make BlockRectangularArea like DebugDrawBox.
function BuildingHelper:BlockRectangularArea(vCenter, vMin, vMax)
	local leftBorderX = vCenter.x-vMin.x

	if leftBorderX%64 ~= 0 or rightBorderX%64 ~= 0 or topBorderY%64 ~= 0 or bottomBorderY%64 ~= 0 then
		print("[BuildingHelper] Error in BlockRectangularArea. One of the values does not divide evenly into 64.")
		return
	end
	local blockedCount = 0
	for x=leftBorderX+32, rightBorderX-32, 64 do
		for y=topBorderY-32, bottomBorderY+32,-64 do
			GRIDNAV_SQUARES[VectorString(Vector(x,y,0))] = true
			blockedCount=blockedCount+1
		end
	end
end]]

function BuildingHelper:SetForceUnitsAway(bForceAway)
	FORCE_UNITS_AWAY=bForceAway
end

function BuildingHelper:DisableFireEffects(bDisableFireEffects)
	if bDisableFireEffects then
		FIRE_EFFECTS_ENABLED = false
	else
		FIRE_EFFECTS_ENABLED = true
	end
end

function BuildingHelper:SetPacking(bPacking)
	if not bPacking then
		PACK_ENABLED = false
	else
		PACK_ENABLED = true
		AUTO_SET_HULL = true
	end
end

function BuildingHelper:UsePathingMap(bUsePathingMap)
	if not bUsePathingMap then
		UsePathingMap = false
	else
		UsePathingMap = true
	end
end

-- Determines the squares that a unit is occupying.
function BuildingHelper:AddUnit(unit, bHasBuildingGhostAbilities)

	if bHasBuildingGhostAbilities then
		Timers:CreateTimer(BUILDINGHELPER_THINK, function()
			-- Iterate through everything to get the building ghost abils.
			for i=0, hero:GetAbilityCount()-1 do
				local abil = hero:GetAbilityByIndex(i)
				if abil ~= nil then
					if BuildingGhostAbilities[abil:GetAbilityName()] ~= nil then
						-- This is a building ghost abil on this unit.

					end
				end
			end
		end)
	end

	-- Remove the unit if it was already added.

	unit.bGeneratePathingMap = false
	unit.vPathingMap = {}
	unit.bNeedsToJump=false
	unit.bCantBeBuiltOn = true
	unit.fCustomRadius = unit:GetHullRadius()
	unit.bForceAway = false
	unit.bPathingMapGenerated = false
	unit.bhID = DoUniqueString("bhID")

	-- Set the id to the playerID if it's a player's hero.
	if unit:IsHero() and unit:GetOwner() ~= nil then
		unit.bhID = unit:GetPlayerID()
	end
	BH_UNITS[unit.bhID] = unit

	function unit:SetCustomRadius(fRadius)
		unit.fCustomRadius = fRadius
	end
	
	function unit:GetCustomRadius()
		return unit.fCustomRadius
	end
	
	function unit:GeneratePathingMap()
		local pathmap = {}
		local length = snapToGrid64(unit.fCustomRadius)
		length = length+128
		local c = unit:GetAbsOrigin()
		local x2 = snapToGrid64(c.x)
		local y2 = snapToGrid64(c.y)
		local unitRect = makeBoundingRect(x2-length, x2+length, y2+length, y2-length)
		local xs = {}
		local ys = {}
		for a=0,2*3.14,3.14/10 do
			table.insert(xs, math.cos(a)*unit.fCustomRadius+c.x)
			table.insert(ys, math.sin(a)*unit.fCustomRadius+c.y)
		end
		
		local pathmapCount=0
		for i=1, #xs do
			-- Check if this boundary circle point is inside any square in the list.
			for x=unitRect.leftBorderX+32,unitRect.rightBorderX-32,64 do
				for y=unitRect.topBorderY-32,unitRect.bottomBorderY+32,-64 do
					if (xs[i] >= x-32 and xs[i] <= x+32) and (ys[i] >= y-32 and ys[i] <= y+32) then
						if pathmap[VectorString(Vector(x,y,0))] ~= true then
							--BuildingHelper:PrintSquareFromCenterPointShort(Vector(x,y,0))
							pathmapCount=pathmapCount+1
							pathmap[VectorString(Vector(x,y,0))]=true
						end
					end
				end
			end
		end
		unit.vPathingMap = pathmap
		unit.bPathingMapGenerated = true
		return pathmap
	end
end

function BuildingHelper:AddPlayerHeroes()
	-- Add every player's hero to BH_UNITS if it's not already.
	local heroes = HeroList:GetAllHeroes()
	for i,v in ipairs(heroes) do
		-- if it's a player's hero
		if v:GetOwner() ~= nil then
			BuildingHelper:AddUnit(v)
		end
	end
end

function BuildingHelper:RemoveUnit(unit)
	if unit.bhID == nil then
		-- unit was never added.
		return
	end
	BH_UNITS[unit.bhID] = nil
end

function BuildingHelper:AutoSetHull(bAutoSetHull)
	if not bAutoSetHull then
		AUTO_SET_HULL = false
	else
		AUTO_SET_HULL = true
	end
end

function BuildingHelper:AddBuildingToGrid(vPoint, nSize, hBuilder)
	LastSize = nSize
	LastOwner = hBuilder
	-- Remember, our blocked squares are defined according to the square's center.
	local centerX = snapToGrid64(vPoint.x)
	local centerY = snapToGrid64(vPoint.y)
	-- Buildings are centered differently when the size is odd.
	if nSize%2 ~= 0 then
		centerX=snapToGrid32(vPoint.x)
		centerY=snapToGrid32(vPoint.y)
	end

	local vBuildingCenter = Vector(centerX,centerY,vPoint.z)
	local halfSide = (nSize/2)*64
	local buildingRect = {leftBorderX = centerX-halfSide, 
		rightBorderX = centerX+halfSide, 
		topBorderY = centerY+halfSide, 
		bottomBorderY = centerY-halfSide}
		
	if BuildingHelper:IsRectangularAreaBlocked(buildingRect) then
		return -1
	end
	
		-- The spot is not blocked, so add it to the closed squares.
		local closed = {}

		if UsePathingMap then
			if BH_UNITS[hBuilder:GetPlayerID()] then
				hBuilder:GeneratePathingMap()
			else
				print("[Building Helper] Error: You haven't added the owner as a unit.")
			end
		end
	
		for x=buildingRect.leftBorderX+32,buildingRect.rightBorderX-32,64 do
			for y=buildingRect.topBorderY-32,buildingRect.bottomBorderY+32,-64 do
				if UsePathingMap then
					if hBuilder ~= nil and hBuilder.vPathingMap ~= nil then
						-- jump the owner if it's in the way of this building.
						if hBuilder.bPathingMapGenerated and hBuilder.vPathingMap[VectorString(Vector(x,y,0))] then
							hBuilder.bNeedsToJump=true
						end
						-- check if other units are in the way of this building. could make this faster.
						for id,unit in pairs(BH_UNITS) do
							if unit ~= hBuilder then
								unit:GeneratePathingMap()
								-- if a square in the pathing map overlaps a square of this building
								if unit.vPathingMap[VectorString(Vector(x,y,0))] then
									-- force the units away if the bool is true.
									if FORCE_UNITS_AWAY then
										unit.bNeedsToJump=true
									else
										return -1
									end
								end
							end
						end
					end
				-- don't use pathing map.
				else
					hBuilder.bNeedsToJump=true
				end
				table.insert(closed,Vector(x,y,0))
			end
		end
		for i,v in ipairs(closed) do
			BUILDING_SQUARES[VectorString(v)]=true
		end
	return vBuildingCenter
end

function BuildingHelper:AddBuilding(building)
	building.bUpdatingHealth = false
	building.bFireEffectEnabled = true
	building.fireEffect="modifier_jakiro_liquid_fire_burn"
	building.bForceUnits = false
	building.fMaxScale=1.0
	building.fCurrentScale = 0.0
	building.bScale=false
	building.hullSet = false
	building.packed = false
	building.BHSize = LastSize
	building.BHOwner = LastOwner
	building.BHParticleDummies = {}
	building.BHParticles = {}
	
	building:SetControllableByPlayer(building.BHOwner:GetPlayerID(), true)

	function building:PackWithDummies()
		--BH_A = math.pow(2,.5) --multi this by rad of building
		--BH_cos45 = math.pow(.5,.5) -- cos(45)
		local origin = building:GetAbsOrigin()
		local rad = building:GetPaddedCollisionRadius()
		local A = BH_A*rad
		local B = rad
		local discCenter = (A-B)/2
		local discRad = BH_cos45*discCenter
		local dist = B + discCenter
		local C = dist*BH_cos45
		-- Top right disc
		local tr_x = origin.x + C
		local tr_y = origin.y + C
		-- top left disc
		local tl_x = origin.x - C
		local tl_y = tr_y
		-- bot left disc
		local bl_x = tl_x
		local bl_y = origin.y - C
		-- bot right disc
		local br_x = tr_x
		local br_y = bl_y

		local s = building.BHSize*64
		--DebugDrawCircle(origin, Vector(0,255,0), 5, building:GetPaddedCollisionRadius(), false, 60)
		--DebugDrawBox(origin, Vector(-1*s/2,-1*s/2,0), Vector(s/2,s/2,0), 0, 0, 255, 0, 60)

		local topRight = CreateUnitByName("npc_bh_dummy", Vector(tr_x,tr_y,0), false, nil, nil, DOTA_TEAM_GOODGUYS)
		local dummyPadding = 10
		Timers:CreateTimer(function()
			topRight:FindAbilityByName("bh_dummy_unit"):SetLevel(1)
			dummyPadding = topRight:GetCollisionPadding()
			topRight:SetHullRadius(discRad-dummyPadding)
			--DebugDrawCircle(Vector(tr_x,tr_y,0), Vector(255,0,0), 5, topRight:GetPaddedCollisionRadius(), false, 60)
		end)

		local topLeft = CreateUnitByName("npc_bh_dummy", Vector(tl_x,tl_y,0), false, nil, nil, DOTA_TEAM_GOODGUYS)
		Timers:CreateTimer(function()
			topLeft:FindAbilityByName("bh_dummy_unit"):SetLevel(1)
			topLeft:SetHullRadius(discRad-dummyPadding)
			--DebugDrawCircle(Vector(tl_x,tl_y,0), Vector(255,0,0), 5, topLeft:GetPaddedCollisionRadius(), false, 60)
		end)

		local bottomLeft = CreateUnitByName("npc_bh_dummy", Vector(bl_x,bl_y,0), false, nil, nil, DOTA_TEAM_GOODGUYS)
		Timers:CreateTimer(function()
			bottomLeft:FindAbilityByName("bh_dummy_unit"):SetLevel(1)
			bottomLeft:SetHullRadius(discRad-dummyPadding)
			--DebugDrawCircle(Vector(bl_x,bl_y,0), Vector(255,0,0), 5, bottomLeft:GetPaddedCollisionRadius(), false, 60)
		end)

		local bottomRight = CreateUnitByName("npc_bh_dummy", Vector(br_x,br_y,0), false, nil, nil, DOTA_TEAM_GOODGUYS)
		Timers:CreateTimer(function()
			bottomRight:FindAbilityByName("bh_dummy_unit"):SetLevel(1)
			bottomRight:SetHullRadius(discRad-dummyPadding)
			--DebugDrawCircle(Vector(br_x,br_y,0), Vector(255,0,0), 5, bottomRight:GetPaddedCollisionRadius(), false, 60)
		end)

		building.packers = {topRight, topLeft, bottomLeft, bottomRight}
		building.packed = true
	end
	
	function building:ShowValidLocations()
		local size = building.BHSize*64
		local pos = building:GetAbsOrigin()
		for x=pos.x-(size*3), pos.x+(size*3), size do
			for y=pos.y+(size*3), pos.y-(size*3), -1*size do
				--DebugDrawCircle(Vector(x,y,0), Vector(0,255,0), 5, 10, false, 60)
				local halfSize = size/2
				local rect = makeBoundingRect(x-halfSize, x+halfSize, y+halfSize, y-halfSize)
				if not BuildingHelper:IsRectangularAreaBlocked(rect) then
					local player = PlayerResource:GetPlayer(building.BHOwner:GetPlayerID())
					local dummy = CreateUnitByName("npc_bh_dummy", Vector(x,y,0+3), false, nil, nil, building.BHOwner:GetTeam())
					dummy:FindAbilityByName("bh_dummy_unit"):SetLevel(1)
					local particle = ParticleManager:CreateParticleForPlayer("particles/units/heroes/hero_lich/lich_ambient_ball_glow_b.vpcf", PATTACH_ABSORIGIN, dummy, player)
					Timers:CreateTimer(15, function()
						dummy:ForceKill(false)
						ParticleManager:DestroyParticle(particle, true)
					end)
				end
			end
		end
	end

	function building:GetSize()
		return building.BHSize
	end

	function building:SetFireEffect(fireEffect)
		if not fireEffect then
			building.bFireEffectEnabled = false
			return
		end
		building.fireEffect = fireEffect
	end

	function building:UpdateHealth(fBuildTime, bScale, fMaxScale)
		building:SetHealth(1)
		building.fBuildTime=fBuildTime
		building.fTimeBuildingCompleted=GameRules:GetGameTime()+fBuildTime+fBuildTime*.35
		building.fMaxHealth = building:GetMaxHealth()
		building.nHealthInterval = building.fMaxHealth*1/(fBuildTime/BUILDINGHELPER_THINK)
		if building.fMaxHealth < 200 then
			-- increase by 50%
			building.nHealthInterval = 1.5*building.nHealthInterval
		end

		building.bUpdatingHealth = true
		if bScale then
			building.fMaxScale=fMaxScale
			building.fScaleInterval=building.fMaxScale*1/(fBuildTime/BUILDINGHELPER_THINK)
			building.fScaleInterval=building.fScaleInterval-.1*building.fScaleInterval
			building.fCurrentScale=.2*fMaxScale
			building.bScale=true
		end
	end
	
	function building:RemoveBuilding(bKill)
		local center = building:GetAbsOrigin()
		local halfSide = (building.BHSize/2.0)*64
		local buildingRect = {leftBorderX = center.x-halfSide, 
			rightBorderX = center.x+halfSide, 
			topBorderY = center.y+halfSide, 
			bottomBorderY = center.y-halfSide}
		local removeCount=0
		for x=buildingRect.leftBorderX+32,buildingRect.rightBorderX-32,64 do
			for y=buildingRect.topBorderY-32,buildingRect.bottomBorderY+32,-64 do
				for v,b in pairs(BUILDING_SQUARES) do
					if v == VectorString(Vector(x,y,0)) then
						BUILDING_SQUARES[v]=nil
						removeCount=removeCount+1
						if bKill then
							building:SetAbsOrigin(Vector(center.x,center.y,center.z-200))
							building:ForceKill(true)
						end
					end
				end
			end
		end
		-- remove the packers.
		if building.packed and building.packers ~= nil then
			for i,unit in ipairs(building.packers) do
				unit:ForceKill(true)
			end
		end
	end

	function building:OnCompleted(callback)
		building.onCompletedCallback = callback
	end

	-- Dynamic packing.
	function building:Pack()
		-- setup global dummy if not already setup.
		if not BHGlobalDummySet then
			BHDummy = CreateUnitByName("npc_bh_dummy", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_GOODGUYS)
			Timers:CreateTimer(function()
	      		local abil = BHDummy:FindAbilityByName("bh_dummy_unit")
				abil:SetLevel(1)
				BHGlobalDummySet = true
	   	    end)
		end
		if not building.hullSet then
			building:SetHull()
			building.hullSet = true
		end
		building:PackWithDummies()
	end

	function building:SetHull()
		building:SetHullRadius(building.BHSize*64/2-building:GetCollisionPadding())
	end

	if (AUTO_SET_HULL) then
		building:SetHull()
		building.hullSet = true
	end

	-- Auto packing
	if PACK_ENABLED then
		-- setup global dummy if not already setup.
		if not BHGlobalDummySet then
			BHDummy = CreateUnitByName("npc_bh_dummy", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_GOODGUYS)
			Timers:CreateTimer(function()
	      		local abil = BHDummy:FindAbilityByName("bh_dummy_unit")
				abil:SetLevel(1)
				BHGlobalDummySet = true
	   	    end)
		end
		if not building.hullSet then
			building:SetHull()
			building.hullSet = true
		end
		building:PackWithDummies()
	end

	-- find clear space for building owner on the next frame.
	  Timers:CreateTimer(function()
      	FindClearSpaceForUnit(building.BHOwner, building.BHOwner:GetAbsOrigin(), true)
   	  end)

	--[[for id,unit in pairs(BH_UNITS) do
		if unit.bNeedsToJump then
			--print("jumping")
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			unit.bNeedsToJump=false
		end
	end]]

	-- health and scale timer
	building.healthTimer = DoUniqueString('health')
	Timers:CreateTimer(building.healthTimer, {
    callback = function()
		if IsValidEntity(building) then
			if building.bUpdatingHealth then
				if building:GetHealth() < building.fMaxHealth and GameRules:GetGameTime() <= building.fTimeBuildingCompleted then
					building:SetHealth(building:GetHealth()+building.nHealthInterval)
				else
					building:SetHealth(building.fMaxHealth)
					if building.onCompletedCallback ~= nil then
						building.onCompletedCallback()
						building.onCompletedCallback = nil
					end
					building.bUpdatingHealth=false
				end
			end
			
			if building.bScale then
				if building.fCurrentScale < building.fMaxScale then
					building.fCurrentScale = building.fCurrentScale+building.fScaleInterval
					building:SetModelScale(building.fCurrentScale)
				else
					building:SetModelScale(building.fMaxScale)
					building.bScale=false
				end
			end

			-- clean up the timer if we don't need it.
			if not building.bUpdatingHealth and not building.bScale then
				return nil
			end
		-- not valid ent
		else
			return nil
		end
	    return BUILDINGHELPER_THINK
    end})
	
	-- fire effect timer
	if FIRE_EFFECTS_ENABLED then
		building.fireTimer = DoUniqueString('fire')
		Timers:CreateTimer(building.fireTimer, {
	    callback = function()
			if building.bFireEffectEnabled and IsValidEntity(building) then
				if building:GetHealth() <= building:GetMaxHealth()/2 and building.bUpdatingHealth == false then
					if building:HasModifier(building.fireEffect) == false then
						building:AddNewModifier(building, nil, building.fireEffect, nil)
					end
				elseif building:GetHealth() > building:GetMaxHealth()/2 and building:HasModifier(building.fireEffect) then
					building:RemoveModifierByName(building.fireEffect)
				end
			-- fire disabled or not valid ent.
			else
				return nil
			end
		    return .25
	    end})
	end
end

------------------------ UTILITY FUNCTIONS --------------------------------------------

function VectorString(v)
  return 'x: ' .. v.x .. ' y: ' .. v.y .. ' z: ' .. v.z
end

function BuildingHelper:IsRectangularAreaBlocked(boundingRect)
	for x=boundingRect.leftBorderX+32,boundingRect.rightBorderX-32,64 do
		for y=boundingRect.topBorderY-32,boundingRect.bottomBorderY+32,-64 do
			local vect = Vector(x,y,0)
			if GRIDNAV_SQUARES[VectorString(vect)] or BUILDING_SQUARES[VectorString(vect)] then
				return true
			end
		end
	end
	return false
end

function IsSquareBlocked( sqCenter )
	sqCenter = Vector(sqCenter.x, sqCenter.y, 0)
	return GRIDNAV_SQUARES[VectorString(sqCenter)] or BUILDING_SQUARES[VectorString(sqCenter)]
end

function snapToGrid64(coord)
	return 64*math.floor(0.5+coord/64)
end

function snapToGrid32(coord)
	return 32+64*math.floor(coord/64)
end

function makeBoundingRect(leftBorderX, rightBorderX, topBorderY, bottomBorderY)
	return {leftBorderX = leftBorderX, rightBorderX = rightBorderX, topBorderY = topBorderY, bottomBorderY = bottomBorderY}
end

-- Use BuildingHelper:GetZ before using these print funcs.
function BuildingHelper:PrintSquareFromCenterPoint(v)
	local z = GetGroundPosition(v, nil).z
	DebugDrawBox(v, Vector(-32,-32,0), Vector(32,32,1), 255, 0, 0, 255, 30)
end

function BuildingHelper:PrintSquareFromCenterPointShort(v)
	DebugDrawBox(v, Vector(-32,-32,0), Vector(32,32,1), 255, 0, 0, 255, .1)
end

--Put this line in InitGameMode to use this function: Convars:RegisterCommand( "buildings", Dynamic_Wrap(YourGameMode, 'DisplayBuildingGrids'), "blah", 0 )
