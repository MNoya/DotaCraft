if not Shops then
    Shops = class({})
end

function Shops:start()
    self.Units = {}   -- Holds shop units
    self.Players = {} -- Holds players
    self.TavernID = nil
    self.Debug = true

    CustomGameEventManager:RegisterListener("shops_buy_item", function(userID, event) Dynamic_Wrap(Shops, "BuyItem")(self, event) end)
    CustomGameEventManager:RegisterListener("shops_tavern_buy_hero", function(userID, event) Dynamic_Wrap(Shops, "BuyHero")(self, event) end)
    CustomGameEventManager:RegisterListener("shops_tavern_revive_hero", function(userID, event) Dynamic_Wrap(Shops, "ReviveHero")(self, event) end)
    CustomGameEventManager:RegisterListener("open_closest_shop", function(userID, event) Dynamic_Wrap(Shops, "OpenClosestShop")(self, event) end)

    self.ShopsKV = LoadKeyValues("scripts/kv/shops.kv")
    self.GoblinMerchantKV = LoadKeyValues("scripts/kv/goblin_merchant.kv")
    self.MercenariesKV = LoadKeyValues("scripts/kv/mercenaries.kv")
end

-- neutral hero tavern values
NEUTRAL_HERO_GOLDCOST = 425
NEUTRAL_HERO_LUMBERCOST = 135
NEUTRAL_HERO_FOODCOST = 5
NEUTRAL_HERO_STOCKTIME = 135

-- player hero revival cost values
BASE_HERO_GOLDCOST = 255
BASE_HERO_ADDITIONAL_GOLDCOST_PER_LEVEL = 85
BASE_HERO_LUMBERCOST = 50
BASE_HERO_ADDITIONAL_LUMBERCOST_PER_LEVEL = 30

-- marketplace values
MARKETPLACE_THINK = 30 -- Every 30 seconds, a new item is added to the marketplace
MARKETPLACE_START_DELAY = 120 -- Marketplaces do not stock items until 2 minutes into the game.
MARKETPLACE_ITEM_LIMIT = 11
    
-- Entry point from ability_shop
function SetupShop(event)
    local shop = event.caster
    shop.current_unit = {} -- Keeps track of the current unit of this shop for every possible player
    shop.active_particle = {}

    Shops:CreateShop(shop)
end

function Shops:CreateShop(unit)
    local shopType = unit:GetKeyValue("ShopType")
    local shopIndex = unit:GetEntityIndex()
    local shopName = unit:GetUnitName()
    local playerID = unit:GetPlayerOwnerID()
    
    -- Init tracking
    self.Units[shopIndex] = {}
    self.Units[shopIndex].Items = {}
    
    if not self.Players[playerID] then
        self.Players[playerID] = {}
        self.Players[playerID].Items = {}
    end

    -- Create shop panels based on the shop type
    if shopType == "tavern" then
        Shops:SetupTavern(unit)
    elseif shopType == "global" then
        Shops:SetupGlobalShop(unit)
    elseif shopType:match("team") then
        Shops:SetupTeamShop(unit)
    elseif shopType == "marketplace" then
        Shops:SetupMarketplace(unit)
    else
        if not shopType then
            self:print("Missing \"ShopType\" KV on "..shopName)
        else
            self:print("Unsupported type of shop ("..shopType..") for "..shopName)
        end
    end

    -- Create a trigger for enabling the sell option on units
    if shopType == "team" or shopType == "marketplace" or shopName == "goblin_merchant" then
        self:CreateTrigger(unit)
    end
end

function Shops:CreateTrigger(unit)
    local shopEnt = Entities:FindByName(nil, "*custom_shop") -- entity name in hammer
    if shopEnt then
        local modelName = shopEnt:GetModelName()
        local newshop = SpawnEntityFromTableSynchronous("trigger_shop", {origin = unit:GetAbsOrigin(), shoptype = 1, model = modelName}) -- shoptype is 0 for a "home" shop, 1 for a side shop and 2 for a secret shop)
    else
        self:print("ERROR: CreateTrigger was unable to find a custom_shop trigger area. Add a custom_shop trigger to this map!")
    end
end

function Shops:SetupTavern(unit)
    local playerID = unit:GetPlayerOwnerID()
    local tier = Players:GetTier(playerID)
    CustomGameEventManager:Send_ServerToAllClients("shops_create", {Index = unit:GetEntityIndex(), Shop = Shops:GenerateItemTableForShop(unit), Tier=tier, Tavern=true}) 
    self.TavernID = unit:GetEntityIndex()
    self:print("Created Tavern!")
end

function Shops:SetupGlobalShop(unit)
    local bUnitShop = unit:GetKeyValue("SellsNPCs")
    CustomGameEventManager:Send_ServerToAllClients("shops_create", {Index = unit:GetEntityIndex(), Shop = Shops:GenerateItemTableForShop(unit), Tier=0, Neutral=bUnitShop})
    self:print("Created Global Shop: "..unit:GetUnitName())
end

function Shops:SetupTeamShop(unit)
    local playerID = unit:GetPlayerOwnerID()
    local tier = Players:GetTier(playerID)
    CustomGameEventManager:Send_ServerToTeam(unit:GetTeamNumber(), "shops_create", {Index = unit:GetEntityIndex(), Shop = Shops:GenerateItemTableForShop(unit), Tier=tier}) 
    self:print("Created Team Shop: "..unit:GetUnitName())
end

function Shops:SetupMarketplace(unit)
    local marketplace = unit
    marketplace.itemList = {}

    function marketplace:Start()
        CustomGameEventManager:Send_ServerToAllClients("shops_create", {Index = unit:GetEntityIndex(), Shop = {}, Tier=0}) 
        Timers:CreateTimer(MARKETPLACE_START_DELAY, function()
            if TableCount(marketplace.itemList) < MARKETPLACE_ITEM_LIMIT then
                local itemName = Drops:GetRandomDrop()
                while marketplace.itemList[itemName] do
                    itemName = Drops:GetRandomDrop()
                end
                marketplace:AddItem(itemName)
            end
            return MARKETPLACE_THINK
        end)
    end

    function marketplace:AddItem(name)
        local itemInfo = {}
        itemInfo.ItemName = name
        itemInfo.CurrentRefreshTime = 1
        itemInfo.CurrentStock = 1
        itemInfo.MaxStock = 1
        itemInfo.RequiredTier = 0
        itemInfo.GoldCost = GetKeyValue(name, "ItemCost") or 0
        itemInfo.LumberCost = GetKeyValue(name, "LumberCost") or 0
        itemInfo.FoodCost = 0
        itemInfo.RestockRate = 1
        itemInfo.StockStartDelay = 0
        Shops:StockUpdater(itemInfo, marketplace)

        -- Store the item on tables
        marketplace.itemList[name] = true
        Shops.Units[marketplace:GetEntityIndex()].Items[name] = itemInfo

        CustomGameEventManager:Send_ServerToAllClients("shops_create_item_panel", {Index = marketplace:GetEntityIndex(), ItemInfo = itemInfo})
        Shops:print("Added item to Marketplace: "..name)
    end

    function marketplace:RemoveItem(name)
        Shops:print("Removing item from Marketplace: "..name)
        CustomGameEventManager:Send_ServerToAllClients("shops_delete_panel", {Index = marketplace:GetEntityIndex(), ItemName = name}) 
        marketplace.itemList[name] = nil
    end

    marketplace:Start()
    self:print("Created Marketplace")
end

function Shops:GenerateItemTableForShop(unit)
    local shop_name = unit:GetUnitName()
    local shopTable = self.Units[unit:GetEntityIndex()]
    local shopItemList = self.ShopsKV[shop_name] or {}

    -- Mercenaries take their list based on the tileset
    if shop_name == "mercenary" then
        local mapName = dotacraft:GetMapName()
        local tileset = self.MercenariesKV["Maps"][mapName]
        self:print("Created Mercenary shop for "..mapName.." (" ..tileset.." tileset)")
        shopItemList = self.MercenariesKV[tileset]
    end
    local bTavern = shop_name == "tavern"

    local sorted_table = {} -- empty sorted table to organize the item list
    for i,itemName in pairs(shopItemList) do
        self:print("Creating timer for "..itemName.." new shop: "..shop_name)

        -- set all variables
        local itemInfo = {}
        itemInfo = {}
        itemInfo.ItemName = itemName
        itemInfo.CurrentRefreshTime = 1
        
        local grTable

        -- Mercenary and Goblin Lab take values from unit kv files
        if shop_name == "mercenary" or shop_name == "goblin_lab" then
            grTable = KeyValues.UnitKV

        -- Merchant uses a different stock system and tiers for items
        elseif shop_name == "goblin_merchant" then
            grTable = self.GoblinMerchantKV

        -- Other shops take the values directly from the item kv
        else
            grTable = KeyValues.ItemKV
        end
        
        -- Tavern heroes initially cost only food
        if bTavern then
            itemInfo.CurrentStock = 0
            itemInfo.MaxStock = 1
            itemInfo.RequiredTier = 9000
            itemInfo.GoldCost = 0
            itemInfo.LumberCost = 0
            itemInfo.FoodCost = 5
            itemInfo.RestockRate = NEUTRAL_HERO_STOCKTIME
            self:TavernStockUpdater(itemInfo, unit)    
        else
            itemInfo.CurrentStock = grTable[itemName]["StockInitial"] or 1
            itemInfo.MaxStock = grTable[itemName]["StockMax"] or 1
            itemInfo.RequiredTier = grTable[itemName]["RequiresTier"] or 0
            itemInfo.GoldCost = grTable[itemName]["ItemCost"] or grTable[itemName]["GoldCost"] or 0
            itemInfo.LumberCost = grTable[itemName]["LumberCost"] or 0
            itemInfo.FoodCost = grTable[itemName]["FoodCost"] or 0
            itemInfo.RestockRate = grTable[itemName]["StockTime"] or 1
            itemInfo.StockStartDelay = grTable[itemName]["StockStartDelay"] or 0
            self:StockUpdater(itemInfo, unit)
        end

        shopTable.Items[itemName] = itemInfo
        
        -- save item into table using it's sort index, this is sent once at the beginning to initialise the shop
        sorted_table[tonumber(i)] = shopTable.Items[itemName]
    end

    return sorted_table
end

--[[TODO: This shouldn't be on a timer, but as an event, whenever the player
    Builds an altar/city center
    Altar/city center destroyed
    City center upgraded (special case of destroying -> building)
    Altar tier increases/decreases (hero training start/cancel)
]]
function Shops:TavernStockUpdater(itemInfo, unit)
    Timers:CreateTimer(0.1, function()
        local PlayerCount = PlayerResource:GetPlayerCount() - 1
        self:Stock_Management(itemInfo)
        
        -- check all players hero count
        for playerID=0, PlayerCount do
            local hero = PlayerResource:GetSelectedHeroEntity(playerID)
            if hero then
                local player = PlayerResource:GetPlayer(playerID)                       
                
                -- if player cannot train more heroes and tavern wasn't previously disabled, disable it now     
                if player and not Players:CanTrainMoreHeroes(playerID) then
                    CustomGameEventManager:Send_ServerToPlayer(player, "shops_remove_content", {Index = self.TavernID, Shop = itemInfo}) 
                    self:print("Remove neutral heroes panels from player "..playerID)
                    return
                end
                
                self:UpdateTavern(playerID)
                local tier = Players:GetCityLevel(playerID) or 9000
                local hasAltar = Players:HasFinishedAltar(playerID)
                
                CustomGameEventManager:Send_ServerToPlayer(player, "shop_update_stock", {Index = self.TavernID, Item = itemInfo, Tier=tier, Altar=hasAltar})
            end
            
        end
        return 0.01
    end)
end

function Shops:StockUpdater(itemInfo, unit)
    local entIndex = unit:GetEntityIndex()
    local bUpdateStock = unit:GetKeyValue("ShopType") == "global" or unit:GetKeyValue("ShopType") == "marketplace"
    Timers:CreateTimer(1, function()
        local playerID = unit:GetPlayerOwnerID()    
        local tier = Players:GetTier(playerID)

        if not IsValidEntity(unit) or not unit:IsAlive() then
            -- send command to kill shop panel
            self:print("Shop identified not valid, terminating timer")
            return
        end

        self:Stock_Management(itemInfo)
        if PlayerResource:IsValidPlayer(playerID) or bUpdateStock then
            CustomGameEventManager:Send_ServerToAllClients("shop_update_stock", {Index = entIndex, Item = itemInfo, Tier=tier})      
        end
        return 1
    end)
end

function Shops:Stock_Management(itemInfo)
    -- if the item is not at max stock start a counter until it's restocked
    if itemInfo.CurrentStock < itemInfo.MaxStock then
        if itemInfo.StockStartDelay ~= 0 and itemInfo.CurrentRefreshTime == itemInfo.StockStartDelay then
            -- this is might need altering, currently its abit hardcoded
            itemInfo.CurrentStock = itemInfo.MaxStock
            
            -- set to 0 to stop condition from being met so that it resumes normal restocking rates
            itemInfo.StockStartDelay = 0
            
            -- reset counter for next stock
            itemInfo.CurrentRefreshTime = 1
            self:print("Increasing stock of "..itemInfo.ItemName.." in global shop")
        elseif itemInfo.CurrentRefreshTime == itemInfo.RestockRate then
            -- increase stock by 1 when the CurrentRefreshTime == RestockRate
            itemInfo.CurrentStock = itemInfo.CurrentStock + 1
            
            -- reset counter for next stock
            itemInfo.CurrentRefreshTime = 1
            self:print("Increasing stock of "..itemInfo.ItemName)
        else
            --self:print("Incrementing counter to restock")
            itemInfo.CurrentRefreshTime = itemInfo.CurrentRefreshTime + 1 -- increment the time counter
        end
    end
end

function Shops:RemoveHeroPanel(ShopEntityIndex, playerID, ItemName)
    self:print("Deleting hero panel")
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "shops_delete_panel", {Index = ShopEntityIndex, ItemName = ItemName}) 
end

function Shops:BuyHero(data)
    local item = data.ItemName
    local playerID = data.PlayerID -- The player that clicked on an item to purchase.
    local player = PlayerResource:GetPlayer(playerID)
    local shopID = data.Shop
    local Shop = EntIndexToHScript(data.Shop)

    -- cost of the item
    local Gold_Cost = data.GoldCost
    local Lumber_Cost = data.LumberCost
    
    local buyer = self:ValidateNearbyBuyer(playerID, Shop)
    if not Players:CanTrainMoreHeroes(playerID) then
        self:print("player "..playerID.." tried to create a hero at the tavern(MAX HERO LIMIT REACHED)")
        return
    elseif not self:ValidateNearbyBuyer(playerID, Shop) then
        self:print("No valid buyer nearby tavern for player "..playerID)
        return
    end

    EmitSoundOnClient("General.Buy", player)
    self:print("Tavern creating hero for "..playerID)                      
    Players:CreateHeroFromTavern(playerID, item, shopID)
    
    self:RemoveHeroPanel(shopID, playerID, item)

    -- deduct gold & lumber
    Players:ModifyGold(playerID, -Gold_Cost)
    Players:ModifyLumber(playerID, -Lumber_Cost)

    Scores:IncrementMercenariesHired(playerID)
end

function Shops:ReviveHero(data)
    local item = data.ItemName
    local playerID = data.PlayerID -- The player that clicked on an item to purchase. This can be an allied player
    local player = PlayerResource:GetPlayer(playerID)
    local shopID = data.Shop
    local Shop = EntIndexToHScript(data.Shop)

    -- cost of the item
    local Gold_Cost = data.GoldCost
    local Lumber_Cost = data.LumberCost

    local buyer = self:ValidateNearbyBuyer(playerID, Shop)
    if not buyer then return end
    local buyerPlayerID = buyer:GetPlayerOwnerID()  
    
    EmitSoundOnClient("General.Buy", player)
    self:print("Tavern reviving hero for "..playerID)
    Players:ReviveHeroFromTavern(playerID, item, shopID)
    
    self:RemoveHeroPanel(shopID, playerID, item)
    -- deduct gold & lumber
    Players:ModifyGold(buyerPlayerID, -Gold_Cost)
    Players:ModifyLumber(buyerPlayerID, -Lumber_Cost)
end

function Shops:ValidateNearbyBuyer(playerID, shop)
    -- Information about the buying unit
    local buyer
    if shop.current_unit[playerID] == nil then
        SendErrorMessage(playerID, "#shops_no_buyers_found")
        return
    else
        buyer = shop.current_unit[playerID] --A shop can sell to more than 1 player at a time
    end
    
    return buyer
end

function Shops:BuyItem(data)
    local itemName = data.ItemName
    local playerID = data.PlayerID -- The player that clicked on an item to purchase. This can be an allied player
    local player = PlayerResource:GetPlayer(playerID)
    local shopID = data.Shop
    local shop = EntIndexToHScript(data.Shop)
    
    self:print("Player "..playerID.." trying to buy "..itemName.." from "..shop:GetUnitName().." "..shopID)

    local buyer = self:ValidateNearbyBuyer(playerID, shop)
    if not buyer then return end

    -- cost of the item
    local goldCost = data.GoldCost
    local lumberCost = data.LumberCost

    local isUnitItem = tobool(data.Neutral) -- Unit-items don't need an inventory
    local bEnoughSlots = isUnitItem and true or CountInventoryItems(buyer) < 6
    
    if bEnoughSlots then
        EmitSoundOnClient("General.Buy", player)
        if isUnitItem then
            Players:CreateMercenary(playerID, shopID, itemName)
        else
            buyer:AddItem(CreateItem(itemName, nil, nil))

            Scores:IncrementItemsObtained(playerID)
        end 
        -- lower stock count by 1
        self.Units[shopID].Items[itemName].CurrentStock = self.Units[shopID].Items[itemName].CurrentStock - 1

        if shop:GetKeyValue("ShopType") == "marketplace" then
            shop:RemoveItem(itemName)
        end
        
        -- deduct gold & lumber
        Players:ModifyGold(playerID, -goldCost)
        Players:ModifyLumber(playerID, -lumberCost)
    else
        -- Stock, gold and lumber are checked clientside
        SendErrorMessage(playerID, "#shops_not_enough_inventory")
    end
end

function Shops:AddHeroToTavern(hero)
    local HeroLevel = hero:GetLevel()
    local heroPlayerID = hero:GetPlayerOwnerID()
    
    local GoldCost = BASE_HERO_GOLDCOST + (BASE_HERO_ADDITIONAL_GOLDCOST_PER_LEVEL * HeroLevel)
    local LumberCost = BASE_HERO_LUMBERCOST + (BASE_HERO_ADDITIONAL_LUMBERCOST_PER_LEVEL * HeroLevel)

    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(heroPlayerID), "shops_create_hero_panel", {Index = self.TavernID, playerID=heroPlayerID, HeroInfo={GoldCost=GoldCost, LumberCost=LumberCost, RequiredTier=1} , Hero=hero:GetUnitName(), Revive=true}) 
end

-- Find a shop to open nearby the currently selected unit
function Shops:OpenClosestShop(data)
    local playerID = data.PlayerID
    local player = PlayerResource:GetPlayer(playerID)
    local mainSelected = data.UnitIndex

    self:print("OpenClosestShop near unit "..mainSelected.." of player "..playerID)

    local unit = EntIndexToHScript(mainSelected)
    local shop = self:FindNearby(unit)

    if shop then
        EmitSoundOnClient("Shop.Available", player)
        CustomGameEventManager:Send_ServerToPlayer(player, "shops_open", {Shop=shop:GetEntityIndex()})
    else
        EmitSoundOnClient("Shop.Unavailable", player)
    end
end

-- all the player-specific updates for players
-- make sure to feed it correct player requirement
function Shops:UpdateTavern(playerID)
    local UnitShop = self.Units[self.TavernID]
    local heroCount = Players:HeroCount(playerID)
    local tier = Players:GetCityLevel(playerID)

    local inRequiredTier = heroCount + 1
    
    if inRequiredTier == 4 then
        return
    end
    
    if (inRequiredTier - 1) > 0 then
        for HeroName,_ in pairs(UnitShop.Items) do
            UnitShop.Items[HeroName].GoldCost = NEUTRAL_HERO_GOLDCOST
            UnitShop.Items[HeroName].LumberCost = NEUTRAL_HERO_LUMBERCOST
        end
    end

    for HeroName,_ in pairs(UnitShop.Items) do
        UnitShop.Items[HeroName].RequiredTier = inRequiredTier
    end
end

-- Find one shop in 900 range
function Shops:FindNearby(unit)
    local origin = unit:GetAbsOrigin()
    local team = unit:GetTeamNumber()

    -- iterate through shops
    for k,v in pairs(self.Units) do
        local shop = EntIndexToHScript(k)
        if shop and IsValidAlive(shop) and (shop:GetTeamNumber() == team or shop:GetTeamNumber() == DOTA_TEAM_NEUTRALS) then
            if unit:GetRangeToUnit(shop) < 900 then
                return shop
            end
        end
    end
end


function Shops:print(...)
    if self.Debug then
        print("[Shops] ".. ...)
    end
end

---------------------------------------------------------------------------------------------------

-- The shop will sell all the items placed on its inventory
-- The shop will try to assign a valid buyer to each valid player unit nearby
function ShopThink(event)
    local shop = event.caster
    local ability = event.ability
    local teamNumber = shop:GetTeamNumber()

    -- Sell items in inventory
    for i=0,5 do
        local item = shop:GetItemInSlot(i)
        if item then
            SellCustomItem(item:GetOwner(), item)
        end
    end

    -- Check heroes in radius
    for playerID=0,DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            local playerTeam = PlayerResource:GetTeam(playerID)
            if teamNumber == DOTA_TEAM_NEUTRALS or playerTeam == teamNumber then
                
                local current_unit = shop.current_unit[playerID]

                -- If the shop already has a unit acquired, check if its still valid
                if IsValidAlive(current_unit) then
                    -- Break out of range
                    if shop:GetRangeToUnit(current_unit) > 900 then
                        ResetShop(shop,playerID)                        
                        return
                    end

                    -- If the current_unit is a creature and was autoassigned (not through rightclick), find heroes
                    if current_unit:IsCreature() and not shop.targeted then
                        local foundHero = FindShopAbleUnit(shop, playerID, DOTA_UNIT_TARGET_HERO)
                        if foundHero then
                            event.shop = shop:GetEntityIndex()
                            event.unit = foundHero:GetEntityIndex()
                            event.PlayerID = playerID
                            dotacraft:ShopActiveOrder(event)
                        end
                    end
                else
                    -- Find a nearby units in radius
                    local foundUnit = FindShopAbleUnit(shop, playerID, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC)

                    -- If a valid shop unit is found, update the current hero and set the replicated items
                    if foundUnit then
                        event.shop = shop:GetEntityIndex()
                        event.unit = foundUnit:GetEntityIndex()
                        event.PlayerID = playerID
                        dotacraft:ShopActiveOrder(event)
                    else
                        ResetShop(shop,playerID)
                    end
                end
            end
        end
    end
end

function ResetShop(shop, playerID)
    if shop.active_particle[playerID] then
        ParticleManager:DestroyParticle(shop.active_particle[playerID], true)
    end
    shop.current_unit[playerID] = nil
end

function FindShopAbleUnit(shop, playerID, unit_types)
    local teamNumber = shop:GetTeamNumber()
    local units
    if teamNumber == DOTA_TEAM_NEUTRALS then
        units = FindUnitsInRadius(teamNumber, shop:GetAbsOrigin(), nil, 600, DOTA_UNIT_TARGET_TEAM_ENEMY, unit_types, 0, FIND_CLOSEST, false)
    else
        units = FindUnitsInRadius(teamNumber, shop:GetAbsOrigin(), nil, 900, DOTA_UNIT_TARGET_TEAM_FRIENDLY, unit_types, 0, FIND_CLOSEST, false)
    end

    if units then
        -- Check for heroes
        for k,unit in pairs(units) do
            if unit:IsAlive() and unit:GetPlayerOwnerID() == playerID and unit:IsRealHero() then
                return unit
            end
        end

        -- Check for creature units with inventory
        for k,unit in pairs(units) do
            if unit:IsAlive() and unit:GetPlayerOwnerID() == playerID and not IsCustomBuilding(unit) and unit:HasInventory() and not unit:IsIllusion() then
                return unit
            end
        end

        -- For npc-selling buildings, check any unit
        if shop:SellsUnits() then
            for k,unit in pairs(units) do
                if unit:IsAlive() and unit:GetPlayerOwnerID() == playerID and not unit:IsIllusion() then
                    return unit
                end
            end
        end
    end
    return nil
end

-- Clear the shop when destroyed
function RemoveShop(event)
    local shop = event.caster
    for playerID=0,DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if shop.active_particle[playerID] then
                ParticleManager:DestroyParticle(shop.active_particle[playerID], true)
            end
        end
        shop.current_unit[playerID] = nil
    end
end

if not Shops.Units then Shops:start() end