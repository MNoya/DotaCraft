function EtherStart( event )
    local caster = event.caster
    local ability = event.ability
    caster:EmitSound('Hero_Pugna.Decrepify')
    ability:ApplyDataDrivenModifier(caster, caster, 'modifier_ethereal', {})
    local cooldown = ability:GetCooldown(0)
    ability:StartCooldown(cooldown)
    local another = caster:FindAbilityByName('orc_corporeal_form')
    another:StartCooldown(cooldown)
    ability:SetHidden(true)
    another:SetHidden(false)
end

function EtherEnd( event )
    local caster = event.caster
    local ability = event.ability
    caster:RemoveModifierByNameAndCaster('modifier_ethereal', caster)
    local another = caster:FindAbilityByName('orc_ethereal_form')
    ability:SetHidden(true)
    another:SetHidden(false)
end

function Disenchant( event )
    local caster = event.caster
    local ability = event.ability
    local point = event.target_points[1]
    local radius = ability:GetSpecialValueFor("radius")
        
    -- Find targets in radius
    local units = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES+DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for k,unit in pairs(units) do
        if not IsCustomBuilding(unit) then
            if unit:IsSummoned() then
                local damage_to_summons = event.ability:GetSpecialValueFor("damage_to_summons")
                ApplyDamage({victim = unit, attacker = caster, damage = damage_to_summons, damage_type = DAMAGE_TYPE_PURE})
                ParticleManager:CreateParticle("particles/econ/items/enchantress/enchantress_lodestar/ench_death_lodestar_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
            end

            ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_false_promise_dmg_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)

            -- This ability removes both positive and negative buffs from units.
            local bRemovePositiveBuffs = true
            local bRemoveDebuffs = true
            unit:Purge(bRemovePositiveBuffs, bRemoveDebuffs, false, false, false)
        end
    end

    Blight:Dispel(point)
end

function SpiritLinkStart( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local radius = ability:GetSpecialValueFor('radius')

    local units = 0
    local max = ability:GetSpecialValueFor('max_unit')
    local allies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES, FIND_CLOSEST, false)
    if caster.linked == nil then
        caster.linked = {}
    end
    ability:ApplyDataDrivenModifier(caster, target, 'modifier_spirit_link', {})
    local anyunit = false
    local linked = {}
    while units < max do
        for k,ally in pairs(allies) do
            if units < max and (not ally:FindModifierByName('modifier_spirit_link') or anyunit or ally ~= caster) then
                ParticleManager:CreateParticle("particles/custom/orc/spirit_link_cast.vpcf", PATTACH_ABSORIGIN, ally)
                ability:ApplyDataDrivenModifier(caster, ally, 'modifier_spirit_link', {})
                units = units + 1
                table.insert(linked, ally)
            end
        end
        anyunit = true
    end

    for _,unit in pairs(linked) do
        for _,otherUnit in pairs(linked) do
            if otherUnit ~= unit then
                local particle = ParticleManager:CreateParticle("particles/custom/dazzle_shadow_wave_b.vpcf", PATTACH_CUSTOMORIGIN, nil)
                ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
                ParticleManager:SetParticleControl(particle, 1, otherUnit:GetAbsOrigin())
            end
        end
    end
end

function RemoveLinkedUnit( event )
    local unit = event.target
    if IsValidEntity(unit) then
        -- print('=======================')
        local i = getIndex(event.caster.linked, unit:GetEntityIndex())
        if i ~= -1 then
            table.remove(event.caster.linked, i)
            -- print('Unit removed from table')
        else
            -- print("Invalid index")
        end
        -- print('=======================')
    end
end

function AddLinkedUnit( event )
    local unit = event.target
    table.insert(event.caster.linked, unit:GetEntityIndex())
end

function LinkDamage( event )
    local attacker = event.attacker
    local target = event.unit
    local damage = event.Damage
    local ability = event.ability
    local factor = ability:GetSpecialValueFor('distribution_factor') 

    if IsValidAlive(target) then
        target:Heal(damage * factor, attacker)
    end

    local j = TableFindKey(event.caster.linked, target:GetEntityIndex())
    local k = TableCount(event.caster.linked)

    -- DeepPrintTable(event.caster.linked)
    if not j then j = -1 end
    -- print('=======================')
    -- print('Damage on main target: ' .. damage * factor)
    -- print('Index of main target: ' .. j)
    -- print('Table general count: ' .. k)
    -- print('=======================')
    if k-1 > 0 then
        local dist_damage = (damage * factor) / (k-1)
        for i=1,k do
            if i ~= j then
                if event.caster.linked[i] then
                    local linked = EntIndexToHScript(event.caster.linked[i])
                    if IsValidAlive(linked) then
                        local new_health = linked:GetHealth() - dist_damage
                        if new_health < 1 then
                            new_health = 1
                            linked:RemoveModifierByName('modifier_spirit_link')
                        end
                        linked:SetHealth(new_health)
                        -- print('=======================')
                        -- print('Damage on linked unit: ' .. dist_damage)
                        -- print('Index of linked unit: ' .. i)
                        -- print('=======================')
                    end
                end
            end
        end
    end
end

-- Denies casting if no tauren corpses near or not enough food to support revival, with a message
function AncestralSpiritPrecast( event )
    local ability = event.ability
    local caster = event.caster
    local radius = ability:GetCastRange()
    local playerID = caster:GetPlayerOwnerID()

    if not Players:HasEnoughFood(playerID, GetUnitKV("orc_tauren", "FoodCost")) then
        caster:Interrupt()
        SendErrorMessage(playerID, "#error_not_enough_food")
        return
    end

    local corpses = Corpses:FindAlliedInRadius(playerID, caster:GetAbsOrigin(), radius)
    for _,corpse in pairs(corpses) do
        if corpse.unit_name == 'orc_tauren' then
            ability.target = corpse
            return
        end
    end

    caster:Interrupt()
    SendErrorMessage(playerID, "#error_no_usable_corpses")
end

-- Resurrects units near the caster, using the corpse mechanic.
function AncestralSpirit( event )
    local caster = event.caster
    local ability = event.ability
    local health_factor = ability:GetSpecialValueFor('life_restored') * 0.01
    local mana_factor = ability:GetSpecialValueFor('mana_restored') * 0.01
    local playerID = caster:GetPlayerOwnerID()
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    local corpse = ability.target -- Corpse assigned in precast
    if not corpse then print("Seomtghinasdf asdfasd") return end
    ability.target = nil
    local origin = corpse:GetAbsOrigin()
    local tauren = CreateUnitByName("orc_tauren", origin, true, hero, hero, caster:GetTeamNumber())
    tauren:AddNewModifier(caster, nil, "modifier_phased", { duration = 0.03 })
    tauren:SetControllableByPlayer(playerID, true)
    tauren:SetOwner(hero)
    tauren:SetHealth(tauren:GetMaxHealth() * health_factor)
    tauren:SetMana(tauren:GetMaxMana() * mana_factor)
    Players:ModifyFoodUsed(playerID, GetFoodCost(tauren))
    Players:AddUnit(playerID, tauren)
    CheckAbilityRequirements(tauren, playerID)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_skeletonking/wraith_king_reincarnate_explode.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, origin)

    caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)

    corpse:RemoveCorpse()
end