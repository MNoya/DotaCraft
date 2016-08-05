-- Resurrects units near the caster, using the corpse mechanic.
function AnimateDead( event )
    local caster = event.caster
    local ability = event.ability
    local playerID = caster:GetPlayerOwnerID()
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local team = caster:GetTeamNumber()
    local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
    local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
    local max_units_resurrected = ability:GetLevelSpecialValueFor( "max_units_resurrected", ability:GetLevel() - 1 )

    -- Find all corpse entities in the radius and start the counter of units resurrected.
    local corpses = Corpses:FindInRadius(playerID, caster:GetAbsOrigin(), radius)
    local units_resurrected = 0

    -- Go through the units
    for _, corpse in pairs(corpses) do
        if units_resurrected < max_units_resurrected then

            -- The corpse has a unit_name associated.
            local unit = CreateUnitByName(corpse.unit_name, corpse:GetAbsOrigin(), true, caster, caster, team)
            unit:SetControllableByPlayer(playerID, true)
            unit:SetOwner(hero)
            unit:SetForwardVector(corpse:GetForwardVector())
            FindClearSpaceForUnit(resurrected,corpse:GetAbsOrigin(),true)

            -- Apply modifiers for the summon properties
            unit:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
            ability:ApplyDataDrivenModifier(caster, unit, "modifier_animate_dead", nil)

            -- Remove non-passive abilities
            for i=0,15 do
                local a = unit:GetAbilityByIndex(i)
                if a and not a:IsPassive() then
                    UTIL_Remove(a)
                end
            end

            -- Leave no corpses
            unit:SetNoCorpse()
            corpse:RemoveCorpse()

            -- Increase the counter of units resurrected
            units_resurrected = units_resurrected + 1
        end
    end
end