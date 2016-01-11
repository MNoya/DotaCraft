CHEAT_CODES = {
    ["warpten"] = function(...) dotacraft:WarpTen(...) end,                  -- "Speeds construction of buildings and units"
    ["greedisgood"] = function(...) dotacraft:GreedIsGood(...) end,          -- "Gives you X gold and lumber" 
    ["whosyourdaddy"] = function(...) dotacraft:WhosYourDaddy(...) end,      -- "God Mode"    
    ["thereisnospoon"] = function(...) dotacraft:ThereIsNoSpoon(...) end,    -- "Unlimited Mana"      
    ["iseedeadpeople"] = function(...) dotacraft:ISeeDeadPeople(...) end,    -- "Remove fog of war"       
    ["pointbreak"] = function(...) dotacraft:PointBreak(...) end,            -- "Sets food limit to 1000" 
    ["synergy"] = function(...) dotacraft:Synergy(...) end,                  -- "Disable tech tree requirements"
    ["riseandshine"] = function(...) dotacraft:RiseAndShine(...) end,        -- "Set time of day to dawn" 
    ["lightsout"] = function(...) dotacraft:LightsOut(...) end,              -- "Set time of day to dusk"
    ["kurokywasright"] = function(...) dotacraft:RotateCamera(...) end,      -- Rotates the camera 180 degrees
    ["322"] = function(...) dotacraft:MakePlayerLose(...) end,               -- Lose the game         
}

DEBUG_CODES = {
    ["debug_trees"] = function(...) dotacraft:DebugTrees(...) end,           -- Prints the trees marked as pathable
    ["debug_blight"] = function(...) dotacraft:DebugBlight(...) end,         -- Prints the positions marked for undead buildings
    ["debug_food"] = function(...) dotacraft:DebugFood(...) end,             -- Prints the food count for all players, checking for inconsistencies
    ["debug_c"] = function(...) dotacraft:DebugCalls(...) end,               -- Spams the console with every lua call
    ["debug_l"] = function(...) dotacraft:DebugLines(...) end,               -- Spams the console with every lua line
}

TEST_CODES = {
    ["giveitem"] = function(...) dotacraft:GiveItem(...) end,          -- Gives an item by name to the currently selected unit
    ["createunits"] = function(...) dotacraft:CreateUnits(...) end,    -- Creates 'name' units around the currently selected unit, with optional num and neutral team
    ["testhero"] = function(...) dotacraft:TestHero(...) end,          -- Creates 'name' max level hero at the currently selected unit, optional team num
}

function dotacraft:DeveloperMode(player)
	local pID = player:GetPlayerID()
	local hero = player:GetAssignedHero()

    Players:ModifyGold(pID, 50000)
	Players:ModifyLumber(pID, 50000)
	Players:ModifyFoodLimit(pID, 100)
	--[[local position = GameRules.StartingPositions[pID].position
	dotacraft:SpawnTestUnits("orc_spirit_walker", 8, player, position + Vector(0,-600,0), false)
	dotacraft:SpawnTestUnits("nightelf_mountain_giant", 10, player, position + Vector(0,-1000,0), true)]]
end

-- A player has typed something into the chat
function dotacraft:OnPlayerChat(keys)
	local text = keys.text
	local userID = keys.userid
    local playerID = self.vUserIds[userID] and self.vUserIds[userID]:GetPlayerID()
    if not playerID then return end

    -- Handle '-command'
    if StringStartsWith(text, "-") then
        text = string.sub(text, 2, string.len(text))
    end

	local input = split(text)
	local command = input[1]
	if CHEAT_CODES[command] then
		CHEAT_CODES[command](playerID, input[2])
	elseif DEBUG_CODES[command] then
        DEBUG_CODES[command](input[2])
    elseif TEST_CODES[command] then
        TEST_CODES[command](input[2], input[3], input[4], playerID)
    end        
end

function dotacraft:WarpTen()
	GameRules.WarpTen = not GameRules.WarpTen
	
	local message = GameRules.WarpTen and "Cheat enabled!" or "Cheat disabled!"
	GameRules:SendCustomMessage(message, 0, 0)
end

function dotacraft:GreedIsGood(playerID, value)
	if not value then value = 500 end
	
	Players:ModifyGold(playerID, tonumber(value))
	Players:ModifyLumber(playerID, tonumber(value))
	
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

	for playerID=0,DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayerID(playerID) then
			local player = PlayerResource:GetPlayer(playerID)
			Players:ModifyFoodLimit(playerID, foodBonus-Players:GetFoodLimit(playerID))
		end
	end

	local message = GameRules.PointBreak and "Cheat enabled!" or "Cheat disabled!"
	GameRules:SendCustomMessage(message, 0, 0)
end

function dotacraft:Synergy()
	GameRules.Synergy = not GameRules.Synergy
	
	for playerID=0,DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayerID(playerID) then
			local playerUnits = Players:GetUnits(playerID)
            local playerStructures = Players:GetUnits(playerID)
			for _,v in pairs(playerUnits) do
				CheckAbilityRequirements(v, playerID)
			end
			for _,v in pairs(playerStructures) do
				CheckAbilityRequirements(v, playerID)
			end
		end
	end

	local message = GameRules.Synergy and "Cheat enabled!" or "Cheat disabled!"
	GameRules:SendCustomMessage(message, 0, 0)
end

function dotacraft:RiseAndShine()
	GameRules:SetTimeOfDay( 0.3 )
end

function dotacraft:LightsOut()
	GameRules:SetTimeOfDay( 0.8 )
end

function dotacraft:GiveItem(playerID, item_name)
	local cmdPlayer = Convars:GetCommandClient()
	
	local selected = GetMainSelectedEntity(playerID)
	local new_item = CreateItem(item_name, selected, selected)
	if new_item then
		selected:AddItem(new_item)
	end
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
    for x,v in pairs(BuildingHelper.Grid) do
        for y,_ in pairs(v) do
            if BuildingHelper:CellHasGridType(x,y,'BLIGHT') then
                DrawGridSquare(x,y,Vector(128,0,128))
            end
        end
    end
end

function dotacraft:DebugFood()
    for playerID=0,DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            local food_limit = Players:GetFoodLimit(playerID)
            local food_used = Players:GetFoodUsed(playerID)
            local food_produced_counter = 0
            local food_used_counter = 0
            print("== PLAYER "..playerID.." ==")
            print("== UNITS ==")

            local units = {}
            local playerUnits = Players:GetUnits(playerID)
            for _,v in pairs(playerUnits) do
                if not IsValidAlive(v) then
                    print(" Invalid Unit!")
                else
                    local food_cost = GetFoodCost(v)
                    food_used_counter = food_used_counter + food_cost
                    local unitName = v:GetUnitName()
                    units[unitName] = units[unitName] and units[unitName]+1 or 1
                end
            end

            print('-> '..food_used_counter.." food used on units: ")
            for k,v in pairs(units) do
                print(k,GameRules.UnitKV[k].FoodCost * v, "("..v..")")
            end

            print("== HEROES ==")
            local playerHeroes = Players:GetHeroes(playerID)
            local hero_food_counter = 0
            for _,v in pairs(playerHeroes) do
                if not IsValidAlive(v) then
                    print(" Invalid Hero!")
                else
                    local food_cost = GetFoodCost(v)
                    food_used_counter = food_used_counter + food_cost
                    hero_food_counter = hero_food_counter + food_cost
                end
            end
            print("-> "..hero_food_counter.." food used on heroes")

            print("== STRUCTURES ==")
            local playerStructures = Players:GetStructures(playerID)
            for _,v in pairs(playerStructures) do
                if not IsValidAlive(v) then
                    print(" Invalid Structure!")
                else
                    local food_produced = GetFoodProduced(v) or 0
                    food_produced_counter = food_produced_counter + food_produced
                    if food_produced_counter > 100 then food_produced_counter = 100 end
                end
            end
            print("-> "..food_produced_counter.." food produced from structures")

            print("================")
            print("Stored:  ",food_used.." / "..food_limit)
            print("Recount: ",food_used_counter.." / "..food_produced_counter)
            if (food_used ~= food_used_counter) then print("ERROR IN FOOD USED!") end
            if (food_limit ~= food_produced_counter) then print("ERROR IN FOOD PRODUCED!") end
            print("================")
        end
    end
end

function dotacraft:CreateUnits(unitName, numUnits, bEnemy, pID)
    local pos = GetMainSelectedEntity(pID):GetAbsOrigin()
    local player = PlayerResource:GetPlayer(pID)
    local hero = player:GetAssignedHero()

     -- Handle possible unit issues
    numUnits = numUnits or 1
    if not GameRules.UnitKV[unitName] then
        Say(nil,"["..unitName.."] <font color='#ff0000'> is not a valid unit name!</font>", false)
        return
    end

    local gridPoints = GetGridAroundPoint(numUnits, pos)

    PrecacheUnitByNameAsync(unitName, function()
        for i=1,numUnits do
            local unit = CreateUnitByName(unitName, gridPoints[i], true, hero, hero, hero:GetTeamNumber())
            unit:SetOwner(hero)
            unit:SetControllableByPlayer(pID, true)
            unit:SetMana(unit:GetMaxMana())

            if bEnemy then 
                unit:SetTeam(DOTA_TEAM_NEUTRALS)
            else
                Players:AddUnit(pID, unit)
            end

            FindClearSpaceForUnit(unit, gridPoints[i], true)
            unit:Hold()         
        end
    end, pID)
end

function dotacraft:TestHero( heroName, bEnemy )
    local pos = GetMainSelectedEntity(0):GetAbsOrigin()
    local unitName = GetRealHeroName(heroName)
    local team = bEnemy and DOTA_TEAM_NEUTRALS or PlayerResource:GetTeam(0)

    PrecacheUnitByNameAsync(unitName, function()
        local hero = CreateUnitByName(unitName, pos, true, nil, nil, team)
        hero:SetControllableByPlayer(0, true)

        for i=1,8 do
            hero:HeroLevelUp(false)
        end

    end, 0)
end

function dotacraft:DebugCalls()
    if not GameRules.DebugCalls then
        print("Starting DebugCalls")
        GameRules.DebugCalls = true

        debug.sethook(function(...)
            local info = debug.getinfo(2)
            local src = tostring(info.short_src)
            local name = tostring(info.name)
            if name ~= "__index" then
                print("Call: ".. src .. " -- " .. name)
            end
        end, "c")
    else
        print("Stopped DebugCalls")
        GameRules.DebugCalls = false
        debug.sethook(nil, "c")
    end
end

function dotacraft:DebugLines(funcName)
    if not GameRules.DebugLines then
        print("Starting DebugLines "..funcName)
        GameRules.DebugLines = true

        -- Line Hook
        debug.sethook(function(event, line)
            local info = debug.getinfo(2)
            local src = tostring(info.short_src)
            local name = tostring(info.name)
            if name == funcName then
                print("Line ".. line .. " -- " .. src .. " -- " .. name)
            end
        end, "l")
    else
        print("Stopped DebugLines")
        GameRules.DebugLines = false
        debug.sethook(nil, "l")
    end
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

    local offsetX = 100
    local offsetY = 100

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


--[[ 
StrengthAndHonor - No defeat
Motherland [race] [level] - level jump
SomebodySetUpUsTheBomb - Instant defeat
AllYourBaseAreBelongToUs - Instant victory
WhoIsJohnGalt - Enable research
SharpAndShiny - Research upgrades
DayLightSavings [time] - If a time is specified, time of day is set to that, otherwise time of day is alternately halted/resumed
]]