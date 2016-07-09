function FreezingAttack(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local teamNumber = caster:GetTeamNumber()
    local duration = ability:GetSpecialValueFor("duration")
    local radius = ability:GetSpecialValueFor("radius")
            
    -- Freeze buildings in radius
    local targets = FindUnitsInRadius(teamNumber, target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
    for k,unit in pairs(targets) do
        if IsCustomBuilding(unit) then
            ability:ApplyDataDrivenModifier(caster, unit, "modifier_frozen",  {duration=duration}) 
        end
    end
end

function Freeze(event)
    local building = event.target

    -- Stop builders repairing
    BuildingHelper:CancelRepair(building)
    
    -- Stop channeling
    local channelingAbility = IsChanneling(building)
    if channelingAbility then
        channelingAbility:EndChannel(true)
    end

    -- Disable all ability usage
    building.frozen_abilities = {}
    for i=0,15 do
        local ability = building:GetAbilityByIndex(i)
        if ability and ability:GetLevel() > 0 then
            ability:SetActivated(false)
            table.insert(building.frozen_abilities, ability)
        end
    end
end

function UnFreeze(event)
    local building = event.target

    -- Reenable abilities
    for _,ability in pairs(building.frozen_abilities) do
        ability:SetActivated(true)
    end
end