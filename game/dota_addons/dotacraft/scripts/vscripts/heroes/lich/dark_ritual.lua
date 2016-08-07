--[[
    Author: Noya
    Kills a target, gives Mana to the caster according to the sacrificed target current Health
    Can only be cast on organic undead units and while the caster has mana deficit
--]]

lich_dark_ritual_warcraft = class({})

function lich_dark_ritual_warcraft:OnSpellStart( event )
    local ability = self
    local caster = ability:GetCaster()
    local target = ability:GetCursorTarget()

    -- Mana to give 
    local target_health = target:GetHealth()
    local rate = ability:GetLevelSpecialValueFor( "health_conversion" , ability:GetLevel() - 1 ) * 0.01
    local mana_gain = math.floor((target_health * rate)+0.5)

    caster:GiveMana(mana_gain)
    caster:EmitSound("Ability.DarkRitual")

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lich/lich_dark_ritual.vpcf",PATTACH_CUSTOMORIGIN,nil)
    ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

    -- Purple particle with eye
    local particleName = "particles/msg_fx/msg_xp.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, target)

    local digits = 0
    if mana_gain ~= nil then
        digits = #tostring(mana_gain)
    end

    ParticleManager:SetParticleControl(particle, 1, Vector(9, mana_gain, 6))
    ParticleManager:SetParticleControl(particle, 2, Vector(1, digits+1, 0))
    ParticleManager:SetParticleControl(particle, 3, Vector(170, 0, 250))

    -- Kill the target, ForceKill doesn't grant xp
    target:SetNoCorpse()
    Timers:CreateTimer(2, function() target:AddNoDraw() end)
    target:ForceKill(true)
end

--------------------------------------------------------------------------------

function lich_dark_ritual_warcraft:CastFilterResultTarget( target )
    local ability = self
    local caster = ability:GetCaster()

    if target:IsHero() then
        return UF_FAIL_HERO
    end

    -- Check missing mana
    if caster:GetMana() == caster:GetMaxMana() then
        return UF_FAIL_CUSTOM
    end

    -- Check undead
    if not (target:GetUnitName():match("undead") or target:GetUnitLabel():match("undead")) then
        return UF_FAIL_CUSTOM
    end

    -- Check mechanical
    if target:GetUnitLabel():match("mechanical") then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end
  
function lich_dark_ritual_warcraft:GetCustomCastErrorTarget( target )
    local ability = self
    local caster = ability:GetCaster()

    -- Check missing mana
    if caster:GetMana() == caster:GetMaxMana() then
        return "#error_full_mana"
    end

    -- Check undead
    if not (target:GetUnitName():match("undead") or target:GetUnitLabel():match("undead")) then
        return "#error_must_target_undead"
    end

    -- Check mechanical
    if target:GetUnitLabel():match("mechanical") then
        return "error_must_target_organic"
    end
 
    return ""
end