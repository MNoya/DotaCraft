function Retrain( event )
    local hero = event.caster
    local level = hero:GetLevel()

    for i=0,15 do
        local ability = hero:GetAbilityByIndex(i)
        if ability then ability:SetLevel(0) end
    end

    hero:SetAbilityPoints(level)
    -- Add particle effect on hero
end