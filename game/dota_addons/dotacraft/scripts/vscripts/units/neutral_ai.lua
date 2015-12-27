AI_THINK_INTERVAL = 0.5
AI_STATE_IDLE = 0
AI_STATE_AGGRESSIVE = 1
AI_STATE_RETURNING = 2
AI_STATE_SLEEPING = 3

NeutralAI = {}
NeutralAI.__index = NeutralAI

function NeutralAI:Start( unit )
    --print("Starting NeutralAI for "..unit:GetUnitName().." "..unit:GetEntityIndex())

    local ai = {}
    setmetatable( ai, NeutralAI )

    ai.unit = unit --The unit this AI is controlling
    ai.stateThinks = { --Add thinking functions for each state
        [AI_STATE_IDLE] = 'IdleThink',
        [AI_STATE_AGGRESSIVE] = 'AggressiveThink',
        [AI_STATE_RETURNING] = 'ReturningThink',
        [AI_STATE_SLEEPING] = 'SleepThink'
    }

    unit.state = AI_STATE_IDLE
    unit.spawnPos = unit:GetAbsOrigin()
    unit.campCenter = FindCreepCampCenter(unit)
    unit.allies = FindAllUnitsAroundPoint(unit, unit.campCenter, 1000)
    unit.acquireRange = unit:GetAcquisitionRange()
    unit.aggroRange = 200 --Range an enemy unit has to be for the group to go from IDLE to AGGRESIVE
    unit.leashRange = unit.acquireRange * 2 --Range from spawnPos to go from AGGRESIVE to RETURNING

    -- Disable normal ways of acquisition
    unit:SetIdleAcquire(false)
    unit:SetAcquisitionRange(0)

    --Start thinking
    Timers:CreateTimer(function()
        return ai:GlobalThink()
    end)

    return ai
end

function NeutralAI:GlobalThink()
    local unit = self.unit

    if not IsValidAlive(unit) then
        return nil
    end

    --Execute the think function that belongs to the current state
    Dynamic_Wrap(NeutralAI, self.stateThinks[ unit.state ])( self )

    return AI_THINK_INTERVAL
end

function NeutralAI:IdleThink()
    local unit = self.unit

    -- Sleep
    if not GameRules:IsDaytime() then
        ApplyModifier(unit, "modifier_neutral_sleep")

        unit.state = AI_STATE_SLEEPING
        return true
    end

    local target = FindAttackableEnemies( unit, unit.aggroRange )

    --Start attacking as a group
    if target then
        for _,v in pairs(unit.allies) do
            if IsValidAlive(v) then
                if v.state == AI_STATE_IDLE then
                    v:MoveToTargetToAttack(target)
                    v.aggroTarget = target
                    v.state = AI_STATE_AGGRESSIVE
                end
            end
        end    
        return true
    end
end

function NeutralAI:SleepThink()
    local unit = self.unit

    -- Wake up
    if GameRules:IsDaytime() then
        unit:RemoveModifierByName("modifier_neutral_sleep")

        unit.state = AI_STATE_IDLE
        return true
    end
end

function NeutralAI:AggressiveThink()
    local unit = self.unit

    --Check if the unit has walked outside its leash range
    local distanceFromSpawn = ( unit.spawnPos - unit:GetAbsOrigin() ):Length2D()
    if distanceFromSpawn >= unit.leashRange then
        unit:MoveToPosition( unit.spawnPos )
        unit.state = AI_STATE_RETURNING
        unit.aggroTarget = nil
        return true
    end
    
    -- Use the acquisition range to find enemies while in aggro state
    local target = FindAttackableEnemies( unit, unit.acquireRange )
    
    --Check if the unit's target is still alive
    if not IsValidAlive(unit.aggroTarget) then
        -- If there is no other valid target, return
        if not target then
            unit:MoveToPosition( unit.spawnPos )
            unit.state = AI_STATE_RETURNING
            unit.aggroTarget = nil    
        else
            unit:MoveToTargetToAttack(target)
            unit.aggroTarget = target
        end
        return true
    
    -- If the current aggro target is still valid
    else
        if target then
            local range_to_current_target = unit:GetRangeToUnit(unit.aggroTarget)
            local range_to_closest_target = unit:GetRangeToUnit(target)

            -- If the range to the current target exceeds the attack range of the attacker, and there is a possible target closer to it, attack that one instead
            if range_to_current_target > unit:GetAttackRange() and range_to_current_target > range_to_closest_target then
                unit:MoveToTargetToAttack(target)
                unit.aggroTarget = target
            end
        else    
            -- Can't attack the current target and there aren't more targets close
            if not UnitCanAttackTarget(unit, unit.aggroTarget) or unit.aggroTarget:HasModifier("modifier_invisible") or unit:GetRangeToUnit(unit.aggroTarget) > unit.leashRange then
                unit:MoveToPosition( unit.spawnPos )
                unit.state = AI_STATE_RETURNING
                unit.aggroTarget = nil
            end
        end
    end
    return true
end

function NeutralAI:ReturningThink()
    local unit = self.unit

    --Check if the AI unit has reached its spawn location yet
    if ( unit.spawnPos - unit:GetAbsOrigin() ):Length2D() < 10 then
        --Go into the idle state
        unit.state = AI_STATE_IDLE
        ApplyModifier(unit, "modifier_neutral_idle_aggro")
        return true
    end
end

-- Return a valid attackable unit or nil if there are none
function FindAttackableEnemies( unit, radius )
    local enemies = FindEnemiesInRadius( unit, radius )
    for _,target in pairs(enemies) do
        if UnitCanAttackTarget(unit, target) and not target:HasModifier("modifier_invisible") then
            return target
        end
    end
    return nil
end

-- Looks for the center minimap_ unit
function FindCreepCampCenter( unit )
    local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, unit:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
                                    DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST, false)
    for _,neutral in pairs(units) do
        if string.match(neutral:GetUnitName(), "minimap_") then
            return neutral:GetAbsOrigin()
        end
    end
end