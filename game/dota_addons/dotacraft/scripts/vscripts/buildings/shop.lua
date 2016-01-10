if not unit_shops then
	unit_shops = class({})
end

function unit_shops:start()
	-- create the Units table
	unit_shops.Units = {}
	unit_shops.Players = {}
	GameRules.HeroTavernEntityID = nil

	CustomGameEventManager:RegisterListener( "Shops_Buy_Item", Dynamic_Wrap(unit_shops, "BuyItem"))
	CustomGameEventManager:RegisterListener( "Shops_Buy_Tavern_Revive_Hero", Dynamic_Wrap(unit_shops, "BuyHeroRevive"))
	CustomGameEventManager:RegisterListener( "Shops_Buy_Tavern_Buy_Hero", Dynamic_Wrap(unit_shops, "BuyHero"))
	
	CustomGameEventManager:RegisterListener( "open_closest_shop", Dynamic_Wrap(unit_shops, "OpenClosestShop"))

	GameRules.Shops = LoadKeyValues("scripts/kv/shops.kv")
	GameRules.GoblinMerchant = LoadKeyValues("scripts/kv/goblin_merchant.kv")
	GameRules.Mercenaries = LoadKeyValues("scripts/kv/mercenaries.kv")
end
	
-- called to create the shop
function Setup_Shop( keys )
	-- Keeps track of the current unit of this shop for every possible player
	keys.caster.current_unit = {}
	keys.caster.active_particle = {}

	local Shop_Name = keys.caster:GetUnitLabel()
	unit_shops:CreateShop(keys.caster, Shop_Name)
end

--[[
	shops[UnitID].CurrentStock is the current stock in store, this holds an array of ints that correlate to the item based on index
	
	shops[UnitID].MaxStocks is the max amount of stock the store can have for that item, this also holds an array of int that correlate to the item based on index

	shops[UnitID].RefreshRate is the time at which an item is restocked, this holds an array of int which represent the amount of seconds it takes to add stock++

	shops[UnitID].CurrentRefreshTime is the time that the item is currently at, this is used as a counter to reference against RefreshRate, once they match we increase stock
--]]

-- neutral hero tavern details
local NEUTRAL_HERO_GOLDCOST = 425
local NEUTRAL_HERO_LUMBERCOST = 135
local NEUTRAL_HERO_FOODCOST = 5
local NEUTRAL_HERO_STOCKTIME = 135

-- player hero revival cost details
local BASE_HERO_GOLDCOST = 255
local BASE_HERO_ADDITIONAL_GOLDCOST_PER_LEVEL = 85
local BASE_HERO_LUMBERCOST = 50
local BASE_HERO_ADDITIONAL_LUMBERCOST_PER_LEVEL = 30

-- this value should be 135, left at 1 for debugging
local NEUTRAL_TAVERN_UNLOCKTIME = 1

function unit_shops:CreateShop(unit, shop_name)
	local UnitID = unit:GetEntityIndex()
	
	if unit_shops.Units[UnitID] == nil then
	-- initialise Shop item table
		unit_shops.Units[UnitID] = {}
		unit_shops.Units[UnitID].Items = {}
	end
	
	if unit_shops.Players[unit:GetPlayerOwnerID()] == nil then
		unit_shops.Players[unit:GetPlayerOwnerID()] = {}
		unit_shops.Players[unit:GetPlayerOwnerID()].Items = {}
	end
	
	local UnitShop = unit_shops.Units[UnitID]
	local playerID = unit:GetPlayerOwnerID()	
	local tier = playerID and Players:GetCityLevel(playerID) or 9000
	
	-- empty sorted table
	local sorted_table = {}
	
	local isTavern = shop_name == "tavern"
	local isGlobal = (shop_name == "goblin_merchant" or shop_name == "mercenary" or shop_name == "goblin_lab")
	local isUnitShop = (shop_name == "mercenary" or shop_name == "goblin_lab") -- does not include tavern
	
	-- Shops that sell npc units can sell to units without inventory
	if shop_name == "mercenary" or shop_name == "goblin_lab" or shop_name == "tavern" then
		unit.SellsNPCs = true
	end

	local shopEnt = Entities:FindByName(nil, "*custom_shop") -- entity name in hammer
	if shopEnt then
		local modelName = shopEnt:GetModelName()
		local newshop = SpawnEntityFromTableSynchronous('trigger_shop', {origin = unit:GetAbsOrigin(), shoptype = 1, model = modelName}) -- shoptype is 0 for a "home" shop, 1 for a side shop and 2 for a secret shop
		unit_shops:print("CreateShop out of "..modelName)
	else
		unit_shops:print("ERROR: CreateShop was unable to find a custom_shop trigger area. Add a custom_shop trigger to this map")
	end
	
	local shopList = GameRules.Shops[shop_name]

	-- Mercenaries take their list based on the tileset
	if shop_name == "mercenary" then
		local mapName = string.sub(GetMapName(), string.find(GetMapName(), '_', 1, true)+1)
		local tileset = GameRules.Mercenaries["Maps"][mapName]
		unit_shops:print("Mercenary shop for "..mapName,tileset)
		shopList = GameRules.Mercenaries[tileset]
	end

	for order,itemname in pairs(shopList) do
		unit_shops:print("Creating timer for "..itemname.." new unit shop: "..shop_name)
		local key = itemname

		-- set all variables
		UnitShop.Items[key] = {}
		UnitShop.Items[key].ItemName = key
		UnitShop.Items[key].CurrentRefreshTime = 1
		local Item = UnitShop.Items[key]
		
		local grTable
		-- Mercenary and Goblin Lab take values from unit kv files
		if shop_name == "mercenary" or shop_name == "goblin_lab" then
			grTable = GameRules.UnitKV

		-- Merchant uses a different stock system and tiers for items
		elseif shop_name == "goblin_merchant" then
			grTable = GameRules.GoblinMerchant

		-- Other shops take the values directly from the item kv
		else
			grTable = GameRules.ItemKV
		end
		
		-- Tavern heroes initially cost only food
		if isTavern then
			Item.CurrentStock = 0
			Item.MaxStock = 1
			Item.RequiredTier = 9000
			Item.GoldCost = 0
			Item.LumberCost = 0
			Item.FoodCost = 5
			Item.RestockRate = NEUTRAL_HERO_STOCKTIME		
		else
			Item.CurrentStock = grTable[key]["StockInitial"] or 1
			Item.MaxStock = grTable[key]["StockMax"] or 1
			Item.RequiredTier = grTable[key]["RequiresTier"] or 0
			Item.GoldCost = grTable[key]["ItemCost"] or grTable[key]["GoldCost"] or 0
			Item.LumberCost = grTable[key]["LumberCost"] or 0
			Item.FoodCost = grTable[key]["FoodCost"] or 0
			Item.RestockRate = grTable[key]["StockTime"] or 0
			Item.StockStartDelay = grTable[key]["StockStartDelay"] or 0
		end

		if isTavern then
			unit_shops:TavernStockUpdater(Item, unit)
		else
			unit_shops:StockUpdater(Item, unit, isGlobal)
		end
		
		-- save item into table using it's sort index, this is send once at the beginning to initialise the shop
		sorted_table[tonumber(order)] = UnitShop.Items[key]
	end

	-- Create shop panels
	unit_shops:SetupShopPanels(unit, sorted_table, isTavern, isGlobal, isUnitShop, tier, shop_name)
end

local SHOPS_PRINT = false
function unit_shops:print( ... )
	if SHOPS_PRINT then
		 print("[SHOPS] ".. ...)
	end
end

function unit_shops:SetupShopPanels(unit, ShopItemTable, isTavern, isGlobal, isUnitShop, RequiredTier, ShopName)
	local UnitID = unit:GetEntityIndex()
	local team = unit:GetTeam()
	if not isTavern then
		--unit_shops:print("Create "..shop_name.." "..UnitID.." Tier "..tier)
		if isGlobal then
			CustomGameEventManager:Send_ServerToAllClients("Shops_Create", {Index = UnitID, Shop = ShopItemTable, Tier=0, Race=ShopName, Neutral = isUnitShop}) 		
		else
			CustomGameEventManager:Send_ServerToTeam(team, "Shops_Create", {Index = UnitID, Shop = ShopItemTable, Tier=RequiredTier, Race=ShopName }) 
		end
	else
		GameRules.HeroTavernEntityID = UnitID
		CustomGameEventManager:Send_ServerToAllClients("Shops_Create", {Index = UnitID, Shop = ShopItemTable, Tier=RequiredTier, Tavern = true}) 
		--unit_shops:print("Create Tavern "..GameRules.HeroTavernEntityID)		
	end

end

function unit_shops:TavernStockUpdater(UnitShopItem, unit)
	Timers:CreateTimer(0.1, function()
		local PlayerCount = PlayerResource:GetPlayerCount() - 1
		unit_shops:Stock_Management(UnitShopItem)
		
		-- check all players hero count
		for playerID=0, PlayerCount do
			
			local hero = PlayerResource:GetSelectedHeroEntity(playerID)			
			if PlayerResource:IsValidPlayer(playerID) and hero then
				local player = PlayerResource:GetPlayer(playerID)						
				
				-- if player cannot train more heroes and tavern wasn't previously disabled, disable it now		
				if not Players:CanTrainMoreHeroes( playerID ) then
					CustomGameEventManager:Send_ServerToPlayer(player, "Shops_Remove_Content", {Index = GameRules.HeroTavernEntityID, Shop = UnitShopItem, playerID = i}) 
					unit_shops:print("remove neutral heroes panels from player="..tostring(playerID))
					return
				end
				
				UpdateHeroTavernForPlayer( playerID )
				local tier = Players:GetCityLevel(playerID) or 9000
				local hasAltar = Players:HasAltar(playerID) and true or false
				
				CustomGameEventManager:Send_ServerToPlayer(player, "unitshop_updateStock", { Index = GameRules.HeroTavernEntityID, Item = UnitShopItem, playerID = playerID, Tier=tier, Altar=hasAltar})
			end
			
		end
	
		return 0.01
	end)
end

function unit_shops:StockUpdater(UnitShopItem, unit, isGlobal)
	local UnitID = unit:GetEntityIndex()
	local team = unit:GetTeam()
	Timers:CreateTimer(1, function()
		local playerID = unit:GetPlayerOwnerID()	
		local tier = playerID and Players:GetCityLevel(playerID) or 9000

		if not IsValidEntity(unit) or not unit:IsAlive() then
			-- send command to kill shop panel
			unit_shops:print("Shop identified not valid, terminating timer")
			return
		end

		unit_shops:Stock_Management(UnitShopItem)
		if PlayerResource:IsValidPlayer(playerID) or isGlobal then
			CustomGameEventManager:Send_ServerToAllClients("unitshop_updateStock", { Index = UnitID, Item = UnitShopItem, Tier=tier })		
		end
		
		return 1
	end)
end

function unit_shops:Stock_Management(UnitShopItem)
	-- if the item is not at max stock start a counter until it's restocked
	
	if UnitShopItem.CurrentStock < UnitShopItem.MaxStock then
	
		if UnitShopItem.StockStartDelay ~= 0 and UnitShopItem.CurrentRefreshTime == UnitShopItem.StockStartDelay then
			-- this is might need altering, currently its abit hardcoded
			UnitShopItem.CurrentStock = UnitShopItem.MaxStock
			
			-- set to 0 to stop condition from being met so that it resumes normal restocking rates
			UnitShopItem.StockStartDelay = 0
			
			-- reset counter for next stock
			UnitShopItem.CurrentRefreshTime = 1
			unit_shops:print("Increasing stock count by 1 for global shop")
		elseif UnitShopItem.CurrentRefreshTime == UnitShopItem.RestockRate then
			-- increase stock by 1 when the currentrefreshtime == the refreshrate
			UnitShopItem.CurrentStock = UnitShopItem.CurrentStock + 1
			
			-- reset counter for next stock
			UnitShopItem.CurrentRefreshTime = 1
			unit_shops:print("Increasing stock count by 1")
		else
			--unit_shops:print("Incrementing counter to restock")
			-- increment the time counter
			UnitShopItem.CurrentRefreshTime = UnitShopItem.CurrentRefreshTime + 1
		end
	
	end
end

function unit_shops:RemoveHeroPanel(ShopEntityIndex, playerID, ItemName)
	unit_shops:print("Deleting hero panel")
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "Shops_Delete_Single_Panel", {Index = ShopEntityIndex, Hero = ItemName}) 
end

function unit_shops:BuyHero(data)
	local item = data.ItemName
	local playerID = data.PlayerID -- The player that clicked on an item to purchase.
	local player = PlayerResource:GetPlayer(playerID)
	local shopID = data.Shop
	local Shop = EntIndexToHScript(data.Shop)

	-- cost of the item
	local Gold_Cost = data.GoldCost
	local Lumber_Cost = data.LumberCost
	
	local buyer = unit_shops:ValidateNearbyBuyer(playerID, Shop)
	if not Players:CanTrainMoreHeroes( playerID ) or not unit_shops or not buyer then
		if buyer or unit_shops then
			unit_shops:print("playerID = "..tostring(playerID).." tried to create a hero at the tavern(MAX HERO LIMIT REACHED)")
		end
		return
	end

	EmitSoundOnClient("General.Buy", player)
	unit_shops:print("Tavern creating hero for "..playerID)						
	TavernCreateHeroForPlayer(playerID, shopID, item)
	
	unit_shops:RemoveHeroPanel(shopID, playerID, item)

	-- deduct gold & lumber
	Players:ModifyGold(playerID, -Gold_Cost)
	Players:ModifyLumber(playerID, -Lumber_Cost)
end

function unit_shops:BuyHeroRevive(data)
	local item = data.ItemName
	local playerID = data.PlayerID -- The player that clicked on an item to purchase. This can be an allied player
	local player = PlayerResource:GetPlayer(playerID)
	local shopID = data.Shop
	local Shop = EntIndexToHScript(data.Shop)
	-- cost of the item
	local Gold_Cost = data.GoldCost
	local Lumber_Cost = data.LumberCost

	local buyer = unit_shops:ValidateNearbyBuyer(playerID, Shop)
	if not buyer then return end
	local buyerPlayerID = buyer:GetPlayerOwnerID()	
	
	EmitSoundOnClient("General.Buy", player)
	unit_shops:print("Tavern reviving hero for "..playerID)
	TavernReviveHeroForPlayer(playerID, shopID, item)
	
	unit_shops:RemoveHeroPanel(shopID, playerID, item)
	-- deduct gold & lumber
	Players:ModifyGold(buyerPlayerID, -Gold_Cost)
	Players:ModifyLumber(buyerPlayerID, -Lumber_Cost)
end

function unit_shops:ValidateNearbyBuyer( playerID, Shop )
	-- Information about the buying unit
	local buyer
	if Shop.current_unit[playerID] == nil then
		SendErrorMessage(playerID, "#shops_no_buyers_found")
		return
	else
		buyer = Shop.current_unit[playerID] --A shop can sell to more than 1 player at a time
	end
	
	return buyer
end

function unit_shops:BuyItem(data)
	local item = data.ItemName
	local playerID = data.PlayerID -- The player that clicked on an item to purchase. This can be an allied player
	local player = PlayerResource:GetPlayer(playerID)
	local shopID = data.Shop
	local Shop = EntIndexToHScript(data.Shop)
	
	unit_shops:print("Player "..playerID.." trying to buy "..item.." from "..data.Shop.." "..shopID)

	local buyer = unit_shops:ValidateNearbyBuyer(playerID, Shop)
	if not buyer then return end
	local buyerPlayerID = buyer:GetPlayerOwnerID()
	local buyerPlayerOwner = buyer:GetPlayerOwner()
	-- hero of the buying unit
	local buyerHero = buyerPlayerOwner:GetAssignedHero()
	
	-- Issue with script_reload
	if not unit_shops then return end

	-- cost of the item
	local Gold_Cost = data.GoldCost
	local Lumber_Cost = data.LumberCost

	local isUnitItem = tobool(data.Neutral)
	local bEnoughSlots = isUnitItem and true or CountInventoryItems(buyer) < 6
	
	if bEnoughSlots then
		EmitSoundOnClient("General.Buy", player)
		if isUnitItem then
			CreateMercenaryForPlayer(playerID, shopID, item)
		else
			local Bought_Item = CreateItem(item, buyerPlayerOwner, buyerPlayerOwner)
			buyer:AddItem(Bought_Item)
		end	
		-- lower stock count by 1
		Purchased(item, Shop)
		
		-- deduct gold & lumber
		Players:ModifyGold(buyerPlayerID, -Gold_Cost)
		Players:ModifyLumber(buyerPlayerID, -Lumber_Cost)
	else
		-- player error message
		--if not bEnoughStock then -- not enough stock
		--	SendErrorMessage(buyerPlayerID, "#shops_not_enough_stock")
		--elseif not bEnoughSlots then -- not enough inventory space
			SendErrorMessage(buyerPlayerID, "#shops_not_enough_inventory")
		--elseif not bHasEnoughGold then -- not enough gold
		--	SendErrorMessage(buyerPlayerID, "#shops_not_enough_gold")
		--elseif not bHasEnoughLumber then -- not enough lumber
		--	SendErrorMessage(buyerPlayerID, "#shops_not_enough_lumber")
		--end	
	end
end

function unit_shops:AddHeroToTavern(hero)
	local HeroLevel = hero:GetLevel()
	local heroPlayerID = hero:GetPlayerOwnerID()
	
	local GoldCost = BASE_HERO_GOLDCOST + (BASE_HERO_ADDITIONAL_GOLDCOST_PER_LEVEL * HeroLevel)
	local LumberCost = BASE_HERO_LUMBERCOST + (BASE_HERO_ADDITIONAL_LUMBERCOST_PER_LEVEL * HeroLevel)

	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(heroPlayerID), "Shops_Create_Single_Panel", {Index = GameRules.HeroTavernEntityID, playerID=heroPlayerID, HeroInfo={GoldCost=GoldCost, LumberCost=LumberCost, RequiredTier = 1} , Hero=hero:GetUnitName(), Revive = true}) 
end	

-- all the player-specific updates for players
-- make sure to feed it correct player requirement
function UpdateHeroTavernForPlayer(playerID)

	local UnitShop = unit_shops.Units[GameRules.HeroTavernEntityID]
	local player = PlayerResource:GetPlayer(playerID)
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

function TavernCreateHeroForPlayer(playerID, shopID, HeroName)
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()
	local unit_name = HeroName
	local tavern = EntIndexToHScript(shopID)

	-- Add food cost
	Players:ModifyFoodUsed(playerID, 5)

	-- Acquired ability
	local train_ability_name = "neutral_train_"..HeroName
	train_ability_name = string.gsub(train_ability_name, "npc_dota_hero_" , "")
	
	-- Add the acquired ability to each altar
	local altarStructures = Players:GetAltars(playerID)
	for _,altar in pairs(altarStructures) do
		local acquired_ability_name = train_ability_name.."_acquired"
		TeachAbility(altar, acquired_ability_name)
		SetAbilityLayout(altar, 5)	
	end

	-- Increase the altar tier
	dotacraft:IncreaseAltarTier( playerID )

	-- handle_UnitOwner needs to be nil, else it will crash the game.
	PrecacheUnitByNameAsync(unit_name, function()
		local new_hero = CreateUnitByName(unit_name, tavern:GetAbsOrigin(), true, hero, nil, hero:GetTeamNumber())
		new_hero:SetPlayerID(playerID)
		new_hero:SetControllableByPlayer(playerID, true)
		new_hero:SetOwner(player)
		FindClearSpaceForUnit(new_hero, tavern:GetAbsOrigin(), true)

		new_hero:RespawnUnit()
		
		-- Add a teleport scroll
		local tpScroll = CreateItem("item_scroll_of_town_portal", new_hero, new_hero)
		new_hero:AddItem(tpScroll)
		tpScroll:SetPurchaseTime(0) --Dont refund fully

		-- Add the hero to the table of heroes acquired by the player
		Players:AddHero( playerID, new_hero )

		--Reference to swap to a revive ability when the hero dies
		new_hero.RespawnAbility = train_ability_name 

		Setup_Hero_Panel(new_hero)
	end, playerID)
end

function TavernReviveHeroForPlayer(playerID, shopID, HeroName)
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()
	local hero_name = HeroName
	local tavern = EntIndexToHScript(shopID)
	local health_factor = 0.5
	local ability_name --Ability on the altars, needs to be removed after the hero is revived
	local level

	local playerHeroes = Players:GetHeroes(playerID)
	for k,hero in pairs(playerHeroes) do
		if hero:GetUnitName() == HeroName then
			hero:RespawnUnit()
			FindClearSpaceForUnit(hero, tavern:GetAbsOrigin(), true)
			hero:SetMana(0)
			hero:SetHealth(hero:GetMaxHealth() * health_factor)
			ability_name = hero.RespawnAbility
			level = hero:GetLevel()
			unit_shops:print("Revived "..hero_name.." with 50% Health at Level "..hero:GetLevel())
		end
	end

	ability_name =  ability_name.."_revive"..level
	
	-- Swap the _revive ability on the altars for a _acquired ability
	local altarStructures = Players:GetAltars(playerID)
	for _,altar in pairs(altarStructures) do
		local new_ability_name = string.gsub(ability_name, "_revive" , "")
		new_ability_name = GetResearchAbilityName(new_ability_name) --Take away numbers or research
		new_ability_name = new_ability_name.."_acquired"

		unit_shops:print("new_ability_name is "..new_ability_name..", it will replace: "..ability_name)

		altar:AddAbility(new_ability_name)
		altar:SwapAbilities(ability_name, new_ability_name, false, true)
		altar:RemoveAbility(ability_name)
		
		local new_ability = altar:FindAbilityByName(new_ability_name)
		new_ability:SetLevel(new_ability:GetMaxLevel())

		PrintAbilities(altar)
	end
end

function CreateMercenaryForPlayer(playerID, shopID, unitName)
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()
	local shop = EntIndexToHScript(shopID)
	local mercenary = CreateUnitByName(unitName, shop:GetAbsOrigin(), true, hero, player, hero:GetTeamNumber())
	mercenary:SetControllableByPlayer(playerID, true)
	mercenary:SetOwner(hero)

	-- Add food cost
	Players:ModifyFoodUsed(playerID, 5)

	-- Add to player table
	Players:AddUnit(playerID, mercenary)
end

-- Find a shop to open nearby the currently selected unit
function unit_shops:OpenClosestShop(data)
	local playerID = data.PlayerID
	local player = PlayerResource:GetPlayer(playerID)
	local mainSelected = data.UnitIndex

	unit_shops:print("OpenClosestShop near unit "..mainSelected.." of player "..playerID)

	local unit = EntIndexToHScript(mainSelected)
	local shop = FindClosestShop(unit)

	if shop then
		EmitSoundOnClient("Shop.Available", player)
		CustomGameEventManager:Send_ServerToPlayer(player, "Shops_Open", {Shop=shop:GetEntityIndex()})
	else
		EmitSoundOnClient("Shop.Unavailable", player)
	end
end

-- Find one shop in 900 range
function FindClosestShop( unit )
	local origin = unit:GetAbsOrigin()
	local team = unit:GetTeamNumber()

	-- iterate through shops
	for k,v in pairs(unit_shops.Units) do
		local shop = EntIndexToHScript(k)
		if shop and IsValidAlive(shop) and (shop:GetTeamNumber() == team or shop:GetTeamNumber() == DOTA_TEAM_NEUTRALS) then
			if unit:GetRangeToUnit(shop) < 900 then
				return shop
			end
		end
	end
end

function Purchased(item, shop)
	unit_shops.Units[shop:GetEntityIndex()].Items[item].CurrentStock = unit_shops.Units[shop:GetEntityIndex()].Items[item].CurrentStock - 1
end

function EnoughStock(item, shop)
	local Stock = unit_shops.Units[shop:GetEntityIndex()].Items[item].CurrentStock

	if Stock > 0 then
		return true
	else
		return false
	end
end

function SellItemsInInventory( event )
	local shop = event.caster
	for i=0,5 do
		local item = shop:GetItemInSlot(i)
		if item then
			SellCustomItem(item:GetOwner(), item)
		end
	end
end

-- The shop will try to assign a valid buyer to each valid player unit nearby
function CheckHeroInRadius( event )
	local shop = event.caster
	local ability = event.ability
	local teamNumber = shop:GetTeamNumber()

	for playerID=0,DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayerID(playerID) then
			local playerTeam = PlayerResource:GetTeam(playerID)
			if teamNumber == DOTA_TEAM_NEUTRALS or playerTeam == teamNumber then
				
				local current_unit = shop.current_unit[playerID]

				-- If the shop already has a unit acquired, check if its still valid
				if IsValidAlive(current_unit) then
					-- Break out of range
					if shop:GetRangeToUnit(current_unit) > 900 then
						if shop.active_particle[playerID] then
					        ParticleManager:DestroyParticle(shop.active_particle[playerID], true)
					    end
					    shop.current_unit[playerID] = nil
					    
					    return
					end

					-- If the current_unit is a creature and was autoassigned (not through rightclick), find heroes
					if current_unit:IsCreature() and not shop.targeted then
						local foundHero = FindShopAbleUnit(shop, DOTA_UNIT_TARGET_HERO)
						if foundHero then
							event.shop = shop:GetEntityIndex()
							event.unit = foundHero:GetEntityIndex()
							event.PlayerID = playerID
							dotacraft:ShopActiveOrder(event)
						end
					end		
				else
					-- Find a nearby units in radius
					local foundUnit = FindShopAbleUnit(shop, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC)

					-- If a valid shop unit is found, update the current hero and set the replicated items
					if foundUnit then
						event.shop = shop:GetEntityIndex()
						event.unit = foundUnit:GetEntityIndex()
						event.PlayerID = playerID
						dotacraft:ShopActiveOrder(event)
					end
				end
			end
		end
	end
end

function FindShopAbleUnit( shop, unit_types )
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
			if string.match(unit:GetClassname(),"npc_dota_hero") then
				return unit
			end
		end

		-- Check for creature units with inventory
		for k,unit in pairs(units) do
			if not IsCustomBuilding(unit) and unit:HasInventory() then
				return unit
			end
		end

		-- For npc-selling buildings, check any unit
		if shop.SellsNPCs then
			for k,unit in pairs(units) do
				return unit
			end
		end
	end
	return nil
end

function RemoveShop( event )
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

if not unit_shops.Units then unit_shops:start() end