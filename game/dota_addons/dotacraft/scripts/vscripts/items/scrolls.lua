function Regeneration(event)
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetSpecialValueFor("radius")
    local duration = ability:GetSpecialValueFor("duration")
    local allies = FindOrganicAlliesInRadius(caster, radius)
    for _,unit in pairs(allies) do
        ability:ApplyDataDrivenModifier(caster, unit, "modifier_scroll_of_regeneration", {duration=duration})
    end
end

function Restoration(event)
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetSpecialValueFor("radius")
    local health_restored = ability:GetSpecialValueFor("health_restored")
    local mana_restored = ability:GetSpecialValueFor("mana_restored")
    local allies = FindOrganicAlliesInRadius(caster, radius)
    for _,unit in pairs(allies) do
        local manaGain = math.min(mana_restored, unit:GetMaxMana() - unit:GetMana())
        unit:GiveMana(manaGain)
        if manaGain > 0 then
            PopupMana(unit, manaGain)
        end

        local hpGain = math.min(health_restored, unit:GetHealthDeficit())
        unit:Heal(hpGain,caster)
        if hpGain > 0 then
            PopupHealing(unit, hpGain)
        end
    end
end

function Healing(event)
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetSpecialValueFor("radius")
    local health_restored = ability:GetSpecialValueFor("health_restored")
    local mana_restored = ability:GetSpecialValueFor("mana_restored")
    local allies = FindOrganicAlliesInRadius(caster, radius)
    for _,unit in pairs(allies) do
        local hpGain = math.min(health_restored, unit:GetHealthDeficit())
        unit:Heal(hpGain,caster)
        if hpGain > 0 then
            PopupHealing(unit, hpGain)
        end
    end
end