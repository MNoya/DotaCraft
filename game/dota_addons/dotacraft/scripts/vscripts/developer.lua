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

CHEAT_CODES = {
	["warpten"] = function() dotacraft:WarpTen() end,                  -- "Speeds construction of buildings and units"
	["greedisgood"] = function(args) dotacraft:GreedIsGood(args) end,  -- "Gives you X gold and lumber"	
	["whosyourdaddy"] = function() dotacraft:WhosYourDaddy() end,      -- "God Mode"	
	["thereisnospoon"] = function() dotacraft:ThereIsNoSpoon() end,    -- "Unlimited Mana"		
	["iseedeadpeople"] = function() dotacraft:ISeeDeadPeople() end,    -- "Remove fog of war"		
	["pointbreak"] = function() dotacraft:PointBreak() end,            -- "Sets food limit to 1000"	
	["synergy"] = function() dotacraft:Synergy() end,                  -- "Disable tech tree requirements"
	["riseandshine"] = function() dotacraft:RiseAndShine() end,        -- "Set time of day to dawn"	
	["lightsout"] = function() dotacraft:LightsOut() end,              -- "Set time of day to dusk"
	["giveitem"] = function() dotacraft:GiveItem() end                 -- "Gives an item by name"
}

-- A player has typed something into the chat
function dotacraft:OnPlayerChat(keys)
	local text = keys.text
	local playerID = keys.userid
	local bTeamOnly = keys.teamonly

	local input = split(text)
	local command = input[1]
	local parameter = input[2]
	if CHEAT_CODES[command] then
		CHEAT_CODES[command](parameter)
	end
end

function dotacraft:WarpTen()
	GameRules.WarpTen = not GameRules.WarpTen
	
	local message = GameRules.WarpTen and "Cheat enabled!" or "Cheat disabled!"
	GameRules:SendCustomMessage(message, 0, 0)
end

function dotacraft:GreedIsGood(value)
	local cmdPlayer = Convars:GetCommandClient()
	local pID = cmdPlayer:GetPlayerID()
	if not value then value = 500 end
	
	PlayerResource:ModifyGold(pID, tonumber(value), true, 0)
	ModifyLumber(cmdPlayer, tonumber(value))
	
	GameRules:SendCustomMessage("Cheat enabled!", 0, 0)
end

function dotacraft:WhosYourDaddy()
	GameRules.WhosYourDaddy = not GameRules.WhosYourDaddy
	
	local message = GameRules.WhosYourDaddy and "Cheat enabled!" or "Cheat disabled!"
	GameRules:SendCustomMessage(message, 0, 0)
end

function dotacraft:ThereIsNoSpoon()
	GameRules.ThereIsNoSpoon = not GameRules.ThereIsNoSpoon
	
	local message = GameRules.ThereIsNoSpoon and "Cheat enabled!" or "Cheat disabled!"
	GameRules:SendCustomMessage(message, 0, 0)
end

function dotacraft:ISeeDeadPeople()	
	GameRules.ISeeDeadPeople = not GameRules.ISeeDeadPeople
	GameMode:SetFogOfWarDisabled( GameRules.ISeeDeadPeople )

	local message = GameRules.ISeeDeadPeople and "Cheat enabled!" or "Cheat disabled!"
	GameRules:SendCustomMessage(message, 0, 0)
end

function dotacraft:PointBreak()
	GameRules.PointBreak = not GameRules.PointBreak
	local foodBonus = GameRules.PointBreak and 1000 or 0

	for i=0,DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayerID(i) then
			local player = PlayerResource:GetPlayer(i)
			ModifyFoodLimit(player, foodBonus-player.food_limit)
		end
	end

	local message = GameRules.PointBreak and "Cheat enabled!" or "Cheat disabled!"
	GameRules:SendCustomMessage(message, 0, 0)
end

function dotacraft:Synergy()
	GameRules.Sinergy = not ameRules.Sinergy
	
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

	local message = GameRules.Sinergy and "Cheat enabled!" or "Cheat disabled!"
	GameRules:SendCustomMessage(message, 0, 0)
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