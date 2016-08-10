function OrbManualCast(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability

    if not IsCustomBuilding(target) and target:IsMagicImmune() then
        local playerID = caster:GetPlayerOwnerID()
        SendErrorMessage(playerID, "error_magic_immune_unit")
        ability:RefundManaCost()
        caster:Interrupt()
        return
    end

    ability.orbAttack = true
    caster:SetRangedProjectileName("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb.vpcf")
    caster:PerformAttack(target,true,true,false,false,true)
    caster:EmitSound("Hero_ObsidianDestroyer.ArcaneOrb")
    caster:StartGesture(ACT_DOTA_ATTACK)
end

function OrbStart(event)
    local caster = event.caster
    local ability = event.ability
    ability.orbAttack = false

    if ability:GetAutoCastState() then
        local manaCost = ability:GetManaCost(1)
        if caster:GetMana() >= manaCost then
            ability.orbAttack = true
            caster:SetRangedProjectileName("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb.vpcf")
            caster:SpendMana(manaCost,ability)
            caster:EmitSound("Hero_ObsidianDestroyer.ArcaneOrb")
        end
    end
    
    if not ability.orbAttack then
        caster:SetRangedProjectileName("particles/units/heroes/hero_bane/bane_projectile.vpcf")
    end
end

function OrbDamage(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local damage = ability:GetSpecialValueFor("damage_bonus")
    local radius = ability:GetSpecialValueFor("radius")
    local enemies = FindEnemiesInRadius(caster, radius, target:GetAbsOrigin())
    
    if ability.orbAttack then
        target:EmitSound("Hero_ObsidianDestroyer.ArcaneOrb.Impact")
        for _,enemy in pairs(enemies) do
            if IsCustomBuilding(enemy) then
                DamageBuilding(enemy, damage, ability, caster)
            else
                ApplyDamage({victim = enemy, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
            end
        end
    end
end

----------------------------------------------------------------

function AbsorbMana(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability

    -- store target mana and set target to 0
    local target_mana = target:GetMana()        
    local mana_to_steal = caster:GetMaxMana() - caster:GetMana()
    
    -- add mana to caster
    target:SetMana(0)
    caster:SetMana(caster:GetMana() + target_mana)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_visage/visage_grave_chill_cast_beams.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

    PopupMana(caster, mana_to_steal)
end

----------------------------------------------------------------

-- Consumes all positive and negative buffs from all units in an area. 
-- Only negative dispels restore hp/mana (own-team buffs should not)
function DevourMagic(keys)
    local ability = keys.ability
    local caster = keys.caster
    local teamNumber = caster:GetTeamNumber()
    
    local radius = ability:GetSpecialValueFor("radius")
    local mana_restore = ability:GetSpecialValueFor("mana_restore")
    local health_restore = ability:GetSpecialValueFor("health_restore")
    local summon_damage = ability:GetSpecialValueFor("summoned_unit_damage")
    
    local targets = {}
    local count = 0
    local point = keys.target_points[1]

    caster:EmitSound("Hero_Antimage.ManaVoidCast")
    
    -- find all units within 300 radius that are enemey
    local units = FindUnitsInRadius(teamNumber, point, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
    
    -- add unit to table if meets requirements
    for k,unit in pairs(units) do
        if not IsCustomBuilding(unit) then
            count = count + 1
            targets[count] = unit
        end
    end

    if count == 0 then return end
    
    local removed_buffs = 0
    local removed_debuffs = 0
    for k,unit in pairs(targets) do
        local modifiers = unit:FindAllModifiers()
        local removed_something = false
        for k,modifier in pairs(modifiers) do -- for all modifiers found

            if modifier:IsPurgableModifier() then
                removed_something = true
                local bDebuff = modifier:IsDebuff()
                if unit:IsOpposingTeam(teamNumber) then
                    removed_debuffs = removed_debuffs + 1
                elseif bDebuff then
                    removed_debuffs = removed_debuffs + 1
                end

                unit:RemoveModifierByName(modifier:GetName())
            end
        end
        if removed_something then
            ParticleManager:CreateParticle("particles/econ/items/antimage/antimage_weapon_basher_ti5/antimage_manavoid_lightning_ti_5.vpcf",PATTACH_ABSORIGIN_FOLLOW,unit)
        end

        -- if unit is summoned
        if unit:IsSummoned() then
            ParticleManager:CreateParticle("particles/generic_gameplay/generic_purge.vpcf",PATTACH_ABSORIGIN_FOLLOW,caster)
            ApplyDamage({victim = unit, attacker = caster, damage = summon_damage, damage_type = DAMAGE_TYPE_PURE})
        end   
    end

    -- if debuffs were removed, give mana and health
    if removed_debuffs > 0 then
        caster:SetMana(caster:GetMana() + mana_restore * removed_debuffs)
        caster:SetHealth(caster:GetHealth() + health_restore * removed_debuffs)

        ParticleManager:CreateParticle("particles/econ/items/antimage/antimage_weapon_basher_ti5/antimage_manavoid_ti_5.vpcf",PATTACH_ABSORIGIN_FOLLOW,caster)
    end
end