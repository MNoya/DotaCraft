-- Removes the first item by name if found on the unit. Returns true if removed
function RemoveItemByName( unit, item_name )
    for i=0,15 do
        local item = unit:GetItemInSlot(i)
        if item and item:GetAbilityName() == item_name then
            item:RemoveSelf()
            return true
        end
    end
    return false
end

-- Takes all items and puts them 1 slot back
function ReorderItems( caster )
    local slots = {}
    for itemSlot = 0, 5, 1 do

        -- Handle the case in which the caster is removed
        local item
        if IsValidEntity(caster) then
            item = caster:GetItemInSlot( itemSlot )
        end

        if item ~= nil then
            table.insert(slots, itemSlot)
        end
    end

    for k,itemSlot in pairs(slots) do
        caster:SwapItems(itemSlot,k-1)
    end
end

-- Sells an item from any unit, with gold and lumber cost refund
function SellCustomItem( unit, item )
    local player = unit:GetPlayerOwner()
    local playerID = player:GetPlayerID()
    local item_name = item:GetAbilityName()
    local GoldCost = GameRules.ItemKV[item_name]["ItemCost"]
    local LumberCost = GameRules.ItemKV[item_name]["LumberCost"]

    -- 10 second sellback
    local time = item:GetPurchaseTime()
    local refund_factor = GameRules:GetGameTime() <= time+10 and 1 or 0.5

    if GoldCost then
        Players:ModifyGold(playerID, GoldCost*refund_factor)
        PopupGoldGain( unit, GoldCost*refund_factor)
    end

    if LumberCost then
        Players:ModifyLumber(playerID, LumberCost*refund_factor)
        PopupLumber( unit, LumberCost*refund_factor)
    end

    EmitSoundOnClient("General.Sell", player)

    item:RemoveSelf()
end

function GetItemSlot( unit, target_item )
    for itemSlot = 0,5 do
        local item = unit:GetItemInSlot(itemSlot)
        if item and item == target_item then
            return itemSlot
        end
    end
    return -1
end

function CountInventoryItems(unit)
    local count = 0
    for i=0, 5 do
        if unit:GetItemInSlot(i) then
            count = count + 1
        end
    end
    
    return count
end

function StartItemGhosting(shop, unit)
    if shop.ghost_items then
        Timers:RemoveTimer(shop.ghost_items)
    end

    shop.ghost_items = Timers:CreateTimer(function()
        if IsValidAlive(shop) and IsValidAlive(unit) then
            ClearItems(shop)
            for j=0,5 do
                local unit_item = unit:GetItemInSlot(j)
                if unit_item then
                    local item_name = unit_item:GetAbilityName()
                    local new_item = CreateItem(item_name, nil, nil)
                    shop:AddItem(new_item)
                    shop:SwapItems(j, GetItemSlot(shop, new_item))
                end
            end
            return 0.1
        else
            return nil
        end
    end)
end

function ClearItems(unit)
     for i=0,5 do
        local item = unit:GetItemInSlot(i)
        if item then
            item:RemoveSelf()
        end
    end
end