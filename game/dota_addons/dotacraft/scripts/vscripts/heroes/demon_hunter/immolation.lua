demon_hunter_immolation = class({})

LinkLuaModifier("modifier_immolation_aura", "heroes/demon_hunter/immolation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_immolation_aura_debuff", "heroes/demon_hunter/immolation", LUA_MODIFIER_MOTION_NONE)

function demon_hunter_immolation:OnToggle()
    if IsServer() then
        if self:GetToggleState() == true then
            self:OnToggleOn()
        else
            self:OnToggleOff()
        end
    end
end

function demon_hunter_immolation:OnToggleOn()
    local caster = self:GetCaster()

    -- Override cloak of flames
    local cloak_of_flames = caster:FindItemByName("item_cloak_of_flames")
    if cloak_of_flames then
        caster:RemoveModifierByName("modifier_immolation_aura")
    end

    caster:AddNewModifier(caster,self,"modifier_immolation_aura",{})
    caster:EmitSound("Hero_EmberSpirit.FlameGuard.Cast")

    self.think = Timers:CreateTimer(1, function()
        if self:GetToggleState() then
            self:OnIntervalThink()
            return 1
        end
    end)
end

function demon_hunter_immolation:OnToggleOff()
    Timers:RemoveTimer(self.think)
    local caster = self:GetCaster()
    caster:RemoveModifierByName("modifier_immolation_aura")

    -- Reapply cloak of flames
    local cloak_of_flames = caster:FindItemByName("item_cloak_of_flames")
    if cloak_of_flames then
        caster:TakeItem(cloak_of_flames)
        caster:AddItem(cloak_of_flames)
    end
end

function demon_hunter_immolation:OnIntervalThink()
    local caster = self:GetCaster()
    local manacost_per_second = self:GetSpecialValueFor("mana_cost_per_second")

    -- Check if the spell mana cost can be maintained
    if caster:GetMana() >= manacost_per_second then
        caster:SpendMana(manacost_per_second, self)
    else
        if self:GetToggleState() then
            self:ToggleAbility()
        end
    end
end

--------------------------------------------------------------------------------

neutral_immolation = class({})

neutral_immolation.OnToggle = demon_hunter_immolation.OnToggle
neutral_immolation.OnToggleOn = demon_hunter_immolation.OnToggleOn
neutral_immolation.OnToggleOff = demon_hunter_immolation.OnToggleOff
neutral_immolation.OnIntervalThink = demon_hunter_immolation.OnIntervalThink

--------------------------------------------------------------------------------

modifier_immolation_aura = class({})

function modifier_immolation_aura:OnCreated()
    if IsServer() then
        local particle = ParticleManager:CreateParticle("particles/custom/nightelf/demon_hunter/flameguard.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControlEnt(particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(particle, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true)
        self:AddParticle(particle, false, false, 1, false, false)
        self:StartIntervalThink(1)
    end
end

function modifier_immolation_aura:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local damage_per_second = ability:GetSpecialValueFor("damage_per_second")
    local radius = ability:GetSpecialValueFor("radius")
    local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)

    for _,unit in pairs(targets) do
        local immolation_modifier = unit:FindModifierByName("modifier_immolation_aura_debuff") --Make sure only one instance is applied
        if immolation_modifier and immolation_modifier:GetAbility() == ability then
            ApplyDamage({ victim = unit, attacker = caster, damage = damage_per_second, damage_type = DAMAGE_TYPE_MAGICAL })
        end
    end
end

function modifier_immolation_aura:IsAura()
    return true
end

function modifier_immolation_aura:IsHidden()
    return false
end

function modifier_immolation_aura:IsPurgable()
    return false
end

function modifier_immolation_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_immolation_aura:GetModifierAura()
    return "modifier_immolation_aura_debuff"
end
   
function modifier_immolation_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_immolation_aura:GetAuraEntityReject(target)
    return IsCustomBuilding(target) or target:HasFlyMovementCapability() or target:IsMechanical()
end

function modifier_immolation_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_immolation_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_immolation_aura_debuff = class({})

function modifier_immolation_aura_debuff:OnCreated()
    local unit = self:GetParent()
    local particle = ParticleManager:CreateParticle("particles/custom/nightelf/demon_hunter/immolation_damage.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
    self:AddParticle(particle, false, false, 1, false, false)
end

function modifier_immolation_aura_debuff:IsHidden()
    return true
end

function modifier_immolation_aura_debuff:IsPurgable()
    return false
end