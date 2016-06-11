--Handles the AutoCast logic after starting an attack
function FrenzyAutocast( event )
    local caster = event.caster
    local ability = event.ability

    -- Name of the modifier to avoid casting the spell if the caster is buffed
    local modifier = "modifier_frenzy"

    -- Get if the ability is on autocast mode and cast the ability if it doesn't have the modifier
    if ability:GetAutoCastState() then
        if not caster:HasModifier(modifier) then
            caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())
        end
    end 
end

--Adds modifier_model_scale
function FrenzyResize( event )
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor( "duration" , ability:GetLevel() - 1  )
    local model_size = ability:GetLevelSpecialValueFor( "model_size" , ability:GetLevel() - 1  )

    caster:AddNewModifier(caster,ability,"modifier_model_scale",{duration=duration,scale=model_size})
end