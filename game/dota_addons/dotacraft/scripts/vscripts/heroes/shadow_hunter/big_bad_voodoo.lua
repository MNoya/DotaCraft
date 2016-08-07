shadow_hunter_big_bad_voodoo = class({})

LinkLuaModifier("modifier_big_bad_voodoo", "heroes/shadow_hunter/big_bad_voodoo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_big_bad_voodoo_invulnerability", "heroes/shadow_hunter/big_bad_voodoo", LUA_MODIFIER_MOTION_NONE)

function shadow_hunter_big_bad_voodoo:OnSpellStart()
    local duration = self:GetSpecialValueFor("duration")
    local caster = self:GetCaster()
    caster:AddNewModifier(caster,self,"modifier_big_bad_voodoo",{duration=duration})
    caster:EmitSound("shadowshaman_shad_ability_shackle_08")
    Timers:CreateTimer(1, function()
        if self:IsChanneling() then
            caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)
            return 1
        end
    end)
end

function shadow_hunter_big_bad_voodoo:OnChannelFinish(bInterrupted)
    local caster = self:GetCaster()
    caster:RemoveModifierByName("modifier_big_bad_voodoo")
    caster:StopSound("Hero_WitchDoctor.Maledict_Loop")
    caster:RemoveGesture(ACT_DOTA_CAST_ABILITY_4)
end

function shadow_hunter_big_bad_voodoo:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_4
end

--------------------------------------------------------------------------------

modifier_big_bad_voodoo = class({})

function modifier_big_bad_voodoo:OnCreated()
    local target = self:GetParent()
    local particle = ParticleManager:CreateParticle("particles/custom/witchdoctor_voodoo_restoration_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    self:AddParticle(particle, false, false, 1, false, false)
 
    local particle = ParticleManager:CreateParticle("particles/custom/warlock_shadow_word_buff_copy.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    self:AddParticle(particle, false, false, 1, false, false)

    local particle = ParticleManager:CreateParticle("particles/custom/witchdoctor_voodoo_restoration.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(particle,1,Vector(self:GetAbility():GetSpecialValueFor("radius"), 0, 0))
    self:AddParticle(particle, false, false, 1, false, false)
end

function modifier_big_bad_voodoo:IsAura() return true end
function modifier_big_bad_voodoo:IsHidden() return true end
function modifier_big_bad_voodoo:IsPurgable() return false end

function modifier_big_bad_voodoo:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_big_bad_voodoo:GetModifierAura()
    return "modifier_big_bad_voodoo_invulnerability"
end

function modifier_big_bad_voodoo:GetEffectName()
    return "particles/units/heroes/hero_warlock/warlock_shadow_word_debuff.vpcf"
end

function modifier_big_bad_voodoo:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
   
function modifier_big_bad_voodoo:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_big_bad_voodoo:GetAuraEntityReject(target)
    return IsCustomBuilding(target) or target == self:GetCaster() or target:IsWard()
end

function modifier_big_bad_voodoo:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_big_bad_voodoo:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_big_bad_voodoo_invulnerability = class({})

function modifier_big_bad_voodoo_invulnerability:CheckState()
    return { [MODIFIER_STATE_INVULNERABLE] = true }
end

function modifier_big_bad_voodoo_invulnerability:GetEffectName()
    return "particles/custom/warlock_shadow_word_buff_c.vpcf"    
end

function modifier_big_bad_voodoo_invulnerability:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_big_bad_voodoo_invulnerability:IsPurgable() return false end