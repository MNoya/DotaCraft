function EquipOrb( event )
    local caster = event.caster
    if caster:IsRealHero() then
        if not caster.original_attack then
            caster.original_attack = caster:GetAttacksEnabled()
        end
        caster:SetAttacksEnabled("ground, air")
        caster.hasOrb = (caster.hasOrb and caster.hasOrb + 1) or 1
    end
end

function UnequipOrb( event )
    local caster = event.caster
    if caster:IsRealHero() then
        caster.hasOrb = caster.hasOrb - 1
        if caster.hasOrb == 0 then
            if not caster:HasModifier("modifier_demon_form") then
                caster:SetAttacksEnabled(caster.original_attack)
            end
            caster.hasOrb = false
        end
    end
end

function Splash(event)
    local attacker = event.caster
    local target = event.target
    local ability = event.ability
    local radius = ability:GetSpecialValueFor("full_damage_radius")
    local full_damage = attacker:GetAttackDamage()
    
    local splash_targets = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
    for _,unit in pairs(splash_targets) do
        if unit ~= target and not unit:HasFlyMovementCapability() and not IsCustomBuilding(unit) and not unit:IsWard() then
            ApplyDamage({victim = unit, attacker = attacker, damage = full_damage, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL})
        end
    end
end

function Purge(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local duration = ability:GetSpecialValueFor('duration')
    local bSummoned = target:IsSummoned()

    target:QuickPurge(true, false)
    ParticleManager:CreateParticle('particles/generic_gameplay/generic_purge.vpcf', PATTACH_ABSORIGIN_FOLLOW, target)
    target:EmitSound("DOTA_Item.DiffusalBlade.Target")

    ability:ApplyDataDrivenModifier(caster, target, 'modifier_purge', {duration = duration}) 

    if bSummoned then
        ApplyDamage({victim = target, attacker = caster, damage = ability:GetSpecialValueFor('damage_to_summons'), damage_type = DAMAGE_TYPE_PURE, ability = ability})
    end
end

function OrbAirCheck( event )
    local attacker = event.attacker
    local target = event.target
    local target_type = GetMovementCapability(target)
    if not attacker.original_attack_type then
        attacker.original_attack_type = attacker:GetAttackCapability()
    end
    if target_type == "air" then
        attacker:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
    else
        attacker:SetAttackCapability(attacker.original_attack_type)
    end
end