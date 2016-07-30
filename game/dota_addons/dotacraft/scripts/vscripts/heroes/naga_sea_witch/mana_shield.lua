--[[
    Author: Noya
    Used from damage filter, recieves damage pre mitigation, checks the mana of the caster and uses it to prevent as much as possible. 
]]
function ManaShieldToggle(event)
    local caster = event.caster
    local ability = event.ability
    local damage_per_mana = ability:GetLevelSpecialValueFor("damage_per_mana", ability:GetLevel()-1)
    local absorption_percent = ability:GetLevelSpecialValueFor("absorption_percent", ability:GetLevel()-1) * 0.01

    ability:ApplyDataDrivenModifier(caster,caster,"modifier_mana_shield",{})
    caster:EmitSound("Hero_Medusa.ManaShield.On")

    function caster:OnIncomingDamage(damage)
        if not caster:HasModifier("modifier_mana_shield") then return damage end
        local caster_mana = caster:GetMana()
        local mana_needed = damage / damage_per_mana
    
        -- If the caster has enough mana, fully heal for the damage done
        damage = damage - math.min(mana_needed, caster_mana)
        caster:SpendMana(mana_needed, ability)
        if mana_needed <= caster_mana then
            caster:EmitSound("Hero_Medusa.ManaShield.Proc")
            
            -- Impact particle based on damage absorbed
            local particleName = "particles/units/heroes/hero_medusa/medusa_mana_shield_impact.vpcf"
            local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, caster)
            ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
            ParticleManager:SetParticleControl(particle, 1, Vector(mana_needed,0,0))
        else
            ParticleManager:CreateParticle("particles/units/heroes/hero_medusa/medusa_mana_shield_oom.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
            ToggleOff(ability)
        end

        return damage
    end
end