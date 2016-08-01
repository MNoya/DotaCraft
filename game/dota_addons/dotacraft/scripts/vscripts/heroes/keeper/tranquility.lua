keeper_tranquility = class({})

LinkLuaModifier("modifier_tranquility_aura", "heroes/keeper/tranquility", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tranquility_aura_effect", "heroes/keeper/tranquility", LUA_MODIFIER_MOTION_NONE)

function keeper_tranquility:OnSpellStart()
    local duration = self:GetSpecialValueFor("duration")
    local caster = self:GetCaster()
    caster:AddNewModifier(caster,self,"modifier_tranquility_aura",{duration=duration})
    caster:EmitSound("leshrac_lesh_respawn_09")
    Timers:CreateTimer(1, function()
        if self:IsChanneling() then
            StartAnimation(caster, {duration=2, activity=ACT_DOTA_CAST_ABILITY_2, rate=0.8, translate="torment"})
            return 2
        end
    end)
end

function keeper_tranquility:OnChannelFinish(bInterrupted)
    local caster = self:GetCaster()
    caster:RemoveModifierByName("modifier_tranquility_aura")
    EndAnimation(caster)
end

function keeper_tranquility:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_2
end

--------------------------------------------------------------------------------

modifier_tranquility_aura = class({})

function modifier_tranquility_aura:OnCreated()
    if IsServer() then
        local caster = self:GetCaster()
        local particle = ParticleManager:CreateParticle("particles/custom/nightelf/tranquility.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControl(particle,1,Vector(self:GetAbility():GetSpecialValueFor("radius"), 0, 0))
        ParticleManager:SetParticleControlEnt(particle, 2, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
        self:AddParticle(particle, false, false, 1, false, false)
    end
end

function modifier_tranquility_aura:IsAura() return true end
function modifier_tranquility_aura:IsHidden() return false end
function modifier_tranquility_aura:IsPurgable() return false end

function modifier_tranquility_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_tranquility_aura:GetModifierAura()
    return "modifier_tranquility_aura_effect"
end

function modifier_tranquility_aura:GetEffectName()
    return "particles/items2_fx/tranquil_boots_healing.vpcf"
end

function modifier_tranquility_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
   
function modifier_tranquility_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_tranquility_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target)
end

function modifier_tranquility_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_tranquility_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_tranquility_aura_effect = class({})

function modifier_tranquility_aura_effect:OnCreated()
    if IsServer() then
        self:StartIntervalThink(1)
    end
end

function modifier_tranquility_aura_effect:OnIntervalThink()
    local target = self:GetParent()
    ParticleManager:CreateParticle("particles/neutral_fx/troll_heal.vpcf",PATTACH_ABSORIGIN_FOLLOW,target)
end

function modifier_tranquility_aura_effect:DeclareFunctions()
    return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT }
end

function modifier_tranquility_aura_effect:GetModifierConstantHealthRegen()
    return self:GetAbility():GetSpecialValueFor("heal_per_second")
end

function modifier_tranquility_aura_effect:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_tranquility_aura_effect:IsPurgable() return false end