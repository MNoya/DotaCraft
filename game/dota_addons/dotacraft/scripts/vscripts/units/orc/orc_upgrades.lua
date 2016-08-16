function ApplyModifierUpgrade(event)
    local caster = event.caster
    local ability = event.ability
    local unit_name = caster:GetUnitName()
    local ability_name = ability:GetAbilityName()

    -- Unholy Strength
    if string.find(ability_name,"melee_weapons") then
        if unit_name == "orc_tauren" then
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_tauren_damage", {})
        elseif unit_name == "orc_raider" then
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_raider_damage", {})
        else
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_grunt_damage", {})
        end

    -- Creature Attack
    elseif string.find(ability_name,"ranged_weapons") then
        if unit_name == "orc_demolisher" then
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_demolisher_damage", {})
        elseif unit_name == "orc_troll_batrider" then
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_batrider_damage", {})
        else
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_bonus_damage", {})
        end
    end
end


-- Swaps the Kodo's War Drums ability to the upgraded version
function ApplyWarDrumsUpgrade(event)
    local caster = event.caster
    local target = event.target
    local playerID = caster:GetPlayerOwnerID()
    local upgrades = Players:GetUpgradeTable( playerID )
    
    if upgrades["orc_research_improved_war_drums"] then
        target:RemoveModifierByName("modifier_war_drums_aura")
        -- Find all units nearby and remove the buff to re-apply
        local allies_nearby = FindAlliesInRadius(target, 900)
        for _,ally in pairs(allies_nearby) do
            if ally:HasModifier("modifier_war_drums") then
                ally:RemoveModifierByName("modifier_war_drums")
            end
        end

        local war_drums = target:AddAbility("orc_improved_war_drums")
        target:SwapAbilities("orc_improved_war_drums", "orc_war_drums", true, false)
        target:RemoveAbility("orc_war_drums")
        war_drums:SetLevel(1)
    end
end

-- Upgrade all Kodo Beasts
function UpgradeWarDrums(event)
    local caster = event.caster
    local playerID = caster:GetPlayerOwnerID()
    local playerUnits = Players:GetUnits(playerID)

    for _,unit in pairs(playerUnits) do
        if IsValidEntity(unit) and unit:HasAbility("orc_war_drums") then
            unit:RemoveModifierByName("modifier_war_drums_aura")
            -- Find all units nearby and remove the buff to re-apply
            local allies_nearby = FindAlliesInRadius(unit, 900)
            for _,ally in pairs(allies_nearby) do
                if ally:HasModifier("modifier_war_drums") then
                    ally:RemoveModifierByName("modifier_war_drums")
                end
            end

            local war_drums = unit:AddAbility("orc_improved_war_drums")
            unit:SwapAbilities("orc_improved_war_drums", "orc_war_drums", true, false)
            unit:RemoveAbility("orc_war_drums")
            war_drums:SetLevel(1)
        end
    end
end

function ReinforcedDefenses(event)
    local building = event.caster
    building:SetArmorType("fortified")
end

function SpikedBarricadeDamage(event)
    local caster = event.caster
    local attacker = event.attacker
    local ability = event.ability
    if attacker:IsOpposingTeam(caster:GetTeamNumber()) and not attacker:IsRangedAttacker() then
        ApplyDamage({victim = attacker, attacker = caster, damage = ability:GetLevelSpecialValueFor("damage_to_attackers",ability:GetLevel()-1), damage_type = DAMAGE_TYPE_PHYSICAL})
    end
end