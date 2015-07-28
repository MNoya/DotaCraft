function RoarAnimation( event )
    local caster = event.caster

    -- Bear Form
    if caster:HasModifier("modifier_bear_form") then
        caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)

    -- Druid Form
    else
        caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_2)
    end
end

function BearFormOn( event )
    local caster = event.caster
    local player = caster:GetPlayerOwner()
    caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_3)
    caster:EmitSound("Hero_LoneDruid.TrueForm.Cast")

    -- Disable rejuvenation
    local rejuvenation = caster:FindAbilityByName("nightelf_rejuvenation")
    if rejuvenation then
        rejuvenation:SetHidden(true)
    end

    -- Disable roar unless the player has mark of the claw researched
    if not PlayerHasResearch(player, "nightelf_research_mark_of_the_claw") then
        local roar_ability = caster:FindAbilityByName("nightelf_roar")
        roar_ability:SetLevel(0)
    end
end

function BearFormOff( event )
    local caster = event.caster
    local player = caster:GetPlayerOwner()
    caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_4)
    caster:EmitSound("Hero_LoneDruid.TrueForm.Recast")
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/true_form_lone_druid.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())

    -- Enable rejuvenation if the research is valid
    if PlayerHasResearch(player, "nightelf_research_druid_of_the_claw_training1") then
        local rejuvenation = caster:FindAbilityByName("nightelf_rejuvenation")
        rejuvenation:SetHidden(false)
    end

    -- Enable roar
    local roar_ability = caster:FindAbilityByName("nightelf_roar")
    roar_ability:SetLevel(1)
end

function TrueFormStart( event )
    local caster = event.caster
    local model = event.model
    local ability = event.ability

    -- Saves the original model
    if caster.caster_model == nil then 
        caster.caster_model = caster:GetModelName()
    end

    -- Sets the new model
    caster:SetModel(model)
    caster:SetOriginalModel(model)

    -- Bonus Health
    local bonus_hp = ability:GetSpecialValueFor("bonus_hp")
    local relative_hp = caster:GetHealthPercent() * caster:GetHealth()
    caster:SetMaxHealth(caster:GetHealth() + bonus_hp)
    caster:SetBaseMaxHealth(caster:GetHealth() + bonus_hp)
    caster:SetHealth(relative_hp)
    caster.bonus_hp = bonus_hp

    -- Swap sub_ability
    local sub_ability_name = event.sub_ability_name
    local main_ability_name = ability:GetAbilityName()

    caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
    print("Swapped "..main_ability_name.." with " ..sub_ability_name)

end

-- Reverts back to the original model, swaps abilities, removes modifier passed
function TrueFormEnd( event )
    local caster = event.caster
    local ability = event.ability
    local modifier = event.remove_modifier_name

    caster:SetModel(caster.caster_model)
    caster:SetOriginalModel(caster.caster_model)

    -- Minus Health
    local bonus_hp = caster.bonus_hp
    local relative_hp = caster:GetHealthPercent() * caster:GetHealth()
    caster:SetMaxHealth(caster:GetHealth() - bonus_hp)
    caster:SetBaseMaxHealth(caster:GetHealth() - bonus_hp)
    caster:SetHealth(relative_hp)

    -- Swap the sub_ability back to normal
    local main_ability_name = event.main_ability_name
    local sub_ability_name = ability:GetAbilityName()

    caster:SwapAbilities(sub_ability_name, main_ability_name, false, true)
    print("Swapped "..sub_ability_name.." with " ..main_ability_name)

    -- Remove modifier
    caster:RemoveModifierByName(modifier)
end

function HideWearables( event )
    local hero = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )

    local model = hero:FirstMoveChild()
    while model ~= nil do
        if model:GetClassname() ~= "" and model:GetClassname() == "dota_item_wearable" then
            model:AddEffects(EF_NODRAW)
        end
        model = model:NextMovePeer()
    end
end

function ShowWearables( event )
    local hero = event.caster

    local model = hero:FirstMoveChild()
    while model ~= nil do
        if model:GetClassname() ~= "" and model:GetClassname() == "dota_item_wearable" then
            model:RemoveEffects(EF_NODRAW)
        end
        model = model:NextMovePeer()
    end
end