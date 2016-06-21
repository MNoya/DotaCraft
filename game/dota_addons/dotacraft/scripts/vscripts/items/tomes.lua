function Retrain( event )
    local item = event.ability
    local hero = event.caster
    local level = hero:GetLevel()

    for i=0,15 do
        local ability = hero:GetAbilityByIndex(i)
        if ability then ability:SetLevel(0) end
    end

    hero:SetAbilityPoints(level)
    UTIL_Remove(item)
    -- Add particle effect on hero
end

function StatTome(event)
    local ability = event.ability
    local hero = event.caster
    local modifierName = event.ModifierName
    ability:ApplyDataDrivenModifier(hero,hero,modifierName,{})
end

function Experience(event)
    local hero = event.caster
    local xp = event.ability:GetSpecialValueFor("bonus_xp")
    hero:AddExperience(xp,0,false,false)
end