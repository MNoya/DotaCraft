if unit_shops == nil then
	unit_shops = class({})
	-- create the Units table
	unit_shops.Units = {}
	-- register listeners
	CustomGameEventManager:RegisterListener( "Shops_Buy", Dynamic_Wrap(unit_shops, "Buy"))
	CustomGameEventManager:RegisterListener( "Shops_Sell", Dynamic_Wrap(unit_shops, "Sell"))
end

-- called to create the shop
function Setup_Shop( keys )
	local Shop_Name = keys.caster:GetUnitLabel()
	unit_shops:CreateShop(keys.caster, Shop_Name)
end

--[[
	shops[UnitID].CurrentStock is the current stock in store, this holds an array of ints that correlate to the item based on index
	
	shops[UnitID].MaxStocks is the max amount of stock the store can have for that item, this also holds an array of int that correlate to the item based on index

	shops[UnitID].RefreshRate is the time at which an item is restocked, this holds an array of int which represent the amount of seconds it takes to add stock++;

	shops[UnitID].CurrentRefreshTime is the time that the item is currently at, this is used as a counter to reference against RefreshRate, once they match we increase stock
--]]

function unit_shops:CreateShop(unit, shop_name)
	local UnitID = unit:GetEntityIndex()
	
	if unit_shops.Units[UnitID] == nil then
	-- initialise Shop item table
		unit_shops.Units[UnitID] = {}
		unit_shops.Units[UnitID].Items = {}
	end
	
	local UnitShop = unit_shops.Units[UnitID]
	local player = unit:GetPlayerOwner()
	local tier = GetPlayerCityLevel(player)

	local shopEnt = Entities:FindByName(nil, "custom_shop") -- entity name in hammer
	if shopEnt then
		local newshop = SpawnEntityFromTableSynchronous('trigger_shop', {origin = unit:GetAbsOrigin(), shoptype = 1, model="maps/hills_of_glory/entities/custom_shop_0.vmdl"}) -- shoptype is 0 for a "home" shop, 1 for a side shop and 2 for a secret shop
		print("CreateShop out of "..shopEnt:GetModelName())
	else
		print("ERROR: CreateShop was unable to find a custom_shop trigger area. Add a custom_shop trigger to this map")
	end
	
	-- for each item create an corresponding timer to restock that item
	--DeepPrintTable(GameRules.Shops["human_shop"])
	DeepPrintTable(GameRules.Shops)
	for order,item in pairs(GameRules.Shops[shop_name]) do
		print("[UNIT SHOP] Creating timer for new unit shop: "..shop_name)
		local key = item
		print(key)

		-- set all variables
		UnitShop.Items[key] = {}
		UnitShop.Items[key].CurrentStock = GameRules.ItemKV[key]["StockInitial"]
		UnitShop.Items[key].MaxStock = GameRules.ItemKV[key]["StockMax"]
		UnitShop.Items[key].RestockRate = GameRules.ItemKV[key]["StockTime"]
		UnitShop.Items[key].CurrentRefreshTime = 1
		UnitShop.Items[key].GoldCost = GameRules.ItemKV[key]["ItemCost"]
		UnitShop.Items[key].RequiredTier = GameRules.ItemKV[key]["RequiresTier"]
		UnitShop.Items[key].Order = order
		DeepPrintTable(UnitShop.Items[key])
		
		-- set to 0 if nil, "0" hides the value in panaroma
		if GameRules.ItemKV[key]["LumberCost"] ~= nil then
			UnitShop.Items[key].LumberCost = GameRules.ItemKV[key]["LumberCost"]
		else
			UnitShop.Items[key].LumberCost = 0
		end
		
		Timers:CreateTimer(1, function()
			tier = GetPlayerCityLevel(player)

			if not IsValidEntity(unit) or not unit:IsAlive() then
				-- send command to kill shop panel
				
				print("[UNIT SHOP] Shop identified not valid, terminating timer")
				return
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
				SetNetTableValue("dotacraft_shops_table", tostring(UnitID), { Index = UnitID, Shop = UnitShop, Tier=tier, Race=shop_name })
			return 1
		end)
			
	end

	local team = unit:GetTeam()
	CustomGameEventManager:Send_ServerToTeam(team, "Shops_Create", {Index = UnitID, Shop = UnitShop, Tier=tier, Race=shop_name }) 

end

function unit_shops:Buy(data)
	local item = data.ItemName
	local PlayerID = data.PlayerID
	local Shop = EntIndexToHScript(data.Shop)
	
	-- check current tier
	local player = Shop:GetPlayerOwner()
	local tier = GetPlayerCityLevel(player)
				
	-- Information about the buying unit
	-- the buying unit
	local buyer
	if Shop.current_unit == nil then
		SendErrorMessage(data.PlayerID, "#shops_no_buyers_found")
		return
	else
		buyer = Shop.current_unit
	end
	
	local buyerPlayerID = buyer:GetPlayerOwnerID()
	local buyerPlayerOwner = buyer:GetPlayerOwner()
	-- hero of the buying unit
	local buyerHero = buyerPlayerOwner:GetAssignedHero()
	
	-- Issue with script_reload
	if not unit_shops then return end

	-- cost of the item
	local Gold_Cost = unit_shops.Units[data.Shop].Items[item].GoldCost
	local Lumber_Cost = unit_shops.Units[data.Shop].Items[item].LumberCost

	-- Conditions
	local bHasEnoughGold = PlayerHasEnoughGold(buyerPlayerOwner, GoldCost)
	local bHasEnoughLumber = PlayerHasEnoughLumber(buyerPlayerOwner, Lumber_Cost )
	local bEnoughStock = EnoughStock(item, Shop)
	local bEnoughSlots = CountInventoryItems(buyer) < 6
	local bPlayerCanPurchase = bHasEnoughGold and bHasEnoughLumber and bEnoughStock and bEnoughSlots
		
	--DeepPrintTable(GameRules.Shops["human_shop"])
	if bPlayerCanPurchase then

		EmitSoundOnClient("General.Buy", player)

		-- lower stock count by 1
		Purchased(item, Shop)

		-- create & add item	
		local Bought_Item = CreateItem(item, buyerPlayerOwner, buyerPlayerOwner) 
		buyer:AddItem(Bought_Item)

		-- deduct gold & lumber
		PlayerResource:SpendGold(buyerPlayerID, Gold_Cost, 0)
		ModifyLumber(buyerPlayerOwner, Lumber_Cost)
		
		local UnitShop =  unit_shops.Units[data.Shop]
		
		SetNetTableValue("dotacraft_shops_table", tostring(data.Shop), { Shop = UnitShop, Tier=tier })
		
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

function unit_shops:Sell(data)

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

function CheckHeroInRadius( event )
	local shop = event.caster
	local ability = event.ability
	local current_unit = shop.current_unit

	if IsValidAlive(current_unit) then
		-- Break out of range
		if shop:GetRangeToUnit(current_unit) > 900 then
			if shop.active_particle then
		        ParticleManager:DestroyParticle(shop.active_particle, true)
		    end
		    shop.current_unit = nil
		    Timers:RemoveTimer(shop.ghost_items)
		    ClearItems(shop)
		    return
		end

		-- If the current_unit is a creature and was autoassigned (not through rightclick), find heroes
		if current_unit:IsCreature() and not shop.targeted then
			local foundHero = FindShopAbleUnit(shop, DOTA_UNIT_TARGET_HERO)
			if foundHero then
				event.shop = shop:GetEntityIndex()
				event.unit = foundHero:GetEntityIndex()
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
			dotacraft:ShopActiveOrder(event)
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