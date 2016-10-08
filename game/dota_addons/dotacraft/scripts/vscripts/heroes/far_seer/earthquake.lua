-- Creates a dummy unit to apply the Earthquake aura
function EarthquakeStart( event )
    local ability = event.ability
    local caster = event.caster
    local point = event.target_points[1]

    caster.earthquake_dummy = CreateUnitByName("dummy_unit", point, false, caster, caster, caster:GetTeam())
    caster.earthquake_dummy:AddNewModifier(caster, ability, "modifier_earthquake_aura", {})

    caster:EmitSound("Hero_Leshrac.Split_Earth")
    Timers:CreateTimer(0.5, function()
        if IsValidAlive(caster) and ability:IsChanneling() then
            caster:StartGesture(ACT_DOTA_KINETIC_FIELD)
            return 1
        end
    end)
end

function EarthquakeEnd( event )
    local caster = event.caster
    if IsValidEntity(caster.earthquake_dummy) then
        caster:RemoveGesture(ACT_DOTA_KINETIC_FIELD)
        caster.earthquake_dummy:ForceKill(true)
    end
end

------------------------------------------------

modifier_earthquake_aura = class({})

LinkLuaModifier("modifier_earthquake", "heroes/far_seer/earthquake", LUA_MODIFIER_MOTION_NONE)

function modifier_earthquake_aura:OnCreated()
    if IsServer() then
        self:PlayParticleEffect()
        self:StartIntervalThink(1)
    end
end

function modifier_earthquake_aura:OnIntervalThink()
    if self:GetAbility():IsChanneling() then
        self:PlayParticleEffect() 
        self:GetParent():EmitSound("Hero_Leshrac.Split_Earth")   
    end
end

function modifier_earthquake_aura:PlayParticleEffect()
    local radius = self:GetAbility():GetSpecialValueFor("radius")
    self.particle = ParticleManager:CreateParticle("particles/custom/orc/earthquake.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.particle,1,Vector(radius,radius,radius))
end

function modifier_earthquake_aura:IsAura() return true end
function modifier_earthquake_aura:IsHidden() return true end
function modifier_earthquake_aura:IsPurgable() return false end

function modifier_earthquake_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_earthquake_aura:GetModifierAura()
    return "modifier_earthquake"
end
   
function modifier_earthquake_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_earthquake_aura:GetAuraEntityReject(target)
    return target:IsWard() or target:IsFlyingUnit()
end

function modifier_earthquake_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_earthquake_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_earthquake_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_earthquake = class({})

function modifier_earthquake:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_earthquake:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movement_speed_slow_pct")
end

function modifier_earthquake:OnCreated()
    if IsServer() then
        self:DamageBuilding()
        self:StartIntervalThink(1)
    end
end

function modifier_earthquake:OnIntervalThink()
    self:DoDamage()
end

function modifier_earthquake:DamageBuilding()
    if IsCustomBuilding(self:GetParent()) then
        DamageBuilding(self:GetParent(), self:GetAbility():GetSpecialValueFor("building_damage_per_sec"), self:GetAbility(), self:GetCaster())
    end
end

function modifier_earthquake:IsPurgable() return false end
function modifier_earthquake:IsDebuff() return true end

--------------------------------------------------------------------------------