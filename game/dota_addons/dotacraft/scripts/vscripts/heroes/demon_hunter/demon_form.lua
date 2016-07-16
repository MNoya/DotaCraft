modifier_demon_form = class({})

function modifier_demon_form:DeclareFunctions()
    return { MODIFIER_PROPERTY_MODEL_CHANGE, 
             MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
             MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
             MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, }
end

function modifier_demon_form:OnCreated()
    if IsServer() then
        local target = self:GetParent()
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        self:AddParticle(particle, false, false, 1, false, false)
        target.old_attack_projectile = GetRangedProjectileName(target) -- In case the hero has an orb
        SetRangedProjectileName(target, "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf")
        target:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
        target:SetAttackType("chaos")
    end
end

function modifier_demon_form:OnDestroy()
    if IsServer() then
        SetRangedProjectileName(target, target.old_attack_projectile)
        target:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
        target:SetAttackType("hero")
        target.old_attack_projectile = nil
    end
end

function modifier_demon_form:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf"
end

function modifier_demon_form:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_demon_form:GetModifierModelChange()
    return "models/heroes/terrorblade/demon.vmdl"
end

function modifier_demon_form:IsHidden()
    return false
end

function modifier_demon_form:IsPurgable()
    return false
end

function modifier_demon_form:GetTexture()
    return "demon_hunter_demon_form"
end

function modifier_demon_form:AllowIllusionDuplicate()
    return true
end

function modifier_demon_form:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_range")
end

function modifier_demon_form:GetModifierExtraHealthBonus()
    return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_demon_form:GetModifierConstantHealthRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end