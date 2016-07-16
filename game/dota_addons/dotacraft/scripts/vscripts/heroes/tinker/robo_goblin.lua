modifier_robot_form = class({})

function modifier_robot_form:DeclareFunctions()
    return { MODIFIER_PROPERTY_MODEL_CHANGE,
             MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
             MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
             MODIFIER_EVENT_ON_ATTACK_LANDED, }
end

function modifier_robot_form:OnCreated()
    if IsServer() then
        local caster = self:GetParent()

        caster:EmitSound("tinker_tink_spawn_03")
        caster:SetModelScale(2)
        function caster:IsMechanical() return true end -- Set mechanical flag

        -- Swap sub_ability
        caster:SwapAbilities("tinker_robo_goblin", "tinker_normal_form", false, true)

        -- Learn upgrades
        local upgrade_ability = caster:FindAbilityByName("tinker_engineering_upgrade")
        if upgrade_ability and upgrade_ability:GetLevel() > 0 then
            upgrade_ability:ApplyDataDrivenModifier(caster, caster, "modifier_robo_goblin_upgrade", {})
        end
    end
end

-- Reverts back to the original model and attack type, swaps abilities, removes modifier
function modifier_robot_form:OnDestroy()
    if IsServer() then
        local caster = self:GetParent()

        caster:SetModelScale(1)
        function caster:IsMechanical() return false end -- Remove mechanical flag

        -- Swap the sub_ability back to normal
        caster:SwapAbilities("tinker_robo_goblin", "tinker_normal_form", true, false)

        -- Remove upgrade modifier
        caster:RemoveModifierByName("modifier_robo_goblin_upgrade")
    end
end

-- Extra damage against buildings
function modifier_robot_form:OnAttackLanded(event)
    local attacker = event.attacker
    if attacker == self:GetParent() then
        local target = event.target
        if IsCustomBuilding(target) then
            local ability = self:GetAbility()
            local extra_dmg_to_buildings = ability:GetSpecialValueFor("extra_dmg_to_buildings")
            local damage = event.damage * (extra_dmg_to_buildings - 1)
            ApplyDamage({ victim = target, attacker = attacker, damage = damage, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL })
        end
    end
end

function modifier_robot_form:GetModifierModelChange()
    return "models/courier/mechjaw/mechjaw.vmdl"
end

function modifier_robot_form:IsHidden()
    return true
end

function modifier_robot_form:IsPurgable()
    return false
end

function modifier_robot_form:AllowIllusionDuplicate()
    return true
end

function modifier_robot_form:GetModifierBonusStats_Strength()
    return self:GetAbility():GetSpecialValueFor("extra_str")
end

function modifier_robot_form:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("extra_armor")
end