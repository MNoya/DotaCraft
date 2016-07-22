-- NOTE: There should be a separate Call To Arms ability on each peasant but it's
--       currently not possible because there's not enough ability slots visible
function CallToArms( event )
    local ability = event.ability
    local building = event.caster -- Can change during the course of the timer if the building is upgraded
    local playerID = building:GetPlayerOwnerID()

    local units = FindAlliesInRadius(building, ability:GetCastRange()) --Radius of the bell ring
    local foundPeasants = false
    for _,unit in pairs(units) do
        if unit:GetUnitName() == "human_peasant" then
            foundPeasants = true
            CallToArmsPeasant({ability=ability,target=unit,caster=building})
        end
    end

    if not foundPeasants then
        SendErrorMessage(playerID, "error_no_peasants_found")
    end
end

function CallToArmsPeasant(event)
    local ability = event.ability
    local unit = event.target
    local building = event.caster
    if not unit:GetUnitName() == "human_peasant" then return end

    unit:CancelGather()
    ExecuteOrderFromTable({UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_STOP, Queue = false}) 

    local position = unit:GetReturnPosition(building)
    unit.target_building = building

    if unit.move_to_build_timer then Timers:RemoveTimer(unit.move_to_build_timer) end

    -- Start moving towards the city center
    unit:MoveToPosition(building:GetAbsOrigin())
    unit.move_to_build_timer = Timers:CreateTimer(function()
        if not IsValidAlive(unit) then return end
        if not IsValidAlive(unit.target_building) then
            building = unit:FindClosestResourceDeposit("gold")
            unit.target_building = building
            if building then
                position = unit:GetReturnPosition(building)
                return 1/30
            else return end
        end
        
        local distance = (position - unit:GetAbsOrigin()):Length2D()       
        if distance > 150 then
            unit:MoveToPosition(position)
            return 0.1
        else
            DepositAllResources(unit)

            local hero = PlayerResource:GetSelectedHeroEntity(unit:GetPlayerOwnerID())
            local militia = ReplaceUnit(unit, "human_militia")
            ability:ApplyDataDrivenModifier(militia, militia, "modifier_militia", {})

            -- Add the units to a table so they are easier to find later
            if not hero.militia then
                hero.militia = {}
            end
            table.insert(hero.militia, militia)
        end
    end)
end

function DepositAllResources(caster)
    local playerID = caster:GetPlayerOwnerID()

    local lumber_gathered = caster:GetModifierStackCount("modifier_carrying_lumber",caster)
    caster:RemoveModifierByName("modifier_carrying_lumber")
    if lumber_gathered > 0 then
        PopupLumber(caster, lumber_gathered)
        Players:ModifyLumber(playerID, lumber_gathered)
        Scores:IncrementLumberHarvested(playerID, lumber_gathered)
    end
    caster.lumber_gathered = 0
    
    if caster.gold_gathered > 0 then
        local upkeep = Players:GetUpkeep( playerID )
        local gold_gain = caster.gold_gathered * upkeep

        caster:RemoveModifierByName("modifier_carrying_gold")
        Scores:IncrementGoldMined(playerID, caster.gold_gathered)
        Scores:AddGoldLostToUpkeep(playerID, caster.gold_gathered - gold_gain)

        Players:ModifyGold(playerID, gold_gain)
        PopupGoldGain(caster, gold_gain)
    end
    caster.gold_gathered = 0
end

function BackToWork( event )
    local unit = event.caster -- The militia unit
    local ability = event.ability
    local playerID = unit:GetPlayerOwnerID()

    local building = unit:FindClosestResourceDeposit("gold")
    if not building then return end
    local position = unit:GetReturnPosition(building)
    unit.target_building = building

    if unit.moving_timer then Timers:RemoveTimer(unit.moving_timer) end

    -- Start moving towards the city center
    unit:MoveToPosition(building:GetAbsOrigin())
    unit.moving_timer = Timers:CreateTimer(function()
        if not IsValidAlive(unit) then return end
        if not IsValidAlive(unit.target_building) then
            building = unit:FindClosestResourceDeposit("gold")
            unit.target_building = building
            if building then
                position = unit:GetReturnPosition(building)
                return 1/30
            else return end
        end

        local distance = (position - unit:GetAbsOrigin()):Length()
        if distance > 150 then
            unit:MoveToPosition(position)
            return 0.1
        else
            local peasant = ReplaceUnit(unit, "human_peasant")
            
            CheckAbilityRequirements(peasant, playerID)
        end
    end)
end

function CallToArmsEnd( event )
    local target = event.target
    local playerID = target:GetPlayerOwnerID()
    local peasant = ReplaceUnit( event.target, "human_peasant" )

    CheckAbilityRequirements(peasant, playerID)

    -- Gather ability level adjust
    local level = Players:GetCurrentResearchRank(playerID, "human_research_lumber_harvesting1")
    local ability = peasant:GetGatherAbility()
    ability:SetLevel(1+level)
end

function HideBackpack( event )
    Timers:CreateTimer(function()
        local peasant = event.caster
        local wearableName = "models/items/kunkka/claddish_back/claddish_back.vmdl"
        if not peasant.backpack then
            peasant.backpack = GetWearable(peasant, wearableName)
        end
        peasant.backpack:AddEffects(EF_NODRAW)
    end)
end

function ShowBackpack( event )
    local peasant = event.caster
    peasant.backpack:RemoveEffects(EF_NODRAW)
end