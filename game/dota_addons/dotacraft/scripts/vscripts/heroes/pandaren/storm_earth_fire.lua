--[[
    Author: Noya
    Primal Split
]]

-- Starts the ability
function PrimalSplit( event )
    local caster = event.caster
    local playerID = caster:GetPlayerID()
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor( "duration" , ability:GetLevel() - 1 )
    local level = ability:GetLevel()

    -- Set the unit names to create
    -- EARTH
    local unit_name_earth = event.unit_name_earth

    -- STORM
    local unit_name_storm = event.unit_name_storm

    -- FIRE
    local unit_name_fire = event.unit_name_fire

    -- Set the positions
    local forwardV = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
    local distance = 100
    local ang_right = QAngle(0, -90, 0)
    local ang_left = QAngle(0, 90, 0)

    -- Earth in front
    local earth_position = origin + forwardV * distance

    -- Storm at the left, a bit behind
    local storm_position = RotatePosition(origin, ang_left, earth_position)

    -- Fire at the righ, a bit behind
    local fire_position = RotatePosition(origin, ang_right, earth_position)

    -- Create the units
    caster.Earth = CreateUnitByName(unit_name_earth, earth_position, true, caster, caster, caster:GetTeamNumber())
    caster.Storm = CreateUnitByName(unit_name_storm, storm_position, true, caster, caster, caster:GetTeamNumber())
    caster.Fire = CreateUnitByName(unit_name_fire, fire_position, true, caster, caster, caster:GetTeamNumber())

    PlayerResource:AddToSelection(playerID, caster.Earth)
    PlayerResource:AddToSelection(playerID, caster.Storm)
    PlayerResource:AddToSelection(playerID, caster.Fire)
    PlayerResource:RemoveFromSelection(playerID, caster)

    -- Make them controllable
    caster.Earth:SetControllableByPlayer(playerID, true)
    caster.Storm:SetControllableByPlayer(playerID, true)
    caster.Fire:SetControllableByPlayer(playerID, true)

    -- Set all of them looking at the same point as the caster
    caster.Earth:SetForwardVector(forwardV)
    caster.Storm:SetForwardVector(forwardV)
    caster.Fire:SetForwardVector(forwardV)

    -- Learn all abilities on the units
    LearnAllAbilities(caster.Earth, 1)
    LearnAllAbilities(caster.Storm, 1)
    LearnAllAbilities(caster.Fire, 1)

    -- Apply modifiers to detect units dying
    ability:ApplyDataDrivenModifier(caster, caster.Earth, "modifier_split_unit", {})
    ability:ApplyDataDrivenModifier(caster, caster.Storm, "modifier_split_unit", {})
    ability:ApplyDataDrivenModifier(caster, caster.Fire, "modifier_split_unit", {})

    -- Make them expire after the duration
    caster.Earth:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
    caster.Storm:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
    caster.Fire:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

    -- Set the Earth unit as the primary active of the split (the hero will be periodically moved to the ActiveSplit location)
    caster.ActiveSplit = caster.Earth

    -- Hide the hero underground
    local underground_position = Vector(origin.x, origin.y, origin.z - 322)
    caster:SetAbsOrigin(underground_position)
    caster:AddNoDraw()

    -- Leave no corpses
    caster.Earth.no_corpse = true
    caster.Storm.no_corpse = true
    caster.Fire.no_corpse = true
end

-- When the spell ends, the Brewmaster takes Earth's place. 
-- If Earth is dead he takes Storm's place, and if Storm is dead he takes Fire's place.
function SplitUnitDied( event )
    local caster = event.caster
    local attacker = event.attacker
    local unit = event.unit

    -- Chech which spirits are still alive
    if IsValidEntity(caster.Earth) and caster.Earth:IsAlive() then
        caster.ActiveSplit = caster.Earth
    elseif IsValidEntity(caster.Storm) and caster.Storm:IsAlive() then
        caster.ActiveSplit = caster.Storm
    elseif IsValidEntity(caster.Fire) and caster.Fire:IsAlive() then
        caster.ActiveSplit = caster.Fire
    else
        -- Check if they died because the spell ended, or where killed by an attacker
        -- If the attacker is the same as the unit, it means the summon duration is over.
        if attacker == unit then
            print("Primal Split End Succesfully")
        elseif attacker ~= unit then
            -- Kill the caster with credit to the attacker.
            caster:Kill(nil, attacker)
            caster.ActiveSplit = nil
        end
        caster:RemoveNoDraw()
    end

    if caster.ActiveSplit then
        print(caster.ActiveSplit:GetUnitName() .. " is active now")
    else
        print("All Split Units were killed!")
    end

end

-- While the main spirit is alive, reposition the hero to its position so that auras are carried over.
-- This will also help finding the current Active primal split unit with the hero hotkey
function PrimalSplitAuraMove( event )
    -- Hide the hero underground on the Active Split position
    local caster = event.caster
    local active_split_position = caster.ActiveSplit:GetAbsOrigin()
    local underground_position = Vector(active_split_position.x, active_split_position.y, active_split_position.z - 322)
    caster:SetAbsOrigin(underground_position)
end

-- Ends the the ability, repositioning the hero on the latest active split unit
function PrimalSplitEnd( event )
    local caster = event.caster

    if caster.ActiveSplit then
        local position = caster.ActiveSplit:GetAbsOrigin()
        FindClearSpaceForUnit(caster, position, true)
    end

end

-- Auxiliar Function to loop over all the abilities of the unit and set them to a level
function LearnAllAbilities( unit, level )
    for i=0,15 do
        local ability = unit:GetAbilityByIndex(i)
        if ability then
            ability:SetLevel(level)
        end
    end
end


--- SUB ABILITIES ---

--[[
    Author: Noya
    Changes the attack target of units all targets near to the caster. Doesn't force them to attack for a duration, this is just micro control.
    To force the attack for a duration, use SetForceAttackTarget to caster, and then a timer to nil.
]]
function Taunt( event )
    local caster = event.caster
    local targets = event.target_entities

    for _,unit in pairs(targets) do
        unit:MoveToTargetToAttack(caster)
        --unit:SetForceAttackTarget(caster)
    end
end