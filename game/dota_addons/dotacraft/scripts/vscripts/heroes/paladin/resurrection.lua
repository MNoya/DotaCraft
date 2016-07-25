--[[
    Author: Noya
    Resurrects friendly units near the caster, using the corpse mechanic.
    The spell will choose the most powerful corpses to resurrect if there are too many to revive
]]
function Resurrection( event )
    local caster = event.caster
    local ability = event.ability
    local playerID = caster:GetPlayerOwnerID()
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local team = caster:GetTeamNumber()
    local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
    local max_units_resurrected = ability:GetLevelSpecialValueFor( "max_units_resurrected", ability:GetLevel() - 1 )

    -- Find all corpse entities in the radius and start the counter of units resurrected.
    local targets = Corpses:FindAlliedInRadius(playerID, caster:GetAbsOrigin(), radius)

    -- Sort by level if necessary
    local resurrect_targets = targets
    if #targets > max_units_resurrected then
        resurrect_targets = {}
        local maxLevel = 0
        for _,unit in pairs(targets) do
            local level = unit:GetLevel()
            if level > maxLevel then maxLevel = level end
        end
        for i=maxLevel,0,-1 do
            for _,unit in pairs(targets) do
                if unit:GetLevel() == i then
                    table.insert(resurrect_targets, unit)
                end
                if #resurrect_targets == max_units_resurrected then
                    break
                end
            end
        end
    end

    -- Go through the units
    for _, corpse in pairs(resurrect_targets) do
        -- The corpse has a unit_name associated.
        local position = corpse:GetAbsOrigin()
        local resurrected = CreateUnitByName(corpse.unit_name, position, true, hero, hero, team)
        resurrected:SetControllableByPlayer(playerID, true)
        resurrected:SetOwner(hero)
        resurrected:SetForwardVector(corpse:GetForwardVector())
        FindClearSpaceForUnit(resurrected, position, true)

        Players:AddUnit(playerID, resurrected)
        CheckAbilityRequirements(resurrected, playerID)

        local foodCost = GetFoodCost(resurrected)
        if foodCost and foodCost > 0 then
            Players:ModifyFoodLimit(playerID, foodCost)
        end

        -- Apply modifiers for the summon properties
        ability:ApplyDataDrivenModifier(caster, resurrected, "modifier_resurrection", nil)

        -- Leave no corpses
        resurrected:SetNoCorpse()
        corpse:RemoveCorpse()
    end
end