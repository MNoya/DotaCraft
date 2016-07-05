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
    local playerID = caster:GetPlayerOwnerID()
    caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_3)
    caster:EmitSound("Hero_LoneDruid.TrueForm.Cast")

    -- Disable rejuvenation
    local rejuvenation = caster:FindAbilityByName("nightelf_rejuvenation")
    if rejuvenation then
        rejuvenation:SetHidden(true)
    end

    -- Disable roar unless the player has mark of the claw researched
    if not Players:HasResearch(playerID, "nightelf_research_mark_of_the_claw") then
        local roar_ability = caster:FindAbilityByName("nightelf_roar")
        roar_ability:SetLevel(0)
    end
end

function BearFormOff( event )
    local caster = event.caster
    local playerID = caster:GetPlayerOwnerID()
    caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_4)
    caster:EmitSound("Hero_LoneDruid.TrueForm.Recast")
    
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/true_form_lone_druid.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())

    -- Enable rejuvenation if the research is valid
    if Players:HasResearch(playerID, "nightelf_research_druid_of_the_claw_training1") then
        local rejuvenation = caster:FindAbilityByName("nightelf_rejuvenation")
        rejuvenation:SetHidden(false)
    else
        CheckAbilityRequirements( caster, playerID )
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
    caster:AddNewModifier(caster, nil, "modifier_druid_bear_model", {})

    -- Bonus Health
    local bear_hp = ability:GetSpecialValueFor("bear_hp")
    local newCurrentHp = math.ceil(bear_hp * caster:GetHealth()/caster:GetMaxHealth())
    caster.bonus_hp = bear_hp - caster:GetMaxHealth()
    caster:SetMaxHealth(bear_hp)
    caster:SetBaseMaxHealth(bear_hp)
    caster:SetHealth(newCurrentHp)

    -- Add weapon/armor upgrade benefits
    ApplyMultiRankUpgrade(caster, "nightelf_research_strength_of_the_wild", "weapon")
    ApplyMultiRankUpgrade(caster, "nightelf_research_reinforced_hides", "armor")

    -- Swap sub_ability
    local sub_ability_name = event.sub_ability_name
    local main_ability_name = ability:GetAbilityName()

    caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
end

-- Reverts back to the original model, swaps abilities, removes modifier passed
function TrueFormEnd( event )
    local caster = event.caster
    local ability = event.ability
    local modifier = event.remove_modifier_name

    -- Revert model change
    caster:RemoveModifierByName("modifier_druid_bear_model")

    -- Minus Health
    local bonus_hp = caster.bonus_hp
    local druid_hp = caster:GetMaxHealth() - bonus_hp
    local newCurrentHp = math.ceil(druid_hp * caster:GetHealth()/caster:GetMaxHealth())
    caster:SetMaxHealth(druid_hp)
    caster:SetBaseMaxHealth(druid_hp)
    caster:SetHealth(newCurrentHp)

    -- Remove abilities and modifiers from weapon/armor upgrades
    for i=0,15 do
        local ability = caster:GetAbilityByIndex(i)
        if ability then
            local ability_name = ability:GetAbilityName()
            if ( string.match(ability_name, "nightelf_strength_of_the_wild") or string.match(ability_name, "nightelf_reinforced_hides") ) then
                caster:RemoveAbility(ability:GetAbilityName())
            end
        end
    end

    caster:RemoveModifierByName("modifier_strength_of_the_wild")
    caster:RemoveModifierByName("modifier_druids_mountain_giant_damage")
    caster:RemoveModifierByName("modifier_reinforced_hides")

    -- Swap the sub_ability back to normal
    local main_ability_name = event.main_ability_name
    local sub_ability_name = ability:GetAbilityName()

    caster:SwapAbilities(sub_ability_name, main_ability_name, false, true)

    -- Remove modifier
    caster:RemoveModifierByName("modifier_bear_form")
end