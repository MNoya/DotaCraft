AI_THINK_INTERVAL = 0.5
AI_STATE_IDLE = 0
AI_STATE_AGGRESSIVE = 1
AI_STATE_RETURNING = 2
AI_STATE_SLEEPING = 3

NeutralAI = {}
NeutralAI.__index = NeutralAI

function NeutralAI:Start( unit )
    unit.id = unit:GetUnitName().." "..unit:GetEntityIndex()
    --print("[NeutralAI] Starting "..unit.id)

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
    Timers:CreateTimer(0.03, function() unit.spawnPos = unit:GetAbsOrigin() end)
    unit.acquireRange = unit:GetAcquisitionRange()
    unit.aggroRange = 200 --Range an enemy unit has to be for the group to go from IDLE to AGGRESIVE
    unit.leashRange = unit.acquireRange * 2 --Range from spawnPos to go from AGGRESIVE to RETURNING
    unit.campCenter = FindCreepCampCenter(unit)
    if not unit.campCenter then
        print("[NeutralAI] Error: Cant find minimap_ entity nearby "..unit:GetUnitName())
        unit.allies = {unit}
    else
        unit.allies = FindAllUnitsAroundPoint(unit, unit.campCenter, 1000)
    end

    -- Disable normal ways of acquisition
    unit:SetIdleAcquire(false)
    unit:SetAcquisitionRange(0)

    -- Check ability AI block
    unit.ai_abilities = {}
    for i=0,15 do
        local ability = unit:GetAbilityByIndex(i)
        if ability then
            local ability_ai = ability:GetKeyValue("AI")
            if ability_ai then
                ability.ai = ability_ai
                table.insert(unit.ai_abilities, ability)
            end
        end
    end
    if #unit.ai_abilities == 0 then unit.ai_abilities = nil end

    -- Start thinking
    Timers:CreateTimer(function()
        return ai:GlobalThink()
    end)

    return ai
end

function NeutralAI:GlobalThink()
    local unit = self.unit

    if not IsValidAlive(unit) or unit:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then return end

    --Execute the think function that belongs to the current state
    local thinkInterval = Dynamic_Wrap(NeutralAI, self.stateThinks[ unit.state ])( self )

    return AI_THINK_INTERVAL
end

function NeutralAI:IdleThink()
    local unit = self.unit

    -- Sleep
    if not GameRules:IsDaytime() then
        ApplyModifier(unit, "modifier_neutral_sleep")
        unit.state = AI_STATE_SLEEPING
        return
    end

    local target = FindAttackableEnemy( unit, unit.aggroRange )

    -- Start attacking as a group
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
        return
    end
end

function NeutralAI:SleepThink()
    local unit = self.unit

    -- Wake up
    if GameRules:IsDaytime() then
        unit:RemoveModifierByName("modifier_neutral_sleep")
        unit.state = AI_STATE_IDLE
        return
    end
end

function NeutralAI:AggressiveThink()
    local unit = self.unit

    -- Check if the unit has walked outside its leash range
    local distanceFromSpawn = ( unit.spawnPos - unit:GetAbsOrigin() ):Length2D()
    if distanceFromSpawn >= unit.leashRange then
        unit:MoveToPosition( unit.spawnPos )
        unit.state = AI_STATE_RETURNING
        unit.aggroTarget = nil
        --print("[NeutralAI] "..unit.id.." stopped at "..math.floor(distanceFromSpawn).. " ("..unit.leashRange.." leash range)")
        return
    end

    if unit.ai_abilities then
        local abilityCast = NeutralAI.ThinkAbilities(self)
        if abilityCast then
            --print("[NeutralAI] "..unit.id.." cast ".. abilityCast:GetAbilityName())
            return abilityCast:GetCastPoint() + abilityCast:GetChannelTime() + 0.1 -- Continue attack orders only after the ability finishes casting
        end
    end
    
    -- Use the acquisition range to find enemies while in aggro state
    local target = FindAttackableEnemy( unit, unit.acquireRange )
    
    -- If the unit doesn't have an aggro target, assign a new one
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
end

function NeutralAI:ReturningThink()
    local unit = self.unit

    --Check if the AI unit has reached its spawn location yet
    if ( unit.spawnPos - unit:GetAbsOrigin() ):Length2D() < 10 then
        --Go into the idle state
        unit.state = AI_STATE_IDLE
        ApplyModifier(unit, "modifier_neutral_idle_aggro")
        return
    end
end

NeutralAI.CastLogic = {}
NeutralAI.CastLogic["OnCooldown"] = function(...) return NeutralAI.CastOnCooldown(...) end
NeutralAI.CastLogic["TargetsAround"] = function(...) NeutralAI.CastOnTargetsAround(...) end
NeutralAI.CastLogic["AllyHealthDeficit"] = function(...) return NeutralAI.CastOnAllyHealthDeficit(...) end
NeutralAI.CastLogic["LinedTargets"] = function(...) return NeutralAI.CastOnLinedTargets(...) end

function NeutralAI:ThinkAbilities()
    local unit = self.unit

    for _,ability in pairs(unit.ai_abilities) do
        if ability:IsFullyCastable() and not ability:IsInAbilityPhase() then
            local logic = ability.ai.CastLogic
            if NeutralAI.CastLogic[logic] and NeutralAI.CastLogic[logic](self, ability) then
                return ability -- Something was cast
            end
        end
    end
end

function NeutralAI:CastOnCooldown(ability)
    local unit = self.unit

    -- No-Target abilities are used asap
    if ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_NO_TARGET) then
        unit:CastAbilityNoTarget(ability,-1)
        return true
    else
        -- Unit-Target abilities can check for air units
        local bPrioritizeAirUnits = ability.ai.PriorizeAirUnits
        local enemies = FindEnemiesInRadius(unit, ability:GetCastRange())
        local modifierName = ability.ai.ModifierName
        local target

        if bPrioritizeAirUnits then
            if modifierName then
                target = FindFirstUnit(enemies, function(v) return not v:IsFlyingUnit() and not v:HasModifier(modifierName) and not v.targetedByNeutralAbility end)
            else
                target = FindFirstUnit(enemies, function(v) return not v:IsFlyingUnit() end)
            end
        else
            if modifierName then
                target = FindFirstUnit(enemies, function(v) return not v:HasModifier(modifierName) and not v.targetedByNeutralAbility end)
            else
                target = enemies[1]
            end
        end
        if target then
            if ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
                unit:CastAbilityOnTarget(target,ability,-1)
                if modifierName then
                    target.targetedByNeutralAbility = modifierName -- Prevent two units from targeting the same ability on the same target
                    Timers:CreateTimer(0.1+ability:GetCastPoint(), function() target.targetedByNeutralAbility = nil end)
                end
                return true
            end
        end
    end
end
 
function NeutralAI:CastOnTargetsAround(ability)
    local unit = self.unit
    if ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_NO_TARGET) then
        -- No Target abilities must have its find radius defined in "AbilityCastRange"
        local enemies = FindUnitsInRadius(unit:GetTeamNumber(), unit:GetAbsOrigin(),  nil, ability:GetCastRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)
        local nMinTargets = ability.ai.MinTargets
        if #enemies >= nMinTargets then
            unit:CastAbilityNoTarget(ability,-1)
            return true
        end
    end
end

function NeutralAI:CastOnAllyHealthDeficit(ability)
    local unit = self.unit
    local nHealthPercent = ability.ai.HealthPercent

    for _,ally in pairs(unit.allies) do
        if IsValidEntity(ally) and ally:IsAlive() and ally:GetHealthPercent() <= nHealthPercent then
            -- Point Target abilities are cast behind the caster
            if ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_POINT) then
                local pos = unit:GetAbsOrigin() - unit:GetForwardVector() * 150
                unit:CastAbilityOnPosition(pos,ability,-1)
                return true
            end
        end
    end
end

function NeutralAI:CastOnLinedTargets(ability)
    local unit = self.unit
    local nLineWidth = ability.ai.LineWidth
    local nMinTargets = ability.ai.MinTargets

    -- Point Target abilities check a line towards each unit
    if ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_POINT) then
        local enemies = FindUnitsInRadius(unit:GetTeamNumber(), unit:GetAbsOrigin(),  nil, ability:GetCastRange(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_FARTHEST, false)
        for _,enemy in pairs(enemies) do
            local lineEnemies = FindUnitsInLine(unit:GetTeamNumber(), unit:GetAbsOrigin(), enemy:GetAbsOrigin(), nil, nLineWidth, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS)
            if #enemies >= nMinTargets then
                unit:CastAbilityOnPosition(enemy:GetAbsOrigin(),ability,-1)
                return true
            end
        end
    end
end


-------------------------------------------------------------------

-- Return a valid attackable unit or nil if there are none
function FindAttackableEnemy( unit, radius )
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
        if neutral:GetUnitName():match("minimap_") then
            return neutral:GetAbsOrigin()
        end
    end
end