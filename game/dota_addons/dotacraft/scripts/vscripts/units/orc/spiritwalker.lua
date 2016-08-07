function EtherealStart(event)
    local caster = event.caster
    local ability = event.ability
    ability:EndCooldown()
    StartAnimation(caster, {duration=0.7, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.5})
    caster:EmitSound("Hero_Pugna.Decrepify")
    ability:ApplyDataDrivenModifier(caster,caster,"modifier_ethereal_form_transform",{})
    ability:ToggleOn()
end

function EtherealForm(event)
    local caster = event.caster
    local ability = event.ability
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_ethereal", {})
    
    local orc_corporeal_form = caster:FindAbilityByName("orc_corporeal_form")
    orc_corporeal_form:StartCooldown(orc_corporeal_form:GetCooldown(1))
    caster:SwapAbilities("orc_corporeal_form","orc_ethereal_form",true,false)
    orc_corporeal_form:ToggleOff()
end

function CorporealStart(event)
    local caster = event.caster
    local ability = event.ability
    StartAnimation(caster, {duration=0.7, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.5})
    ability:ApplyDataDrivenModifier(caster,caster,"modifier_corporeal_form_transform",{})
    caster:EmitSound("Hero_Spirit_Breaker.NetherStrike.Begin")
    ability:EndCooldown()
    ability:ToggleOn()
end

function CorporealForm(event)
    local caster = event.caster
    local ability = event.ability
    caster:RemoveModifierByNameAndCaster("modifier_ethereal", caster)
    caster:SwapAbilities("orc_corporeal_form","orc_ethereal_form",false,true)
    local orc_ethereal_form = caster:FindAbilityByName("orc_ethereal_form")
    orc_ethereal_form:ToggleOff()
end

----------------------------------------------------------------------

function Disenchant(event)
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

----------------------------------------------------------------------
-- Damage is distributed across all linked units on the team
if not _G.SpiritLinkTable then
    _G.SpiritLinkTable = {}
end

function SpiritLinkStart(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local radius = ability:GetSpecialValueFor('radius')
    local teamID = caster:GetTeamNumber()
    SpiritLinkTable[teamID] = SpiritLinkTable[teamID] or {}

    local allies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES, FIND_CLOSEST, false)
    local max = ability:GetSpecialValueFor('max_unit')
    
    -- The main target is always linked
    ability:ApplyDataDrivenModifier(caster, target, 'modifier_spirit_link', {})
    local units = 1
    local linked = {} -- Chosen units
    table.insert(linked, target)

    -- First prioritize those that don't have the modifier
    for _,ally in pairs(allies) do
        if units < max then
            if not ally:HasModifier('modifier_spirit_link') then
                ParticleManager:CreateParticle("particles/custom/orc/spirit_link_cast.vpcf", PATTACH_ABSORIGIN, ally)
                ability:ApplyDataDrivenModifier(caster, ally, 'modifier_spirit_link', {})
                table.insert(linked, ally)
                units = units + 1
            end
        else
            break
        end
    end

    -- Then if we havent reached the max, refresh others
    if units < max then
        for _,ally in pairs(allies) do
            if units < max then
                if ally:HasModifier('modifier_spirit_link') and ally ~= target then
                    ParticleManager:CreateParticle("particles/custom/orc/spirit_link_cast.vpcf", PATTACH_ABSORIGIN, ally)
                    ability:ApplyDataDrivenModifier(caster, ally, 'modifier_spirit_link', {})
                    table.insert(linked, ally)
                    units = units + 1
                end
            else
                break
            end
        end
    end

    -- Make a chain between the linked units
    local origin = target
    for _,unit in pairs(linked) do
        local particle = ParticleManager:CreateParticle("particles/custom/dazzle_shadow_wave_b.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(particle, 0, origin:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle, 1, unit:GetAbsOrigin())
        origin = unit
    end
end


-- Modifier created
function AddLinkedUnit(event)
    local unit = event.target
    unit.entIndex = unit:GetEntityIndex()
    SpiritLinkTable[unit:GetTeamNumber()][unit.entIndex] = unit
end

-- Modifier destroyed
function RemoveLinkedUnit(event)
    local unit = event.target
    if IsValidEntity(unit) then
        SpiritLinkTable[unit:GetTeamNumber()][unit.entIndex] = nil        
    end
end

-- Damage taken, post mitigation
function LinkDamage(event)
    local attacker = event.attacker
    local caster = event.caster
    local target = event.unit
    local damage = event.Damage
    local ability = event.ability
    local factor = ability:GetSpecialValueFor('distribution_factor')

    local linked = SpiritLinkTable[target:GetTeamNumber()]
    if not linked then
        print("Error, no Spirit Link Table for team "..target:GetTeamNumber())
        return
    end

    local count = TableCount(linked)
    if count == 1 then return end -- Take full damage

    -- Revert the damage taken
    local distribute_damage = damage * factor
    local damage_prevented = damage - distribute_damage
    local currentHP = target:GetHealth()
    if currentHP > 0 then
        target:SetHealth(currentHP+damage_prevented)
    else -- Last hit wont distribute damage
        target:RemoveModifierByName("modifier_spirit_link")
        return
    end

    -- Split the damage between all other units including the damaged unit
    distribute_damage = distribute_damage / count
    for _,unit in pairs(linked) do
        if IsValidAlive(unit) then
            local new_health = unit:GetHealth() - distribute_damage
            if new_health <= 1 then
                new_health = 1
                unit:RemoveModifierByName("modifier_spirit_link")
            end
            unit:SetHealth(new_health)
        else
            linked[unit.entIndex] = nil
        end
    end
end

----------------------------------------------------------------------

-- Denies casting if no tauren corpses near or not enough food to support revival, with a message
function AncestralSpiritPrecast(event)
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
function AncestralSpirit(event)
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