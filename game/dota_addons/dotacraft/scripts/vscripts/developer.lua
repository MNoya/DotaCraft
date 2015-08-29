function dotacraft:DeveloperMode(player)
	local pID = player:GetPlayerID()
	local hero = player:GetAssignedHero()

	hero:SetGold(50000, false)
	ModifyLumber(player, 50000)
	ModifyFoodLimit(player, 100)

	local position = GameRules.StartingPositions[pID].position
	dotacraft:SpawnTestUnits("orc_spirit_walker", 8, player, position + Vector(0,-600,0), false)
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

-- Legacy Cheat Codes
if not GameRules.RegisteredCheats then
	Convars:RegisterCommand( "warpten", Dynamic_Wrap(dotacraft, 'WarpTen'), "Speeds construction of buildings and units", 0 )
	Convars:RegisterCommand( "greedisgood", Dynamic_Wrap(dotacraft, 'GreedIsGood'), "Gives you X gold and lumber", 0 )
	Convars:RegisterCommand( "whosyourdaddy", Dynamic_Wrap(dotacraft, 'WhosYourDaddy'), "God Mode", 0 )
	Convars:RegisterCommand( "thereisnospoon", Dynamic_Wrap(dotacraft, 'ThereIsNoSpoon'), "Unlimited Mana", 0 )
	Convars:RegisterCommand( "iseedeadpeople", Dynamic_Wrap(dotacraft, 'ISeeDeadPeople'), "Remove fog of war", 0 )
	Convars:RegisterCommand( "pointbreak", Dynamic_Wrap(dotacraft, 'PointBreak'), "Sets food limit to 1000", 0 )
	Convars:RegisterCommand( "synergy", Dynamic_Wrap(dotacraft, 'Synergy'), "Disable tech tree requirements", 0 )
	Convars:RegisterCommand( "riseandshine", Dynamic_Wrap(dotacraft, 'RiseAndShine'), "Set time of day to dawn", 0 )
	Convars:RegisterCommand( "lightsout", Dynamic_Wrap(dotacraft, 'LightsOut'), "Set time of day to dusk", 0 )
	Convars:RegisterCommand( "giveitem", Dynamic_Wrap(dotacraft, 'GiveItem'), "Gives an item by name", 0 )
	GameRules.RegisteredCheats = true
end

function dotacraft:WarpTen()
	if not GameRules.WarpTen then
		print('Cheat enabled!')
		GameRules.WarpTen = true
	else
		print("Cheat disabled!")
		GameRules.WarpTen = false
	end
end

function dotacraft:GreedIsGood(value)
	local cmdPlayer = Convars:GetCommandClient()
	local pID = cmdPlayer:GetPlayerID()
	
	PlayerResource:ModifyGold(pID, tonumber(value), true, 0)
	ModifyLumber(cmdPlayer, tonumber(value))
end

function dotacraft:WhosYourDaddy()
	if not GameRules.WhosYourDaddy then
		print('Cheat enabled!')
		GameRules.WhosYourDaddy = true
	else
		print("Cheat disabled!")
		GameRules.WhosYourDaddy = false
	end
end

function dotacraft:ThereIsNoSpoon()
	if not GameRules.ThereIsNoSpoon then
		print('Cheat enabled!')
		GameRules.ThereIsNoSpoon = true
	else
		print("Cheat disabled!")
		GameRules.ThereIsNoSpoon = false
	end
end

function dotacraft:ISeeDeadPeople()	
	GameRules.ISeeDeadPeople = not GameRules.ISeeDeadPeople
	GameMode:SetFogOfWarDisabled( GameRules.ISeeDeadPeople )
end

function dotacraft:PointBreak()
	GameRules.PointBreak = true
	for i=0,DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayerID(i) then
			local player = PlayerResource:GetPlayer(i)
			ModifyFoodLimit(player, 1000-player.food_limit)
		end
	end
end

function dotacraft:Synergy()
	if not GameRules.Synergy then
		print('Cheat enabled!')
		GameRules.Synergy = true
	else
		print("Cheat disabled!")
		GameRules.Synergy = false
	end

	for i=0,DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayerID(i) then
			local player = PlayerResource:GetPlayer(i)
			for _,v in pairs(player.units) do
				CheckAbilityRequirements(v, player)
			end
			for _,v in pairs(player.structures) do
				CheckAbilityRequirements(v, player)
			end
		end
	end

end

function dotacraft:RiseAndShine()
	GameRules:SetTimeOfDay( 0.3 )
end

function dotacraft:LightsOut()
	GameRules:SetTimeOfDay( 0.8 )
end

function dotacraft:GiveItem(item_name)
	local cmdPlayer = Convars:GetCommandClient()
	local pID = cmdPlayer:GetPlayerID()
	
	local selected = GetMainSelectedEntity(pID)
	local new_item = CreateItem(item_name, selected, selected)
	if new_item then
		selected:AddItem(new_item)
	end
end


--[[ 
StrengthAndHonor - No defeat
Motherland [race] [level] - level jump
SomebodySetUpUsTheBomb - Instant defeat
AllYourBaseAreBelongToUs - Instant victory
WhoIsJohnGalt - Enable research
SharpAndShiny - Research upgrades
DayLightSavings [time] - If a time is specified, time of day is set to that, otherwise time of day is alternately halted/resumed
]]