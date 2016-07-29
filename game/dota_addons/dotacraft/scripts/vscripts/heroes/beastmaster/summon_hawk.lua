local hawkNames = {
    [1] = "neutral_beastmaster_hawk",
    [2] = "neutral_beastmaster_thunder_hawk",
    [3] = "neutral_beastmaster_spirit_hawk",
}
function SpawnHawk(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel()-1)
    local fv = caster:GetForwardVector()
    local position = caster:GetAbsOrigin() + fv * 200
    local playerID = caster:GetPlayerOwnerID()
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    local hawk = caster:CreateSummon(hawkNames[ability:GetLevel()], position, duration)
    ability:ApplyDataDrivenModifier(caster, hawk, "modifier_beastmaster_bird", {})

    -- Initialize the attack and move trackers
    hawk.hawkMoved = GameRules:GetGameTime()
    hawk.hawkAttacked = GameRules:GetGameTime()
end

--------------------------------------------------------------------------------

-- Keeps track of the last time the hawk moved
function HawkMoved( event )
    local caster = event.caster
    caster.hawkMoved = GameRules:GetGameTime()
end

-- Keeps track of the last time the hawk attacked
function HawkAttacked( event )
    local caster = event.caster
    caster.hawkAttacked = GameRules:GetGameTime()
end

-- If the hawk hasn't moved or attacked in the last duration, apply invis
function HawkInvisCheck( event )
    local caster = event.caster
    local ability = event.ability
    local motionless_time = ability:GetLevelSpecialValueFor("motionless_time", ability:GetLevel() - 1)

    local current_time = GameRules:GetGameTime()
    if (current_time - caster.hawkAttacked) > motionless_time and (current_time - caster.hawkMoved) > motionless_time then
        caster:AddNewModifier(caster, ability, "modifier_invisible", {}) 
    end
end