-- This directly applies the current lvl 1/2/3, from the player upgrades table
function ApplyMultiRankUpgrade( event )
	local caster = event.caster
	local target = event.target
	local playerID = caster:GetPlayerOwnerID()
	local upgrades = Players:GetUpgradeTable(playerID)
	local research_name = event.ResearchName
	local ability_name = string.gsub(research_name, "research_" , "")
	local cosmetic_type = event.WearableType
	local level = 0

	if upgrades[research_name.."3"] then
		level = 3		
	elseif upgrades[research_name.."2"] then
		level = 2		
	elseif upgrades[research_name.."1"] then
		level = 1
	end

	if level ~= 0 then
		target:AddAbility(ability_name..level)
		local ability = target:FindAbilityByName(ability_name..level)
		ability:SetLevel(level)

		if cosmetic_type then
			UpgradeWearables(target, level, cosmetic_type)
            if target.rider then
                UpgradeWearables(target.rider, level, cosmetic_type)
            end
		end
	end
end

function ApplySingleRankUpgrade(event)
    local caster = event.caster
    local target = event.target
    local playerID = caster:GetPlayerOwnerID()
    local upgrades = Players:GetUpgradeTable(playerID)
    local research_name = event.ResearchName
    local cosmetic_type = event.WearableType

    if upgrades[research_name] then
        if cosmetic_type then
            UpgradeWearables(target, 1, cosmetic_type)
        end
    end
end

-- ManaGain and HPGain values are defined in the npc_units_custom file
function ApplyTraining( event )
	local caster = event.caster
	local ability = event.ability
	local hero = caster:GetOwner()
	local player = hero:GetPlayerOwner()
	local training_level = ability:GetLevel()
	local levels = event.LevelUp - caster:GetLevel()

	local bonus_health = event.ability:GetSpecialValueFor("bonus_health")
	local bonus_mana = event.ability:GetSpecialValueFor("bonus_mana")

	caster:SetHealth(caster:GetHealth() + bonus_health)
	caster:CreatureLevelUp(levels)
	caster:SetMana(caster:GetMana() + bonus_mana)

	UpgradeWearables(caster, training_level, "training")
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