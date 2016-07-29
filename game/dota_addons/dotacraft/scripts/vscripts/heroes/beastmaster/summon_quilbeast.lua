local quilbeastNames = {
    [1] = "neutral_beastmaster_quilbeast",
    [2] = "neutral_beastmaster_dire_quilbeast",
    [3] = "neutral_beastmaster_raging_quilbeast",
}
function SpawnQuilbeast(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel()-1)
    local position = caster:GetAbsOrigin() + caster:GetForwardVector() * 200

    local bear = caster:CreateSummon(quilbeastNames[ability:GetLevel()], position, duration)
    ability:ApplyDataDrivenModifier(caster, bear, "modifier_beastmaster_boar", {})
end

--------------------------------------------------------------------------------

--Handles the AutoCast logic after starting an attack
function FrenzyAutocast( event )
    local caster = event.caster
    local ability = event.ability

    -- Name of the modifier to avoid casting the spell if the caster is buffed
    local modifier = "modifier_frenzy"

    -- Get if the ability is on autocast mode and cast the ability if it doesn't have the modifier
    if ability:GetAutoCastState() and not caster:HasModifier(modifier) then
        caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())
    end 
end

--Adds modifier_model_scale
function FrenzyResize( event )
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel()-1)

    caster:AddNewModifier(caster,ability,"modifier_model_scale",{duration=duration,scale=25})
end