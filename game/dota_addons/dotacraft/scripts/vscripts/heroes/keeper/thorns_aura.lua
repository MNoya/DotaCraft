keeper_thorns_aura = class({})

LinkLuaModifier("modifier_thorns_aura", "heroes/keeper/thorns_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_thorns_aura_buff", "heroes/keeper/thorns_aura", LUA_MODIFIER_MOTION_NONE)

function keeper_thorns_aura:GetIntrinsicModifierName()
    return "modifier_thorns_aura"
end

--------------------------------------------------------------------------------

modifier_thorns_aura = class({})

function modifier_thorns_aura:IsAura()
    return true
end

function modifier_thorns_aura:IsHidden()
    return true
end

function modifier_thorns_aura:IsPurgable()
    return false
end

function modifier_thorns_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_thorns_aura:GetModifierAura()
    return "modifier_thorns_aura_buff"
end

function modifier_thorns_aura:GetEffectName()
    return "particles/custom/aura_thorns.vpcf"
end

function modifier_thorns_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
   
function modifier_thorns_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_thorns_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target)
end

function modifier_thorns_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_thorns_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_thorns_aura_buff = class({})

function modifier_thorns_aura_buff:DeclareFunctions()
    return { MODIFIER_EVENT_ON_ATTACKED }
end

function modifier_thorns_aura_buff:OnAttacked(event)
    local target = event.target --the damaged unit
    if target == self:GetParent() then
        local attacker = event.attacker
        -- Apply the damage only to ranged attacker
        if not IsCustomBuilding(attacker) and not attacker:IsRangedAttacker() and self:GetParent():IsOpposingTeam(target:GetTeamNumber()) then
            local ability = self:GetAbility()
            local return_damage = ability:GetSpecialValueFor("melee_damage_return") * event.damage * 0.01
            local abilityDamageType = ability:GetAbilityDamageType()

            ApplyDamage({ victim = attacker, attacker = target, damage = return_damage, ability = ability, damage_type = abilityDamageType })

            local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_return.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
            ParticleManager:SetParticleControlEnt(particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(particle, 1, attacker, PATTACH_POINT_FOLLOW, "attach_hitloc", attacker:GetAbsOrigin(), true)
        end
    end
end

function modifier_thorns_aura_buff:IsPurgable()
    return false
end