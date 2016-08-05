-- ManaGain and HPGain values are defined in the npc_units_custom file
function ApplyTraining( event )
    local caster = event.caster
    local ability = event.ability
    local training_level = ability:GetLevel()
    local levels = event.LevelUp - caster:GetLevel()

    caster:LevelUp(levels)
end

-- Gives an inventory to this unit
function Backpack( event )
    local caster = event.caster
    local action = event.Action

    if action == "Enable" then
        caster:SetHasInventory(true)
        -- Remove 2 backpack slot items
        for itemSlot = 0, 1 do
            local item = caster:GetItemInSlot( itemSlot )
            if item then 
                caster:RemoveItem(item)
            end
        end
    else
        caster:SetHasInventory(false)
        -- Make 6 undroppable backpack items
        for itemSlot = 0, 5 do
            local newItem = CreateItem("item_backpack", nil, nil)
            caster:AddItem(newItem)
        end
    end
end

-- Drop all the items on the killed unit
function BackpackDrop( event )
    local caster = event.caster
    local position = caster:GetAbsOrigin()

    for itemSlot = 0, 5 do
        local item = caster:GetItemInSlot( itemSlot )
        if item and item:IsDroppable() then
            local itemName = item:GetAbilityName()
            local newItem = CreateItem(itemName, nil, nil)
            local drop = CreateItemOnPositionSync( position , newItem)
            if drop then
                drop:SetContainedItem( newItem )
                newItem:LaunchLoot( false, 100, 0.35, position + RandomVector( RandomFloat( 10, 100 ) ) )
            end
            caster:RemoveItem(item)
        end
    end
end