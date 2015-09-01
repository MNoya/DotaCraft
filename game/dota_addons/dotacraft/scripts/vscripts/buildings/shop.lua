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

-- neutral hero tavern details
local NEUTRAL_HERO_GOLDCOST = 425
local NEUTRAL_HERO_LUMBERCOST = 135
local NEUTRAL_HERO_FOODCOST = 5
local NEUTRAL_HERO_STOCKTIME = 135

-- player hero revival cost details
local BASE_HERO_GOLDCOST = 340
local BASE_HERO_ADDITIONAL_GOLDCOST_PER_LEVEL = 85
local BASE_HERO_LUMBERCOST = 80
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
	local player = unit:GetPlayerOwner()	
	local tier = player and GetPlayerCityLevel(player) or 9000
	
	-- empty sorted table
	local sorted_table = {}
	
	-- isTavern so we can check whether to setnettable updating
	local isTavern = false
	if shop_name == "tavern" then
		isTavern = true
	end
	
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
			UnitShop.Items[key].CurrentStock = 0
			UnitShop.Items[key].MaxStock = 1
			UnitShop.Items[key].RequiredTier = 9000
			UnitShop.Items[key].GoldCost = 0
			UnitShop.Items[key].LumberCost = 0
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

		if not isTavern then -- if not tavern
			Timers:CreateTimer(1, function()
				tier = player and GetPlayerCityLevel(player) or 9000

				if not IsValidEntity(unit) or not unit:IsAlive() then
					-- send command to kill shop panel
					UnitShop = nil
					print("[UNIT SHOP] Shop identified not valid, terminating timer")
					return
				end

				unit_shops:Stock_Management(UnitShop, key)
				
				-- set nettable
				SetNetTableValue("dotacraft_shops_table", tostring(UnitID), { Index = UnitID, Shop = UnitShop, Tier=tier})
				
				return 1
			end)
		else
		
			Timers:CreateTimer(0.1, function()
				local PlayerCount = PlayerResource:GetPlayerCount() - 1
				unit_shops:Stock_Management(UnitShop, key)
				-- check all players hero count
				for i=0, PlayerCount do
									
					if PlayerResource:IsValidPlayer(i) then
						local player = PlayerResource:GetPlayer(i)
						
						-- if player cannot train more heroes and tavern wasn't previously disabled, disable it now			
						if not CanPlayerTrainMoreHeroes( i ) and not player.hero_tavern_removed then
							-- delete tavern
							player.hero_tavern_removed = true
							CustomGameEventManager:Send_ServerToPlayer(player, "Shops_Remove_Content", {Index = UnitID, Shop = UnitShop, PlayerID = i}) 
							print("remove neutral heroes panels from player="..tostring(i))
						end
						
						UpdateHeroTavernForPlayer( i )
						local tier = GetPlayerCityLevel(player)
						local PlayerHasAltar = HasAltar(i)
						SetNetTableValue("dotacraft_shops_table", tostring(HeroTavernEntityID), {Shop = UnitShop, PlayerID = PlayerID, Tier=tier, Altar=PlayerHasAltar}) 
					
					end
					
				end
			
				return 0.1
			end)
		
		end
		
		-- save item into table using it's sort index, this is send once at the beginning to initialise the shop
		sorted_table[tonumber(order)] = UnitShop.Items[key]
	end

	local team = unit:GetTeam()
	if not isTavern then
		print("[UNIT SHOP] Create "..shop_name.." "..UnitID.." Tier "..tier)
		--DeepPrintTable(sorted_table)
		CustomGameEventManager:Send_ServerToTeam(team, "Shops_Create", {Index = UnitID, Shop = sorted_table, Tier=tier, Race=shop_name }) 
	else
		HeroTavernEntityID = UnitID
		CustomGameEventManager:Send_ServerToAllClients("Shops_Create", {Index = UnitID, Shop = sorted_table, Tier=tier, Tavern = true}) 
		print("[UNIT SHOP] Create Tavern "..HeroTavernEntityID)		
	end
	
end


function unit_shops:Buy(data)
	local item = data.ItemName
	local PlayerID = data.PlayerID -- The player that clicked on an item to purchase. This can be an allied player
	local player = PlayerResource:GetPlayer(PlayerID)
	local shopID = data.Shop
	local Shop = EntIndexToHScript(data.Shop)

	print("Player "..PlayerID.." trying to buy "..item.." from "..data.Shop.." "..shopID)
	
	-- Check whether hero item or no
	local isHeroItem = tobool(data.Hero)
	local isTavern = tobool(data.Tavern)
	
	if isTavern and not CanTrainHeroes(player) then
		print("PlayerID = "..tostring(PlayerID).." tried to create a hero at the tavern(MAX HERO LIMIT REACHED)")
		return
	end
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

	local bPlayerCanPurchase = bHasEnoughGold and bHasEnoughLumber and bEnoughSlots and bEnoughStock
		
	--DeepPrintTable(GameRules.Shops["human_shop"])
	if bPlayerCanPurchase then

		EmitSoundOnClient("General.Buy", player)

		if not isHeroItem or isTavern then
			
			-- create & add item
			if not isTavern then

				-- lower stock count by 1
				Purchased(item, Shop)

				local Bought_Item = CreateItem(item, buyerPlayerOwner, buyerPlayerOwner) 
				buyer:AddItem(Bought_Item)

			-- if it is tavern create hero
			else 
				
				if PlayerHasEnoughFood(player, 5) then

					-- lower stock count by 1
					Purchased(item, Shop)

					print("[UNIT SHOPS] Tavern creating hero for "..PlayerID)
										
					-- create neutral hero here
					TavernCreateHeroForPlayer(PlayerID, shopID, item)

				else
					print("[UNIT SHOPS] Player "..PlayerID.." doesn't have enough food to purchase a hero from Tavern")
					SendErrorMessage(buyerPlayerID, "#error_not_enough_food_"..(GetPlayerRace(player)))
					return
				end			
			end
		else 
			-- revive hero here (dead heroes)
			-- Should look for enough food!
			print("[UNIT SHOPS] Tavern creating hero for "..PlayerID)

			TavernReviveHeroForPlayer(PlayerID, shopID, item)
		end

		-- deduct gold & lumber
		PlayerResource:SpendGold(buyerPlayerID, Gold_Cost, 0)
		ModifyLumber(buyerPlayerOwner, Lumber_Cost)
		
		local UnitShop =  unit_shops.Units[data.Shop]
		
		-- delete hero / neutral hero panel if IsHero or IsTavern
		if isHeroItem or isTavern then -- update shop
			CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(data.PlayerID), "Shops_Delete_Single_Panel", {Index = data.Shop, Hero = data.ItemName }) 
		else -- update information of stock since it's an item
			SetNetTableValue("dotacraft_shops_table", tostring(data.Shop), { Shop = UnitShop, Tier=tier })
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

function unit_shops:AddHeroToTavern(hero)
	local HeroLevel = hero:GetLevel()

	local GoldCost = BASE_HERO_GOLDCOST + (BASE_HERO_ADDITIONAL_GOLDCOST_PER_LEVEL * HeroLevel)
	local LumberCost = BASE_HERO_LUMBERCOST + (BASE_HERO_ADDITIONAL_LUMBERCOST_PER_LEVEL * HeroLevel)
	
	for k,v in pairs(unit_shops.Units) do
		--print(k) (ShopID, HeroName, NewGoldCost, NewLumberCost, RequiredTier)
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(hero:GetPlayerOwnerID()), "Shops_Create_Single_Panel", {Index = k, PlayerID=hero:GetPlayerOwnerID(), HeroInfo={GoldCost=GoldCost, LumberCost=LumberCost, RequiredTier = 1} , Hero=hero:GetUnitName() }) 
	end
end	

function unit_shops:Stock_Management(UnitShop, key)
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
end

function HasAltar(PlayerID)
    local player = PlayerResource:GetPlayer(PlayerID)
    return (player.altar_structures and #player.altar_structures > 0)
end

-- all the player-specific updates for players
-- make sure to feed it correct player requirement
function UpdateHeroTavernForPlayer(PlayerID)

	local UnitShop = unit_shops.Units[HeroTavernEntityID]
	local player = PlayerResource:GetPlayer(PlayerID)
	local tier = GetPlayerCityLevel(player)
	
	local inRequiredTier = #player.heroes + 1
	
	if inRequiredTier == 4 then
		return
	end
	
	if (inRequiredTier - 1) > 0 then
		for HeroName,Kaapa in pairs(UnitShop.Items) do
			UnitShop.Items[HeroName].GoldCost = NEUTRAL_HERO_GOLDCOST
			UnitShop.Items[HeroName].LumberCost = NEUTRAL_HERO_LUMBERCOST
		end
	end

	for HeroName,Kaapa in pairs(UnitShop.Items) do
		UnitShop.Items[HeroName].RequiredTier = inRequiredTier
	end
end

function TavernCreateHeroForPlayer(playerID, shopID, HeroName)
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()
	local unit_name = HeroName
	local tavern = EntIndexToHScript(shopID)

	-- handle_UnitOwner needs to be nil, else it will crash the game.
	local new_hero = CreateUnitByName(unit_name, tavern:GetAbsOrigin(), true, hero, nil, hero:GetTeamNumber())
	new_hero:SetPlayerID(playerID)
	new_hero:SetControllableByPlayer(playerID, true)
	new_hero:SetOwner(player)
	FindClearSpaceForUnit(new_hero, tavern:GetAbsOrigin(), true)
	
	-- Add a teleport scroll
	local tpScroll = CreateItem("item_scroll_of_town_portal", new_hero, new_hero)
	new_hero:AddItem(tpScroll)
	tpScroll:SetPurchaseTime(0) --Dont refund fully

	-- Add the hero to the table of heroes acquired by the player
	table.insert(player.heroes, new_hero)

	-- Add food cost
	ModifyFoodUsed(player, 5)

	-- Acquired ability
	local train_ability_name = "neutral_train_"..HeroName
	train_ability_name = string.gsub(train_ability_name, "npc_dota_hero_" , "")
	new_hero.RespawnAbility = train_ability_name --Reference to swap to a revive ability when the hero dies

	-- Add the acquired ability to each altar
	for _,altar in pairs(player.altar_structures) do
		local acquired_ability_name = train_ability_name.."_acquired"
		TeachAbility(altar, acquired_ability_name)
		SetAbilityLayout(altar, 5)	
	end

	-- Increase the altar tier
	dotacraft:IncreaseAltarTier( playerID )
	
	Setup_Hero_Panel(new_hero)
end

function TavernReviveHeroForPlayer(playerID, shopID, HeroName)
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()
	local hero_name = HeroName
	local tavern = EntIndexToHScript(shopID)
	local health_factor = 0.5
	local ability_name --Ability on the altars, needs to be removed after the hero is revived
	local level

	for k,hero in pairs(player.heroes) do
		if hero:GetUnitName() == HeroName then
			hero:RespawnUnit()
			FindClearSpaceForUnit(hero, tavern:GetAbsOrigin(), true)
			hero:SetMana(0)
			hero:SetHealth(hero:GetMaxHealth() * health_factor)
			ability_name = hero.RespawnAbility
			level = hero:GetLevel()
			print("Revived "..hero_name.." with 50% Health at Level "..hero:GetLevel())
		end
	end

	ability_name =  ability_name.."_revive"..level
	
	-- Swap the _revive ability on the altars for a _acquired ability
	for _,altar in pairs(player.altar_structures) do
		local new_ability_name = string.gsub(ability_name, "_revive" , "")
		new_ability_name = GetResearchAbilityName(new_ability_name) --Take away numbers or research
		new_ability_name = new_ability_name.."_acquired"

		print("new_ability_name is "..new_ability_name..", it will replace: "..ability_name)

		altar:AddAbility(new_ability_name)
		altar:SwapAbilities(ability_name, new_ability_name, false, true)
		altar:RemoveAbility(ability_name)
		
		local new_ability = altar:FindAbilityByName(new_ability_name)
		new_ability:SetLevel(new_ability:GetMaxLevel())

		PrintAbilities(altar)
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

		-- For tavern, check any unit
		if shop:GetUnitName() == "tavern" then
			for k,unit in pairs(units) do
				return unit
			end
		end
	end
	return nil
end