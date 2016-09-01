-- This is for the active component
function ShadowMeld( event )
    local caster = event.caster
    local ability = event.ability
    local fade_time = ability:GetSpecialValueFor("fade_time")

    if GameRules:IsDaytime() then
        SendErrorMessage(caster:GetPlayerOwnerID(), "error_shadowmeld_night")
    elseif caster:HasModifier("modifier_shadow_meld") and caster:IsInvisible() then
        ShadowMeldAnimation(caster, fade_time)
        ability:ApplyDataDrivenModifier(caster, caster, "modifier_shadow_meld_active", {})
    elseif not GameRules:IsDaytime() then
        ShadowMeldAnimation(caster, fade_time)

        ability:ApplyDataDrivenModifier(caster, caster, "modifier_shadow_meld", {})
        ability:ApplyDataDrivenModifier(caster, caster, "modifier_shadow_meld_active", {})

        if not ability:IsItem() then
            ToggleOn(ability)
        end
        caster:Stop()
    end
end

function ShadowMeldAnimation(caster, time)
    local unitName = caster:GetUnitName()
    if unitName == "nightelf_archer" then
        StartAnimation(caster, {duration=time, activity=ACT_DOTA_OVERRIDE_ABILITY_2, rate=0.5, translate="sparrowhawk_bow"})
    elseif unitName == "nightelf_huntress" then
        StartAnimation(caster, {duration=time, activity=ACT_DOTA_CAST_ABILITY_1, rate=0.5, translate="moonfall"})
    elseif unitName == "npc_dota_hero_phantom_assassin" then
        StartAnimation(caster, {duration=time, activity=ACT_DOTA_SPAWN})
    elseif unitName == "npc_dota_hero_mirana" then
        StartAnimation(caster, {duration=time, activity=ACT_DOTA_CAST_ABILITY_1})
    end
end

-- This is for the passive component
function ShadowMeldThink( event )
    local caster = event.caster 
    local ability = event.ability
    local fade_time = ability:GetSpecialValueFor("fade_time")

    -- Only available at night time
    if not GameRules:IsDaytime() then
        if ability:GetLevel() == 0 then
            ability:SetLevel(1)
        end

        -- If idle on night time, passively apply the fade out
        if caster:IsIdle() and not caster:GetAttackTarget() and not caster:IsStunned() and not caster:HasModifier("modifier_shadow_meld") and not caster:HasModifier("modifier_mounted_archer") then
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_shadow_meld", {})
        end
    else
        -- Turn off in day time
        if ability:GetLevel() == 1 then
            ShadowMeldRemove(event)
            if not ability:IsItem() then
                ability:SetLevel(0)
            end
        end
    end

    if caster:IsStunned() then
        ShadowMeldRemove(event)
    end
end

-- Modifier created, start fade time
function ShadowMeldApply(event)
    local caster = event.caster
    local ability = event.ability
    caster:AddNewModifier(caster,ability,"modifier_invisibility",{fade_time = 1.5})
end

function ShadowMeldRemove( event )
    local caster = event.caster
    local ability = event.ability
    local order = event.event_ability
    
    if order then
        local ignoreRemoval = order:GetAbilityName() == "nightelf_shadow_meld" or order:GetAbilityName() == "item_cloak_of_shadows"
        if ignoreRemoval then
            if not ability:IsItem() then
                ToggleOn(ability)
            end
            return
        end
    end
    caster:RemoveModifierByName("modifier_shadow_meld_active")
    caster:RemoveModifierByName("modifier_shadow_meld")
    caster:RemoveModifierByName("modifier_invisibility")
    if not ability:IsItem() then
        ToggleOff(ability)
    end
end


-- Only regen at night time
function NightRegenThink( event )
    local caster = event.caster

    if GameRules:IsDaytime() then
        if not caster:HasModifier("modifier_night_regen_disabled") then
            local ability = event.ability
            local base_regen = caster:GetBaseHealthRegen()
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_night_regen_disabled", {})
            caster:SetModifierStackCount("modifier_night_regen_disabled", caster, base_regen*10)
        end
    else
        if caster:HasModifier("modifier_night_regen_disabled") then
            caster:RemoveModifierByName("modifier_night_regen_disabled")
        end
    end
end

-- For Ultravision
function SetNightVision( event )
    local caster = event.caster

    caster:SetNightTimeVisionRange(caster:GetDayTimeVisionRange())
end