-- Adds modifier_model_scale
function AvatarResize( event )
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor( "duration" , ability:GetLevel() - 1  )
    local model_size = ability:GetLevelSpecialValueFor( "model_size" , ability:GetLevel() - 1  )

    caster:AddNewModifier(caster,ability,"modifier_model_scale",{duration=duration,scale=model_size})
end