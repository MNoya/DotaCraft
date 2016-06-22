function Healing(event)
    local caster = event.caster
    local ability = event.ability
    local heal = ability:GetSpecialValueFor("heal")
    local radius = ability:GetSpecialValueFor("radius")
    local allies = FindAlliesInRadius(caster, radius)
    for _,unit in pairs(allies) do
        local value = math.min(heal, unit:GetHealthDeficit())
        unit:Heal(value,caster)
        PopupHealing(unit, value)
    end
end

function Watcher(event)
    local caster = event.caster
    local ability = event.ability
    local origin = event.caster:GetAbsOrigin()
    local point = origin + caster:GetForwardVector() * 150
    local sentry = CreateUnitByName('warcraft_sentry_ward', point, false, caster, caster, caster:GetTeamNumber())
    ability:ApplyDataDrivenModifier(sentry,sentry,"modifier_sentry_ward",{})
    sentry:EmitSound('DOTA_Item.SentryWard.Activate')
    sentry:EmitSound('DOTA_Item.ObserverWard.Activate')
end