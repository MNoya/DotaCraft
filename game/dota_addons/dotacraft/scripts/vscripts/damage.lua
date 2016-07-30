function dotacraft:FilterDamage( filterTable )
    --for k, v in pairs( filterTable ) do
    --  print("Damage: " .. k .. " " .. tostring(v) )
    --end
    local victim_index = filterTable["entindex_victim_const"]
    local attacker_index = filterTable["entindex_attacker_const"]
    if not victim_index or not attacker_index then
        return true
    end

    local victim = EntIndexToHScript( victim_index )
    local attacker = EntIndexToHScript( attacker_index )
    local damagetype = filterTable["damagetype_const"]
    local inflictor = filterTable["entindex_inflictor_const"]

    if inflictor then
        local ability = EntIndexToHScript(inflictor)
        local bBlock = victim:ShouldAbsorbSpell(attacker, ability)
        if bBlock then
            return false
        end

        if ability and ability.IsAllowedTarget then
            local bAllowTarget = ability:IsAllowedTarget(victim)
            if not bAllowTarget then
                return false
            end
        end
    end

    -- Revert damage from MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
    if inflictor and attacker:IsHero() then
        filterTable["damage"] = math.floor(filterTable["damage"]/(1+((attacker:GetIntellect()/16)/100))+0.5)
    end

    local value = filterTable["damage"] --Post reduction
    local damage,reduction = dotacraft:GetPreMitigationDamage(value, victim, attacker, damagetype) --Pre reduction

    if victim.OnIncomingDamage then
        damage = victim:OnIncomingDamage(damage)
    end

    -- Physical attack damage filtering
    if damagetype == DAMAGE_TYPE_PHYSICAL then
        if victim == attacker and not inflictor then return end -- Self attack, for fake attack ground

        if attacker:HasSplashAttack() and not inflictor then
            SplashAttackUnit(attacker, victim:GetAbsOrigin())
            return false
        end

        -- Apply custom armor reduction
        local attack_damage = damage
        local attack_type  = attacker:GetAttackType()
        local armor_type = victim:GetArmorType()
        local multiplier = attacker:GetAttackFactorAgainstTarget(victim)
        local armor = victim:GetPhysicalArmorValue()

        damage = (attack_damage * (1 - reduction)) * multiplier
        
        --print(string.format("Damage (%s attack vs %.f %s armor): (%.f * %.2f) * %.2f = %.f", attack_type, armor, armor_type, attack_damage, 1-reduction, multiplier, damage))

        -- Extra rules for certain ability modifiers
        -- modifier_defend (50% less damage from Piercing attacks)
        if victim:HasModifier("modifier_defend") and attack_type == "pierce" then
            damage = damage * 0.5

        -- modifier_elunes_grace (Piercing attacks to 65%)
        elseif victim:HasModifier("modifier_elunes_grace") and attack_type == "pierce" then
            damage = damage * 0.65
        end

        -- modifier_ethereal (Magic attacks to 166%)
        if victim:HasModifier("modifier_ethereal") and attack_type == "magic" then
            damage = damage * 1.66
        end
        
        -- Reassign the new damage
        filterTable["damage"] = damage
    
    -- Magic damage filtering
    elseif damagetype == DAMAGE_TYPE_MAGICAL then

        -- Extra rules for certain ability modifiers
        -- modifier-anti_magic_shell (Absorbs 300 magic damage)
        if victim:HasModifier("modifier_anti_magic_shell") then
            local absorbed = 0
            local absorbed_already = victim.anti_magic_shell_absorbed

            if damage+absorbed_already < 300 then
                absorbed = damage
                victim.anti_magic_shell_absorbed = absorbed_already + damage
            else
                -- Absorb up to the limit and end
                absorbed = 300 - absorbed_already
                victim:RemoveModifierByName("modifier_anti_magic_shell")
                victim.anti_magic_shell_absorbed = nil
            end
            damage = damage - absorbed
        end 
        
        -- Reassign the new damage
        filterTable["damage"] = damage
    end

    -- Cheat code host only
    if GameRules.WhosYourDaddy then
        local victimID = EntIndexToHScript(victim_index):GetPlayerOwnerID()
        if victimID == 0 then
            filterTable["damage"] = 0
        end
    end

    return true
end

function dotacraft:GetPreMitigationDamage(value, victim, attacker, damagetype)
    if damagetype == DAMAGE_TYPE_PHYSICAL then
        local armor = victim:GetPhysicalArmorValue()
        local reduction = ((armor)*0.06) / (1+0.06*(armor))
        local damage = value / (1 - reduction)

        return damage,reduction

    elseif damagetype == DAMAGE_TYPE_MAGICAL then
        local reduction = victim:GetMagicalArmorValue()*0.01
        local damage = value / (1 - reduction)

        return damage,reduction
    else
        return value,0
    end
end

function DamageBuilding(target, damage, ability, caster)
    local currentHP = target:GetHealth()
    local newHP = currentHP - damage

    -- If the HP would hit 0 with this damage, kill the unit
    if newHP <= 0 then
        target:Kill(nil, caster)
    else
        target:SetHealth(newHP)
    end
end

DAMAGE_TYPES = {
    [0] = "DAMAGE_TYPE_NONE",
    [1] = "DAMAGE_TYPE_PHYSICAL",
    [2] = "DAMAGE_TYPE_MAGICAL",
    [4] = "DAMAGE_TYPE_PURE",
    [7] = "DAMAGE_TYPE_ALL",
    [8] = "DAMAGE_TYPE_HP_REMOVAL",
}
