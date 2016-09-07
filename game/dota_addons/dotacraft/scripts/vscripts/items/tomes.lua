function Retrain( event )
    local hero = event.caster
    local level = hero:GetLevel()

    hero:Stop()
    local modifiers = hero:FindAllModifiers()
    for i=0,15 do
        local ability = hero:GetAbilityByIndex(i)
        if ability and ability:GetLevel() > 0 then
            if ability:GetAutoCastState() then
                ability:ToggleAutoCast()
            end
            if ability:GetToggleState() then
                ability:ToggleAbility()
            end
            for _,modifier in pairs(modifiers) do
                if modifier and modifier:GetAbility() == ability then
                    modifier.markedToDestroy = true
                end
            end
            ability:SetLevel(0)
        end
    end
    for _,modifier in pairs(modifiers) do
        if modifier.markedToDestroy then
            modifier:Destroy()
        end
    end

    hero:SetAbilityPoints(level)    
    ParticleManager:CreateParticle("particles/custom/items/tome_of_retrain.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
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