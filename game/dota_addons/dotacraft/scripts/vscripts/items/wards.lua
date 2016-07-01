-- Used in orc_sentry_ward and item_sentry_wards
function SummonSentryWard(event)
    local caster = event.caster
    local ability = event.ability
    local origin = event.caster:GetAbsOrigin()
    local point = event.target_points[1]
    local duration = ability:GetSpecialValueFor("duration")
    local sentry = CreateUnitByName('dotacraft_sentry_ward', point, false, caster, caster, caster:GetTeamNumber())
    sentry:AddNewModifier(caster, ability, "modifier_sentry_ward", {})
    sentry:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
    sentry:AddNewModifier(caster, nil, "modifier_summoned", {})
    sentry:EmitSound("DOTA_Item.ObserverWard.Activate")
end

modifier_sentry_ward = class({})

function modifier_sentry_ward:CheckState() 
    return { [MODIFIER_STATE_INVISIBLE] = true, }
end

function modifier_sentry_ward:DeclareFunctions()
    return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL }
end

function modifier_sentry_ward:GetModifierInvisibilityLevel()
    return 1.0
end

function modifier_sentry_ward:GetEffectName()
    return "particles/items2_fx/ward_true_sight.vpcf"
end

function modifier_sentry_ward:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_sentry_ward:IsAura()
    return true
end

function modifier_sentry_ward:IsHidden()
    return true
end

function modifier_sentry_ward:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius") or 1600
end

function modifier_sentry_ward:GetModifierAura()
    return "modifier_truesight"
end
   
function modifier_sentry_ward:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_sentry_ward:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_sentry_ward:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_sentry_ward:GetAuraDuration()
    return 0.1
end

--------------------------------------------------------------------------------

-- Used in orc_healing_ward and item_healing_wards
function SummonHealingWard(event)
    local caster = event.caster
    local ability = event.ability
    local origin = event.caster:GetAbsOrigin()
    local point = event.target_points[1]
    local duration = ability:GetSpecialValueFor("duration")
    local ward = CreateUnitByName('dotacraft_healing_ward', point, false, caster, caster, caster:GetTeamNumber())
    ward:AddNewModifier(caster, ability, "modifier_healing_ward", {})
    ward:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
    ward:AddNewModifier(caster, nil, "modifier_summoned", {})
    ward:EmitSound("DOTA_Item.ObserverWard.Activate")
end

modifier_healing_ward = class({})
LinkLuaModifier("modifier_healing_ward_buff", "items/wards", LUA_MODIFIER_MOTION_NONE)

function modifier_healing_ward:OnCreated()
    if IsServer() then
        local radius = self:GetAbility():GetSpecialValueFor("radius")
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_healing_ward.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
        ParticleManager:SetParticleControlEnt(particle, 2, self:GetParent(), PATTACH_POINT_FOLLOW, "flame_attachment", self:GetParent():GetAbsOrigin(), true)
        self:AddParticle(particle, false, false, 1, false, false)
    end
end

function modifier_healing_ward:IsAura()
    return true
end

function modifier_healing_ward:IsHidden()
    return true
end

function modifier_healing_ward:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_healing_ward:GetModifierAura()
    return "modifier_healing_ward_buff"
end
   
function modifier_healing_ward:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_healing_ward:GetAuraEntityReject(target)
    return IsCustomBuilding(target) or target:IsMechanical()
end

function modifier_healing_ward:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_healing_ward:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_healing_ward_buff = class({})

function modifier_healing_ward_buff:DeclareFunctions()
    return { MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE }
end

function modifier_healing_ward_buff:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("regeneration")
end

function modifier_healing_ward_buff:GetEffectName()
    return "particles/units/heroes/hero_juggernaut/juggernaut_ward_heal.vpcf"
end

function modifier_healing_ward_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end