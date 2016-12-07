customSchema = class({})

function customSchema:init()

    -- Check the schema_examples folder for different implementations

    -- Flag Example
    -- statCollection:setFlags({version = GetVersion()})

    -- Listen for changes in the current state
    ListenToGameEvent('game_rules_state_change', function(keys)
        local state = GameRules:State_Get()

        -- Send custom stats when the game ends
        if state == DOTA_GAMERULES_STATE_POST_GAME then

            -- Build game array
            local game = BuildGameArray()

            -- Build players array
            local players = BuildPlayersArray()

            -- Print the schema data to the console
            if statCollection.TESTING then
                PrintSchema(game, players)
            end

            -- Send custom stats
            if statCollection.HAS_SCHEMA then
                statCollection:sendCustom({ game = game, players = players })
            end
        end
    end, nil)

    -- Write 'test_schema' on the console to test your current functions instead of having to end the game
    if Convars:GetBool('developer') then
        Convars:RegisterCommand("test_schema", function() PrintSchema(BuildGameArray(), BuildPlayersArray()) end, "Test the custom schema arrays", 0)
        Convars:RegisterCommand("test_end_game", function() GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS) end, "Test the end game", 0)
    end
end



-------------------------------------

-- In the statcollection/lib/utilities.lua, you'll find many useful functions to build your schema.
-- You are also encouraged to call your custom mod-specific functions

-- Returns a table with our custom game tracking.
function BuildGameArray()
    local game = {}

    game.map = dotacraft:GetMapName()
    game.duration = dotacraft:GetTime()
    game.str = START_TIME
    game.fin = END_TIME or (GetSystemDate() .. " " .. GetSystemTime())
    game.ver = VERSION

    return game
end

-- Returns a table containing data for every player in the game
function BuildPlayersArray()
    local players = {}
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then

                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                local scores = Players:GetPlayerScores(playerID)

                table.insert(players, {
                    steamID32 = PlayerResource:GetSteamAccountID(playerID),

                    -- General
                    race = Players:GetRace(playerID),
                    gold = Players:GetGold(playerID),
                    lumber = Players:GetLumber(playerID),
                    food_used = Players:GetFoodUsed(playerID),      -- Useless for the losing player
                    food_limit = Players:GetFoodLimit(playerID),    -- Useless for the losing player
                    build_order = Players:GetBuildOrder(playerID),  -- List of {time, name}

                    -- Units
                    units_produced = scores.units_produced,
                    units_killed = scores.units_killed,
                    buildings_produced = scores.buildings_produced,
                    buildings_razed = scores.buildings_razed,
                    largest_army = scores.largest_army,

                    -- Heroes
                    heroes_used = scores.heroes_used,              -- Might want to split in hero1/2/3
                    heroes_killed = scores.heroes_killed,
                    items_obtained = scores.items_obtained,
                    mercenaries_hired = scores.mercenaries_hired,
                    experienced_gained = scores.experienced_gained,

                    -- Resources
                    gold_mined = scores.gold_mined,
                    lumber_harvested = scores.lumber_harvested,
                    resource_traded = scores.resource_traded,
                    tech_percentage = scores.tech_percentage,        -- Might want to save the order
                    gold_lost_to_upkeep = scores.gold_lost_to_upkeep,
                })
            end
        end
    end

    return players
end

-- Prints the custom schema, required to get an schemaID
function PrintSchema(gameArray, playerArray)
    print("-------- GAME DATA --------")
    DeepPrintTable(gameArray)
    print("\n-------- PLAYER DATA --------")
    DeepPrintTable(playerArray)
    print("-------------------------------------")
end

-------------------------------------

-- If your gamemode is round-based, you can use statCollection:submitRound(bLastRound) at any point of your main game logic code to send a round
-- If you intend to send rounds, make sure your settings.kv has the 'HAS_ROUNDS' set to true. Each round will send the game and player arrays defined earlier
-- The round number is incremented internally, lastRound can be marked to notify that the game ended properly
function customSchema:submitRound()

    local winners = BuildRoundWinnerArray()
    local game = BuildGameArray()
    local players = BuildPlayersArray()

    statCollection:sendCustom({ game = game, players = players })
end

-- A list of players marking who won this round
function BuildRoundWinnerArray()
    local winners = {}
    local current_winner_team = GameRules.Winner or 0 --You'll need to provide your own way of determining which team won the round
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then
                winners[PlayerResource:GetSteamAccountID(playerID)] = (PlayerResource:GetTeam(playerID) == current_winner_team) and 1 or 0
            end
        end
    end
    return winners
end

-------------------------------------
