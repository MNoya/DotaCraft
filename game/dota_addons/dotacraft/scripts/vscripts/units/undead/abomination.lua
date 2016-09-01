
undead_disease_cloud = class({})

LinkLuaModifier("modifier_disease_cloud_aura", "units/undead/abomination.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_disease_cloud_debuff", "units/undead/abomination.lua", LUA_MODIFIER_MOTION_NONE)

function undead_disease_cloud:GetIntrinsicModifierName()
    return "modifier_disease_cloud_aura"
end

--------------------------------------------------------------------------------

modifier_disease_cloud_aura = class({})

function modifier_disease_cloud_aura:OnCreated()
    if IsServer() then
        local particle = ParticleManager:CreateParticle("particles/custom/undead/disease_cloud.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControl(particle, 1, Vector(200,0,0))
        self:AddParticle(particle, false, false, 1, false, false)
    end
end

function modifier_disease_cloud_aura:OnDestroy()
    if IsServer() then
        local unit = self:GetParent()
        if unit:GetUnitName() == "undead_abomination" then
            local disease_cloud_dummy = CreateUnitByName("dummy_unit_disease_cloud", unit:GetAbsOrigin(), false, nil, nil, unit:GetTeamNumber())
            local explosion = ParticleManager:CreateParticle("particles/custom/undead/rot_recipient.vpcf",PATTACH_ABSORIGIN_FOLLOW,disease_cloud_dummy)
            Timers:CreateTimer(1, function() ParticleManager:DestroyParticle(explosion,true) end)
            Timers:CreateTimer(10, function()
                UTIL_Remove(disease_cloud_dummy)
            end)
        end
    end
end

function modifier_disease_cloud_aura:IsAura()
    return true
end

function modifier_disease_cloud_aura:IsHidden()
    return true
end

function modifier_disease_cloud_aura:IsPurgable()
    return false
end

function modifier_disease_cloud_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_disease_cloud_aura:GetModifierAura()
    return "modifier_disease_cloud_debuff"
end
   
function modifier_disease_cloud_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_disease_cloud_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target) or target:IsWard() or target:IsMechanical() or IsUndead(target)
end

function modifier_disease_cloud_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_disease_cloud_aura:GetAuraDuration()
    return 120
end

--------------------------------------------------------------------------------

modifier_disease_cloud_debuff = class({})

function modifier_disease_cloud_debuff:IsPurgable()
    return false
end

function modifier_disease_cloud_debuff:IsDebuff()
    return true
end

function modifier_disease_cloud_debuff:OnCreated()
    if IsServer() then
        self:StartIntervalThink(1)
    end
end

function modifier_disease_cloud_debuff:GetEffectName()
    return "particles/custom/undead/disease_debuff.vpcf"
end

function modifier_disease_cloud_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_disease_cloud_debuff:OnIntervalThink()
    ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), damage = 1, damage_type = DAMAGE_TYPE_MAGICAL})
end