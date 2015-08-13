function dotacraft:DeveloperMode(player)
	local pID = player:GetPlayerID()
	local hero = player:GetAssignedHero()

	hero:SetGold(50000, false)
	ModifyLumber(player, 50000)
	ModifyFoodLimit(player, 100)

	local position = GameRules.StartingPositions[pID].position
	dotacraft:SpawnTestUnits("nightelf_archer", 16, player, position + Vector(0,-600,0), false)
	--dotacraft:SpawnTestUnits("nightelf_mountain_giant", 10, player, position + Vector(0,-1000,0), true)
end

function dotacraft:SpawnTestUnits(unitName, numUnits, player, pos, bEnemy)
	local pID = player:GetPlayerID()
	local hero = player:GetAssignedHero()
	local gridPoints = GetGridAroundPoint(numUnits, pos)

	PrecacheUnitByNameAsync(unitName, function()
		for i=1,numUnits do
			local unit = CreateUnitByName(unitName, gridPoints[i], true, hero, hero, hero:GetTeamNumber())
			unit:SetOwner(hero)
			unit:SetControllableByPlayer(pID, true)
			unit:SetMana(unit:GetMaxMana())

			if bEnemy then 
				unit:SetTeam(DOTA_TEAM_BADGUYS)
			else
				table.insert(player.units, unit)
			end

			FindClearSpaceForUnit(unit, gridPoints[i], true)
			unit:Hold()			
		end
	end, pID)
end

function GetGridAroundPoint( numUnits, point )
	local navPoints = {}  

    local unitsPerRow = math.floor(math.sqrt(numUnits))
    local unitsPerColumn = math.floor((numUnits / unitsPerRow))
    local remainder = numUnits - (unitsPerRow*unitsPerColumn) 

	local forward = point:Normalized()
    local right = RotatePosition(Vector(0,0,0), QAngle(0,90,0), forward)

    local start = (unitsPerColumn-1)* -.5

    local curX = start
    local curY = 0

    local offsetX = 200
    local offsetY = 200

    for i=1,unitsPerRow do
      for j=1,unitsPerColumn do
        local newPoint = point + (curX * offsetX * right) + (curY * offsetY * forward)
        navPoints[#navPoints+1] = newPoint
        curX = curX + 1
      end
      curX = start
      curY = curY - 1
    end

    local curX = ((remainder-1) * -.5)

    for i=1,remainder do 
		local newPoint = point + (curX * offsetX * right) + (curY * offsetY * forward)
		navPoints[#navPoints+1] = newPoint
		curX = curX + 1
    end

    return navPoints
end

function dotacraft:DebugTrees()
	for k,v in pairs(GameRules.ALLTREES) do
		if v:IsStanding() then
			if IsTreePathable(v) then
				DebugDrawCircle(v:GetAbsOrigin(), Vector(0,255,0), 255, 32, true, 60)
				if not v.builder then
					DebugDrawText(v:GetAbsOrigin(), "OK", true, 60)
				end
			else
				DebugDrawCircle(v:GetAbsOrigin(), Vector(255,0,0), 255, 32, true, 60)
			end
		end
	end
end

function dotacraft:DebugBlight()
	local worldMin = Vector(GetWorldMinX(), GetWorldMinY(), 0)
	local worldMax = Vector(GetWorldMaxX(), GetWorldMaxY(), 0)
	local boundX1 = GridNav:WorldToGridPosX(worldMin.x)
	local boundX2 = GridNav:WorldToGridPosX(worldMax.x)
	local boundY1 = GridNav:WorldToGridPosX(worldMin.y)
	local boundY2 = GridNav:WorldToGridPosX(worldMax.y)

	for i=boundX1+1,boundX2-1 do
		for j=(boundY1+1),boundY2-1 do
      		local position = Vector(GridNav:GridPosToWorldCenterX(i), GridNav:GridPosToWorldCenterY(j), 0)
			if HasBlight(position) then
				if HasBlightParticle(position) then
					DebugDrawCircle(position, Vector(128,128,128), 50, 256, true, 60)
				else
					DebugDrawCircle(position, Vector(128,0,128), 50, 32, true, 60)
				end
			end
		end
	end
end

function dotacraft:DebugNight()
	GameRules:SetTimeOfDay( 0.8 )
end

function dotacraft:DebugDay()
	GameRules:SetTimeOfDay( 0.3 )
end