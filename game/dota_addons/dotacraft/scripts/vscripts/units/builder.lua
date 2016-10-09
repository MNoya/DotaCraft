------------------------------------------
--             Build Scripts
------------------------------------------

-- A build ability is used (not yet confirmed)
function Build( event )
    local caster = event.caster
    local ability = event.ability
    local ability_name = ability:GetAbilityName()
    local building_name = ability:GetKeyValue("UnitName")
    local gold_cost = ability:GetSpecialValueFor("gold_cost")
    local lumber_cost = ability:GetSpecialValueFor("lumber_cost")

    local construction_size = BuildingHelper:GetConstructionSize(building_name)
    local construction_radius = construction_size * 64 - 32

    local hero = caster:IsRealHero() and caster or caster:GetOwner()
    local playerID = hero:GetPlayerID()
    local player = PlayerResource:GetPlayer(playerID)    
    local teamNumber = hero:GetTeamNumber()

    -- If the ability has an AbilityGoldCost, it's impossible to not have enough gold the first time it's cast
    -- Always refund the gold here, as the building hasn't been placed yet
    Players:ModifyGold(playerID, gold_cost)

    if not Players:HasEnoughLumber( playerID, lumber_cost ) then
        return
    end

    -- Makes a building dummy and starts panorama ghosting
    BuildingHelper:AddBuilding(event)

    -- Additional checks to confirm a valid building position can be performed here
    event:OnPreConstruction(function(vPos)

        -- Enemy unit check
        local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
        local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
        local enemies = FindUnitsInRadius(teamNumber, vPos, nil, construction_size, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_ANY_ORDER, false)

        if #enemies > 0 then
            SendErrorMessage(playerID, "#error_invalid_build_position")
            return false
        end

       -- Blight check
       if string.match(building_name, "undead") and building_name ~= "undead_necropolis" then
           local bHasBlight = BuildingHelper:PositionHasBlight(vPos)
           BuildingHelper:print("Blight check for "..building_name..":", bHasBlight)
           if not bHasBlight then
               SendErrorMessage(playerID, "#error_must_build_on_blight")
               return false
           end
       end

        -- Proximity to gold mine check for Human/Orc: Main Buildings can be as close as 768 towards the center of the Gold Mine.
        if HasGoldMineDistanceRestriction(building_name) then
            local nearby_mine = Entities:FindAllByNameWithin("*gold_mine", vPos, 768)
            if #nearby_mine > 0 then
                SendErrorMessage(caster:GetPlayerOwnerID(), "#error_too_close_to_goldmine")
                return false
            end
       end

        -- If not enough resources to queue, stop
        if not Players:HasEnoughGold( playerID, gold_cost ) then
            return false
        end

        if not Players:HasEnoughLumber( playerID, lumber_cost ) then
            return false
        end

        -- Don't let a charged item be queued without charges
        if ability:GetKeyValue("ItemInitialCharges") then
            local charges = ability:GetCurrentCharges()
            if charges and charges == 0 then
                SendErrorMessage(playerID, "#error_cant_queue")
                return false
            end
        end

        return true
    end)

    -- Position for a building was confirmed and valid
    event:OnBuildingPosChosen(function(vPos)
        
        -- Spend resources
        Players:ModifyGold(playerID, -gold_cost)
        Players:ModifyLumber(playerID, -lumber_cost)

        -- Play a sound
        Sounds:EmitSoundOnClient(playerID, "Building.Placement")

        -- Cancel gather
        local gather_ability = caster:GetGatherAbility()
        if gather_ability then caster:CancelGather() end

        -- Move allied units away from the building place
        local units = FindUnitsInRadius(teamNumber, vPos, nil, construction_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
        
        for _,unit in pairs(units) do
            if unit ~= caster and not IsCustomBuilding(unit) then
                -- This is still sketchy but works.
                if (unit:IsIdle() and unit.state ~= "repairing") then
                    BuildingHelper:print("Moving unit "..unit:GetUnitName().." outside of the building area")
                    local origin = unit:GetAbsOrigin()
                    local front_position = origin + (origin - vPos):Normalized() * (construction_radius - (vPos-origin):Length2D()+20)
                    ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = front_position, Queue = false})
                    unit:AddNewModifier(nil, nil, "modifier_phased", {duration=1})
                end
            end
        end
    end)

    -- The construction failed and was never confirmed due to the gridnav being blocked in the attempted area
    event:OnConstructionFailed(function()
        local playerTable = BuildingHelper:GetPlayerTable(playerID)
        local name = playerTable.activeBuilding

        BuildingHelper:print("Failed placement of " .. name)
        SendErrorMessage(caster:GetPlayerOwnerID(), "#error_invalid_build_position")
    end)

    -- Cancelled due to ClearQueue
    event:OnConstructionCancelled(function(work)
        local name = work.name
        local building = work.building -- Used on repair

        if building then
            -- Toggle off
            local repair_ability = BuildingHelper:GetRepairAbility(caster)
            if repair_ability and repair_ability:GetToggleState() then repair_ability:ToggleAbility() end 

        else
            BuildingHelper:print("Cancelled construction of " .. name)

            -- Refund resources for this cancelled work
            if work.refund then
                if ability:GetKeyValue("ItemInitialCharges") then
                    ability:SetCurrentCharges(ability:GetCurrentCharges()+1)
                end
                Players:ModifyGold(playerID, gold_cost)
                Players:ModifyLumber(playerID, lumber_cost)
            end
        end
    end)

    -- A building unit was created
    event:OnConstructionStarted(function(unit)
        BuildingHelper:print("Started construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
        -- Play construction sound

        -- Adjust health for human research
        local masonry_rank = Players:GetCurrentResearchRank(playerID, "human_research_masonry")
        local maxHealth = unit:GetMaxHealth() * (1 + 0.2 * masonry_rank)
        unit:SetMaxHealth(maxHealth)
        unit:SetBaseMaxHealth(maxHealth)

        if unit:RenderTeamColor() then
            local color = dotacraft:ColorForTeam(teamNumber)
            unit:SetRenderColor(color[1], color[2], color[3])
        end

        -- Move allied units away from the building place
        local vPos = unit:GetAbsOrigin()
        local units = FindUnitsInRadius(teamNumber, vPos, nil, construction_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
        for _,unit in pairs(units) do
            if unit ~= caster and not IsCustomBuilding(unit) then
                unit:FindClearSpace()
            end
        end

        -- Units can't attack while building
        unit.original_attack = unit:GetAttackCapability()
        unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)

        -- Give item to cancel
        local item = CreateItem("item_building_cancel", nil, nil)
        unit:AddItem(item)

        -- FindClearSpace for the builder
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
        caster:AddNewModifier(caster, nil, "modifier_phased", {duration=0.03})

        -- Remove invulnerability on npc_dota_building baseclass
        unit:RemoveModifierByName("modifier_invulnerable")

        -- Particle effect
        ApplyModifier(unit, "modifier_construction")

        -- Check the abilities of this building, disabling those that don't meet the requirements
        CheckAbilityRequirements( unit, playerID )
        unit:ApplyRankUpgrades()

        -- Add roots to ancient
        local ancient_roots = unit:FindAbilityByName("nightelf_uproot")
        if ancient_roots then
            ancient_roots:ApplyDataDrivenModifier(unit, unit, "modifier_rooted_ancient", {})
        end

        -- Apply altar linking
        if string.find( unit:GetUnitName(), "altar") then
            TeachAbility(unit, "ability_altar")
        end
    end)

    -- A building finished construction
    event:OnConstructionCompleted(function(unit)
        BuildingHelper:print("Completed construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
        
        -- Play construction complete sound

        -- Give the unit their original attack capability
        unit:SetAttackCapability(unit.original_attack)

        -- Let the building cast abilities
        unit:RemoveModifierByName("modifier_construction")

        -- Remove item_building_cancel and reorder
        RemoveItemByName(unit, "item_building_cancel")
        ReorderItems(unit)

        local builders = {}
        if unit.builder then
            table.insert(builders, unit.builder)
        elseif unit.builders_repairing then
            builders = unit.builders_repairing
        end

        -- When building one of the lumber-only buildings, send the builder(s) to auto-gather lumber after the building is done
        Timers:CreateTimer(0.1, function() 
            if #builders == 0 then return end
            if building_name == "human_lumber_mill" or building_name == "orc_war_mill" then
                BuildingHelper:print("Sending "..#builders.." builders to gather lumber after finishing "..building_name)
            
                for k,builder in pairs(builders) do
                    if not builder.work then -- If it doesnt have anything else to do
                        builder:GatherFromNearestTree(builder:GetAbsOrigin(), 2000)
                    end
                end
            elseif Gatherer:IsUnitValidDepositForResource(unit, "gold") and (unit:GetRace() == "human" or unit:GetRace() == "orc") then
                for k,builder in pairs(builders) do
                    if not builder.work then -- If it doesnt have anything else to do
                        builder:GatherFromNearestGoldMine()
                    end
                end
            end
        end)

        -- Add the building handle to the list of structures
        Players:AddStructure(playerID, unit)

        -- If it's a city center, check for city_center_level updates
        local bCityCenter = IsCityCenter(unit)
        if bCityCenter then
            Players:CheckCurrentCityCenters(playerID)
        end

        -- Add blight if its an undead building, dispel otherwise
        local blightSize = bCityCenter and "large" or "small"
        if IsUndead(unit) then
            Blight:Create(unit, blightSize)
        end

        -- Enable night regeneration
        if not GameRules:IsDaytime() and IsNightElfAncient(unit) then
            unit:SetBaseHealthRegen(0.5)
        end

        -- Add ability_shop on team shop buildings
        if unit:GetKeyValue("ShopType") == "team" then
            TeachAbility(unit, "ability_shop")
        end

        -- Add to the Food Limit if possible
        local food_produced = GetFoodProduced(unit)
        if food_produced ~= 0 then
            Players:ModifyFoodLimit(playerID, food_produced)
        end

        -- Update the abilities of the builders and buildings
        local playerUnits = Players:GetUnits(playerID)
        for k,units in pairs(playerUnits) do
            CheckAbilityRequirements( units, playerID )
        end

        local playerStructures = Players:GetStructures(playerID)
        for k,structure in pairs(playerStructures) do
            CheckAbilityRequirements( structure, playerID )
        end

    end)

    -- These callbacks will only fire when the state between below half health/above half health changes.
    -- i.e. it won't fire multiple times unnecessarily.
    event:OnBelowHalfHealth(function(unit)
        if not IsUnsummoning(unit) then
            BuildingHelper:print(unit:GetUnitName() .. " is below half health.")
            ApplyModifier(unit, "modifier_onfire")
        end
    end)

    event:OnAboveHalfHealth(function(unit)
        BuildingHelper:print(unit:GetUnitName().. " is above half health.")

        unit:RemoveModifierByName("modifier_onfire")
    end)
end

-- Called when the Cancel ability-item is used, refunds the cost by a factor
function CancelBuilding( keys )
    local building = keys.caster
    local playerID = building:GetPlayerOwnerID()

    BuildingHelper:print("CancelBuilding "..building:GetUnitName().." "..building:GetEntityIndex())

    -- Refund
    local refund_factor = 0.75
    local gold_cost = math.floor(GetGoldCost(building) * refund_factor)
    local lumber_cost = math.floor(GetLumberCost(building) * refund_factor)

    -- Eject builder
    local builder = building.builder_inside
    if builder then   
        builder:SetAbsOrigin(building:GetAbsOrigin())
    end

    -- Refund items (In the item-queue system, units can be queued before the building is finished)
    local time = 0
    for i=0,5 do
        local item = building:GetItemInSlot(i)
        if item then
            if item:GetAbilityName() == "item_building_cancel" then
                item:RemoveSelf()
            else
                time = time + i*1/30
                Timers:CreateTimer(i*1/30, function() 
                    building:CastAbilityImmediately(item, playerID)
                end)
            end
        end
    end

    Players:ModifyGold(playerID, gold_cost)
    Players:ModifyLumber(playerID, lumber_cost)

    building.state = "canceled"
    Timers:CreateTimer(time+1/30, function() 
        building:ForceKill(true)
    end)
end