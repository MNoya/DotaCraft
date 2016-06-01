--------------------------------
--       Repair Scripts       --
--------------------------------

function Repair(event)
    local caster = event.caster
    local target = event.target

    if IsValidRepairTarget(target, caster) then
        print("Repair.lua - Target: "..target:GetUnitName())
        caster:Interrupt()
        BuildingHelper:AddRepairToQueue(caster, target, false)
    end
end

function IsValidRepairTarget(target, builder)
    return target:GetClassname() == "npc_dota_creature" and (IsCustomBuilding(target) or IsMechanical(target)) and target:GetHealthPercent() < 100 and not target.unsummoning and not target.frozen
end

-- Right before starting to move towards the target building. 
function BuildingHelper:OnPreRepair(builder, building)
    self:print("OnPreRepair "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> "..building:GetUnitName().." "..building:GetEntityIndex())

    -- Return false to stop the repair process
    local repair_ability = self:GetRepairAbility(builder)
    if repair_ability and repair_ability:GetToggleState() == false then
        repair_ability:ToggleAbility() -- Fake toggle the ability
    end
end

-- As soon as the builder reaches the building
function BuildingHelper:OnRepairStarted(builder, building)
    self:print("OnRepairStarted "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> "..building:GetUnitName().." "..building:GetEntityIndex())
end

function BuildingHelper:OnRepairTick(building, hpGain, costFactor)
    -- Can pay the resource cost?
    -- Important: can repair allied resources?

    local playerID = building:GetPlayerOwnerID()
    local goldCost = building:GetKeyValue("GoldCost")
    local lumberCost = building:GetKeyValue("LumberCost")
    local buildTime = building:GetKeyValue("BuildTime")
    building.GoldAdjustment = building.GoldAdjustment or 0
    building.gold_used = 0
    building.lumber_used = 0

    -- Keep adding the floating point values every tick
    local pct_healed = hpGain / building:GetMaxHealth()
    local gold_tick = pct_healed * goldCost * costFactor
    local gold_float = gold_tick - math.floor(gold_tick)
    gold_tick = math.floor(gold_tick)

    -- Lumber is custom so we can get away with storing the floating point value
    local lumber_tick = pct_healed * lumberCost * costFactor

    if Players:HasEnoughGold(playerID, gold_tick+gold_float) and Players:HasEnoughLumber(playerID, lumber_tick) then
        building.GoldAdjustment = building.GoldAdjustment + gold_float
        if building.GoldAdjustment > 1 then
            Players:ModifyGold(playerID, -gold_tick - 1)
            building.GoldAdjustment = building.GoldAdjustment - 1
            building.gold_used = building.gold_used + gold_tick + 1

        else
            Players:ModifyGold(playerID, -gold_tick)
            building.gold_used = building.gold_used + gold_tick
        end
        
        Players:ModifyLumber(playerID, -lumber_tick)
        building.lumber_used = building.lumber_used + lumber_tick


    else
        building.gold_used = nil
        building.lumber_used = 0
        return false -- cancels the repair on all builders
    end
end

-- After an ongoing move-to-building or repair process is cancelled
function BuildingHelper:OnRepairCancelled(builder, building)
    self:print("OnRepairCancelled "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> "..building:GetUnitName().." "..building:GetEntityIndex())
end

-- After a building is fully constructed via repair ("RequiresRepair" buildings), or is fully repaired
function BuildingHelper:OnRepairFinished(builder, building)
    self:print("OnRepairFinished "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> "..building:GetUnitName().." "..building:GetEntityIndex())
end

-------------------------------------------------------------------------------------------
-- Outdated code ahead

-- Health increase thinker on the building being repaired
function OldRepair( event )
    local caster = event.caster -- The builder
    local ability = event.ability
    local building = event.target -- The building to repair
    local playerID = caster:GetPlayerOwnerID()

    local building_name = building:GetUnitName()
    local building_info = GameRules.UnitKV[building_name]
    local gold_cost = building_info.GoldCost
    local lumber_cost = building_info.LumberCost
    local build_time = building_info.BuildTime

    local state = building.state -- "completed" or "building"
    local health_deficit = building:GetHealthDeficit()

    ToggleOn(ability)

    -- If its an unfinished building, keep track of how much does it require to mark as finished
    if not building.constructionCompleted and not building.health_deficit then
        building.missingHealthToComplete = health_deficit
    end

    -- Scale costs/time according to the stack count of builders reparing this
    if health_deficit > 0 then
        -- Initialize the tracking
        if not building.health_deficit then
            building.health_deficit = health_deficit
            building.gold_used = 0
            building.lumber_used = 0
            building.HPAdjustment = 0
            building.GoldAdjustment = 0
            building.time_started = GameRules:GetGameTime()
        end
        
        local stack_count = building:GetModifierStackCount( "modifier_repairing_building", ability )

        -- HP
        local health_per_second = building:GetMaxHealth() /  ( build_time * 1.5 ) * stack_count
        local health_float = health_per_second - math.floor(health_per_second) -- floating point component
        health_per_second = math.floor(health_per_second) -- round down

        -- Don't expend resources for the first peasant repairing the building if its a construction
        if not building.constructionCompleted then
            stack_count = stack_count - 1
        end

        -- Gold
        local gold_per_second = gold_cost / ( build_time * 1.5 ) * 0.35 * stack_count
        local gold_float = gold_per_second - math.floor(gold_per_second) -- floating point component
        gold_per_second = math.floor(gold_per_second) -- round down

        -- Lumber takes floats just fine
        local lumber_per_second = lumber_cost / ( build_time * 1.5 ) * 0.35 * stack_count

        --[[print("Building is repaired for "..health_per_second)
        if gold_per_second > 0 then
            print("Cost is "..gold_per_second.." gold and "..lumber_per_second.." lumber per second")
        else
            print("Cost is "..gold_float.." gold and "..lumber_per_second.." lumber per second")
        end]]
            
        local healthGain = 0
        if Players:HasEnoughGold( playerID, math.ceil(gold_per_second+gold_float) ) and Players:HasEnoughLumber( playerID, lumber_per_second ) then

            -- Health
            building.HPAdjustment = building.HPAdjustment + health_float
            if building.HPAdjustment > 1 then
                healthGain = health_per_second + 1
                building:SetHealth(building:GetHealth() + healthGain)
                building.HPAdjustment = building.HPAdjustment - 1
            else
                healthGain = health_per_second
                building:SetHealth(building:GetHealth() + health_per_second)
            end
            
            -- Consume Resources
            building.GoldAdjustment = building.GoldAdjustment + gold_float
            if building.GoldAdjustment > 1 then
                Players:ModifyGold(playerID, -gold_per_second - 1)
                building.GoldAdjustment = building.GoldAdjustment - 1
                building.gold_used = building.gold_used + gold_per_second + 1
            else
                Players:ModifyGold(playerID, -gold_per_second)
                building.gold_used = building.gold_used + gold_per_second
            end
            
            Players:ModifyLumber( playerID, -lumber_per_second )
            building.lumber_used = building.lumber_used + lumber_per_second
        else
            -- Remove the modifiers on the building and the builders
            building:RemoveModifierByName("modifier_repairing_building")
            print("Remove the modifiers on the building and the builders")
            for _,builder in pairs(building.units_repairing) do
                if builder and IsValidEntity(builder) then
                    builder:RemoveModifierByName("modifier_builder_repairing")
                end
            end
            print("Repair Ended, not enough resources!")
            building.health_deficit = nil
            building.missingHealthToComplete = nil

            -- Toggle off
            ToggleOff(ability)
        end

        -- Decrease the health left to finish construction and mark building as complete
        if building.missingHealthToComplete then
            building.missingHealthToComplete = building.missingHealthToComplete - healthGain
        end

    -- Building Fully Healed
    else
        -- Remove the modifiers on the building and the builders
        building:RemoveModifierByName("modifier_repairing_building")
        print("Building Fully Healed")
        for _,v in pairs(building.units_repairing) do
            local builder = EntIndexToHScript(v)
            if builder and IsValidEntity(builder) then
                builder:RemoveModifierByName("modifier_builder_repairing")
                builder.state = "idle"

                --This should only be done to the additional assisting builders, not the main one that started the construction
                if not builder.work then
                    BuildingHelper:AdvanceQueue(builder)
                end
            end
        end
        -- Toggle off
        ToggleOff(ability)

        --[[print("Repair End")
        print("Start HP/Gold/Lumber/Time: ", building.health_deficit, gold_cost, lumber_cost, build_time)
        print("Final HP/Gold/Lumber/Time: ", building:GetHealth(), building.gold_used, math.floor(building.lumber_used), GameRules:GetGameTime() - building.time_started)]]
        building.health_deficit = nil
    end

    -- Construction Ended
    if building.missingHealthToComplete and building.missingHealthToComplete <= 0 then
        building.missingHealthToComplete = nil
        building.constructionCompleted = true -- BuildingHelper will track this and know the building ended
    else
        --print("Missing Health to Complete building: ",building.missingHealthToComplete)
    end
end

function BuilderRepairing( event )
    local caster = event.caster
    local ability = event.ability
    local target = caster.repair_target

    print("Builder Repairing ",target:GetUnitName(), caster, ability, target)
    
    caster.state = "repairing"

    -- Apply a modifier stack to the building, to show how many peasants are working on it (and scale the Powerbuild costs)
    local modifierName = "modifier_repairing_building"
    if target:HasModifier(modifierName) then
        target:SetModifierStackCount( modifierName, ability, target:GetModifierStackCount( modifierName, ability ) + 1 )
    else
        ability:ApplyDataDrivenModifier( caster, target, modifierName, { duration = duration } )
        target:SetModifierStackCount( modifierName, ability, 1 )
    end

    -- Keep a list of the units repairing this building
    if not target.units_repairing then
        target.units_repairing = {}
    end

    table.insert(target.units_repairing, caster:GetEntityIndex())
end

function BuilderStopRepairing( event )
    local caster = event.caster
    local ability = event.ability
    local building = caster.repair_target

    local ability_order = event.event_ability
    if ability_order then
        local order_name = ability_order:GetAbilityName()
        if string.match(order_name,"build_") then
            return
        end
    end
    
    caster:RemoveModifierByName("modifier_on_order_cancel_repair")
    caster:RemoveModifierByName("modifier_builder_repairing")
    caster:RemoveGesture(ACT_DOTA_ATTACK)

    caster.state = "idle"

    -- Apply a modifier stack to the building, to show how many builders are working on it (and scale the Powerbuild costs)
    local modifierName = "modifier_repairing_building"
    if building and IsValidEntity(building) and building:HasModifier(modifierName) then
        local current_stack = building:GetModifierStackCount( modifierName, ability )
        if current_stack > 1 then
            building:SetModifierStackCount( modifierName, ability, current_stack - 1 )
        else
            building:RemoveModifierByName( modifierName )
        end
    end

    -- Remove the builder from the list of units repairing the building
    local builder = getIndexTable(building.units_repairing, caster:GetEntityIndex())
    if builder and builder ~= -1 then
        table.remove(building.units_repairing, builder)
    end
end

function RepairAnimation( event )
    local caster = event.caster
    caster:StartGesture(ACT_DOTA_ATTACK)
end