-- Creates a dummy unit to apply the cloud aura
function CloudStart( event )
    local caster = event.caster
    local point = event.target_points[1]

    caster.cloud_dummy = CreateUnitByName("dummy_unit", point, false, caster, caster, caster:GetTeam())
    caster.cloud_dummy:AddNewModifier(caster, event.ability, "modifier_cloud_aura", {})

    caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)
end

function CloudEnd( event )
    local caster = event.caster
    local ability = event.ability
    if IsValidEntity(caster.cloud_dummy) then
        caster.cloud_dummy:ForceKill(true)
    end
end

------------------------------------------------

modifier_cloud_aura = class({})

LinkLuaModifier("modifier_cloud", "units/human/dragonhawk_rider", LUA_MODIFIER_MOTION_NONE)

function modifier_cloud_aura:OnCreated()
    if IsServer() then
        local radius = self:GetAbility():GetSpecialValueFor("radius")
        self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_smokebomb.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControl(self.particle,1,Vector(10,radius,radius))
        self:AddParticle(self.particle, false, false, 1, false, false)
        self:StartIntervalThink(1)
    end
end

function modifier_cloud_aura:OnIntervalThink()
    if self:GetAbility():IsChanneling() then
        self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_1)
    end
end

function modifier_cloud_aura:IsAura() return true end
function modifier_cloud_aura:IsHidden() return true end
function modifier_cloud_aura:IsPurgable() return false end

function modifier_cloud_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_cloud_aura:GetModifierAura()
    return "modifier_cloud"
end
   
function modifier_cloud_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_cloud_aura:GetAuraEntityReject(target)
    return not IsCustomBuilding(target) and not target:IsRangedAttacker()
end

function modifier_cloud_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_cloud_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_cloud_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_cloud = class({})

function modifier_cloud:CheckState()
    return { [MODIFIER_STATE_DISARMED] = true }
end

function modifier_cloud:IsPurgable() return false end
function modifier_cloud:IsDebuff() return true end

--------------------------------------------------------------------------------

function ChannelingAnimation(event)
    event.caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)
end

-- Loses flying capability
function LoseFlying( event )
    local target = event.target
    target:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
end

-- Gains flying capability
function ReGainFlying( event )
    local target = event.target
    target:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
end