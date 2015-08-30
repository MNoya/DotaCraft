if unit_shops == nil then
	unit_shops = class({})
	
	-- create the Units table
	unit_shops.Units = {}
	unit_shops.Players = {}
	HeroTavernEntityID = nil
	
	-- register listeners
	CustomGameEventManager:RegisterListener( "Shops_Buy", Dynamic_Wrap(unit_shops, "Buy"))
	CustomGameEventManager:RegisterListener( "open_closest_shop", Dynamic_Wrap(unit_shops, "OpenClosestShop"))

	GameRules.Shops = LoadKeyValues("scripts/kv/shops.kv")
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

	shops[UnitID].RefreshRate is the time at which an item is restocked, this holds an array of int which represent the amount of seconds it takes to add stock++;

	shops[UnitID].CurrentRefreshTime is the time that the item is currently at, this is used as a counter to reference against RefreshRate, once they match we increase stock
--]]
local NEUTRAL_HERO_GOLDCOST = 425
local NEUTRAL_HERO_LUMBERCOST = 135
local NEUTRAL_HERO_FOODCOST = 5
local NEUTRAL_HERO_STOCKTIME = 135

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
	local player = unit:GetPlayerOwner()	
	local tier = player and GetPlayerCityLevel(player) or 9000
	
	-- empty sorted table
	local sorted_table = {}
	
	local shopEnt = Entities:FindByName(nil, "*custom_shop") -- entity name in hammer
	if shopEnt then
		local newshop = SpawnEntityFromTableSynchronous('trigger_shop', {origin = unit:GetAbsOrigin(), shoptype = 1, model="maps/hills_of_glory/entities/custom_shop_0.vmdl"}) -- shoptype is 0 for a "home" shop, 1 for a side shop and 2 for a secret shop
		print("CreateShop out of "..shopEnt:GetModelName())
	else
		print("ERROR: CreateShop was unable to find a custom_shop trigger area. Add a custom_shop trigger to this map")
	end
	
	-- for each item create an corresponding timer to restock that item
	--DeepPrintTable(GameRules.Shops["human_shop"])
	DeepPrintTable(GameRules.Shops[shop_name])
	for order,item in pairs(GameRules.Shops[shop_name]) do
		print("[UNIT SHOP] Creating timer for "..item.." new unit shop: "..shop_name)
		local key = item

		-- set all variables
		UnitShop.Items[key] = {}
		UnitShop.Items[key].ItemName = key
		UnitShop.Items[key].CurrentRefreshTime = 1
		
		if shop_name ~= "tavern" then
			UnitShop.Items[key].CurrentStock = GameRules.ItemKV[key]["StockInitial"]
			UnitShop.Items[key].MaxStock = GameRules.ItemKV[key]["StockMax"]
			UnitShop.Items[key].RequiredTier = GameRules.ItemKV[key]["RequiresTier"]
			UnitShop.Items[key].GoldCost = GameRules.ItemKV[key]["ItemCost"]
			UnitShop.Items[key].RestockRate = GameRules.ItemKV[key]["StockTime"]
						
			--DeepPrintTable(UnitShop.Items[key])
			-- set to 0 if nil, "0" hides the value in panaroma
			if GameRules.ItemKV[key]["LumberCost"] ~= nil then
				UnitShop.Items[key].LumberCost = GameRules.ItemKV[key]["LumberCost"]
			else
				UnitShop.Items[key].LumberCost = 0
			end
		
		else
			UnitShop.Items[key].CurrentStock = 1
			UnitShop.Items[key].MaxStock = 1
			UnitShop.Items[key].RequiredTier = 9000
			UnitShop.Items[key].GoldCost = NEUTRAL_HERO_GOLDCOST
			UnitShop.Items[key].LumberCost = NEUTRAL_HERO_LUMBERCOST
			UnitShop.Items[key].RestockRate = NEUTRAL_HERO_STOCKTIME
		end

		-- Set some defaults incase the keys are missing in the item definition
		if not UnitShop.Items[key].CurrentStock then
			print("[UNIT SHOP] Error - No StockInitial defined for "..item)
			UnitShop.Items[key].CurrentStock = 1
		end

		if not UnitShop.Items[key].MaxStock then
			print("[UNIT SHOP] Error - No StockMax defined for "..item)
			UnitShop.Items[key].MaxStock = 1
		end

		if not UnitShop.Items[key].RestockRate then
			print("[UNIT SHOP] Error - No StockTime defined for "..item)
			UnitShop.Items[key].RestockRate = 1
		end

		if not UnitShop.Items[key].RequiredTier then
			print("[UNIT SHOP] Error - No RequiresTier defined for "..item)
			UnitShop.Items[key].RequiredTier = 1
		end

		Timers:CreateTimer(1, function()
			tier = player and GetPlayerCityLevel(player) or 9000

			if not IsValidEntity(unit) or not unit:IsAlive() then
				-- send command to kill shop panel
				UnitShop = nil
				print("[UNIT SHOP] Shop identified not valid, terminating timer")
				return
			end

			-- if the item is not at max stock start a counter until it's restocked
			if UnitShop.Items[key].CurrentStock < UnitShop.Items[key].MaxStock then
			
				if UnitShop.Items[key].CurrentRefreshTime == UnitShop.Items[key].RestockRate then
					-- increase stock by 1 when the currentrefreshtime == the refreshrate
					UnitShop.Items[key].CurrentStock = UnitShop.Items[key].CurrentStock + 1
					
					-- reset counter for next stock
					UnitShop.Items[key].CurrentRefreshTime = 1
					print("[UNIT SHOP] Increasing stock count by 1")
				else
					--print("[UNIT SHOP] Incrementing counter to restock")
					-- increment the time counter
					UnitShop.Items[key].CurrentRefreshTime = UnitShop.Items[key].CurrentRefreshTime + 1
				end
			
			end
				-- set nettable update
				SetNetTableValue("dotacraft_shops_table", tostring(UnitID), { Index = UnitID, Shop = UnitShop, Tier=tier})
			return 1
		end)
		
		-- save item into table using it's sort index, this is send once at the beginning to initialise the shop
		sorted_table[tonumber(order)] = UnitShop.Items[key]
	end

	local team = unit:GetTeam()
	if shop_name ~= "tavern" then
		print("[UNIT SHOP] Create "..shop_name.." "..UnitID.." Tier "..tier)
		DeepPrintTable(sorted_table)
		CustomGameEventManager:Send_ServerToTeam(team, "Shops_Create", {Index = UnitID, Shop = sorted_table, Tier=tier, Race=shop_name }) 
	else
		HeroTavernEntityID = UnitID
		CustomGameEventManager:Send_ServerToAllClients("Shops_Create", {Index = UnitID, Shop = sorted_table, Tier=tier, Tavern = true}) 
		print("[UNIT SHOP] Create Tavern "..HeroTavernEntityID)
		DeepPrintTable(sorted_table)
	
		-- make panels available after 135seconds
		Timers:CreateTimer(NEUTRAL_TAVERN_UNLOCKTIME, function()
			
			for HeroName,Kaapa in pairs(UnitShop.Items) do
				UnitShop.Items[HeroName].RequiredTier = 1
			end
			print("[UNIT SHOPS] Unlocking neutral hero tavern")
			SetNetTableValue("dotacraft_shops_table", tostring(UnitID), { Index = UnitID, Shop = UnitShop, Tier=tier}) 
		end)
		
	end
end

-- call this function to make the hero tavern put all it's item requirements 1 tier higher
-- make sure to feed it correct player requirement
function Increment_Hero_Tavern_Tier_Requirement(PlayerID)
	local UnitShop = unit_shops.Units[HeroTavernEntityID]
	
	for HeroName,Kaapa in pairs(UnitShop.Items) do
		UnitShop.Items[HeroName].RequiredTier = UnitShop.Items[HeroName].RequiredTier + 1
	end
	
	SetNetTableValue("dotacraft_shops_table", tostring(UnitID), { Index = UnitID, Shop = UnitShop, Tier=tier, PlayerID = PlayerID}) 
end

function unit_shops:Buy(data)
	local item = data.ItemName
	local PlayerID = data.PlayerID -- The player that clicked on an item to purchase. This can be an allied player
	local player = PlayerResource:GetPlayer(PlayerID)
	local Shop = EntIndexToHScript(data.Shop)
	
	-- Check whether hero item or no
	local isHeroItem = Boolize(data.Hero)
	local isTavern = Boolize(data.Tavern)
	
	-- check current tier
	local shopOwner = Shop:GetPlayerOwner()
	local tier = shopOwner and GetPlayerCityLevel(shopOwner) or GetPlayerCityLevel(player) --If there is no owner, use the tier of the player that tries to buy it
				
	-- Information about the buying unit
	-- the buying unit
	local buyer
	if Shop.current_unit[PlayerID] == nil then
		SendErrorMessage(data.PlayerID, "#shops_no_buyers_found")
		return
	else
		buyer = Shop.current_unit[PlayerID] --A shop can sell to more than 1 player at a time
	end
	
	local buyerPlayerID = buyer:GetPlayerOwnerID()
	local buyerPlayerOwner = buyer:GetPlayerOwner()
	-- hero of the buying unit
	local buyerHero = buyerPlayerOwner:GetAssignedHero()
	
	-- Issue with script_reload
	if not unit_shops then return end

	-- cost of the item
	local Gold_Cost = data.GoldCost
	local Lumber_Cost = data.LumberCost

	-- Conditions
	local bHasEnoughGold = PlayerHasEnoughGold(buyerPlayerOwner, GoldCost)
	local bHasEnoughLumber = PlayerHasEnoughLumber(buyerPlayerOwner, Lumber_Cost )
	
	local bEnoughSlots
	local bEnoughStock
	if not isHeroItem and not isTavern then
		bEnoughSlots = EnoughStock(item, Shop)
		bEnoughStock = CountInventoryItems(buyer) < 6
	else -- reviving a hero doesn't need slots or stock
		bEnoughSlots = true
		bEnoughStock = true
	end
		
	--DeepPrintTable(GameRules.Shops["human_shop"])
	if bPlayerCanPurchase then

		EmitSoundOnClient("General.Buy", player)

		if not isHeroItem or isTavern then
			-- lower stock count by 1
			Purchased(item, Shop)

			-- create & add item
			if not isTavern then
				local Bought_Item = CreateItem(item, buyerPlayerOwner, buyerPlayerOwner) 
				buyer:AddItem(Bought_Item)
			else -- if it is tavern create hero
				print("Creating hero")
				-- increments tavern tier requirement by 1 
				Increment_Hero_Tavern_Tier_Requirement(PlayerID)
				
				-- create neutral hero here
			end
		else -- revive hero here (dead heroes)
			print("revive a hero")
			-- revive hero here, NOYA DO IT, JUST DO IT
		end
		-- deduct gold & lumber
		PlayerResource:SpendGold(buyerPlayerID, Gold_Cost, 0)
		ModifyLumber(buyerPlayerOwner, Lumber_Cost)
		
		local UnitShop =  unit_shops.Units[data.Shop]
		
		if not isHeroItem or isTavern then -- update shop
			SetNetTableValue("dotacraft_shops_table", tostring(data.Shop), { Shop = UnitShop, Tier=tier })
		else -- delete panel of hero
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "Shops_Delete_Single_Panel", {Index = data.Shop, Hero = data.ItemName }) 
		end
	else -- error messaging
	
		-- player error message
		if not bEnoughStock then -- not enough stock
			SendErrorMessage(buyerPlayerID, "#shops_not_enough_stock")
		elseif not bEnoughSlots then -- not enough inventory space
			SendErrorMessage(buyerPlayerID, "#shops_not_enough_inventory")
		elseif not bHasEnoughGold then -- not enough gold
			SendErrorMessage(buyerPlayerID, "#shops_not_enough_gold")
		elseif not bHasEnoughLumber then -- not enough lumber
			SendErrorMessage(buyerPlayerID, "#shops_not_enough_lumber")
		end	
	end
end

function Boolize(value)
	if (value == 1 or value == true) then
		return true
	else
		return false
	end
end

-- Find a shop to open nearby the currently selected unit
function unit_shops:OpenClosestShop(data)
	local PlayerID = data.PlayerID
	local player = PlayerResource:GetPlayer(PlayerID)
	local mainSelected = data.UnitIndex

	print("OpenClosestShop near unit "..mainSelected.." of player "..PlayerID)

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
			local player = PlayerResource:GetPlayer(playerID)
			if teamNumber == DOTA_TEAM_NEUTRALS or player:GetTeamNumber() == teamNumber then
				
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
	local units = FindUnitsInRadius(shop:GetTeamNumber(), shop:GetAbsOrigin(), nil, 900, DOTA_UNIT_TARGET_TEAM_FRIENDLY, unit_types, 0, FIND_CLOSEST, false)
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
	end
	return nil
end