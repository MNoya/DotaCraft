-- Global item applier
function ApplyModifier( unit, modifier_name )
    GameRules.Applier:ApplyDataDrivenModifier(unit, unit, modifier_name, {})
end

-- Goes through all modifiers
function CDOTA_BaseNPC:HasPurgableModifiers(bRemovePositiveBuffs)
    local allModifiers = self:FindAllModifiers()
    if bRemovePositiveBuffs then
        for _,modifier in pairs(allModifiers) do
            if modifier:IsPurgableModifier() and not modifier:IsDebuffModifier() then
                return modifier
            end
        end
    else
        for _,modifier in pairs(allModifiers) do
            if modifier:IsPurgableModifier() and modifier:IsDebuffModifier() then
                return modifier
            end
        end

        if self:HasModifier("modifier_brewmaster_storm_cyclone") then
            return self:FindModifierByName("modifier_brewmaster_storm_cyclone")
        end
    end
    return false
end

-- Takes a CDOTA_Buff to check for the IsPurgable key
-- If it is, returns the ability name of the ability associated with it
function CDOTA_Buff:IsPurgableModifier()
    if self.IsPurgable then return self:IsPurgable() end -- CDOTA_Modifier_Lua
    local abilityName = self:GetAbilityName()
    if not abilityName then return false end
    local ability_table = GetKeyValue(abilityName)
    if ability_table then
        local modifier_table = ability_table["Modifiers"] and ability_table["Modifiers"][self:GetName()]
        if modifier_table then
            local bPurgable = modifier_table["IsPurgable"]
            return bPurgable and bPurgable == 1
        end
    end
    return false
end

-- If it has the "IsDebuff" "1" key specified then it's a debuff, otherwise take it as a buff
function CDOTA_Buff:IsDebuffModifier()
    if self.IsDebuff then return self:IsDebuff() end -- CDOTA_Modifier_Lua
    local abilityName = self:GetAbilityName() -- Added on modifier filter
    if not abilityName then return false end
    local ability_table = GetKeyValue(abilityName)
    if ability_table then
        local modifier_table = ability_table["Modifiers"] and ability_table["Modifiers"][self:GetName()]
        if modifier_table then
            local bDebuff = modifier_table["IsDebuff"]
            return bDebuff and bDebuff == 1
        end
    end
    return false
end

function CDOTA_Buff:GetAbilityName()
    return self.abilityName -- Added on modifier filter
end

-- Passes a modifier from one unit to another
function CDOTA_Buff:Transfer(unit, caster)
    local ability = self:GetAbility()
    local duration = self:GetDuration()

    -- If the ability was removed (because the modifier was applied by a unit that died later), we apply it via hero
    if not IsValidEntity(ability) then
        local playerID = caster:GetPlayerOwnerID()
        local fakeHero = PlayerResource:GetSelectedHeroEntity(playerID)
        local abilityName = self:GetAbilityName()
        ability = fakeHero:AddAbility(abilityName)
        Timers:CreateTimer(0.03, function()
            local allModifiers = fakeHero:FindAllModifiers()
            for _,modifier in pairs(allModifiers) do
                -- Remove any associated modifiers that were passively added by the ability
                if modifier:GetAbility() == ability then
                    UTIL_Remove(modifier)
                end
            end
            UTIL_Remove(ability)
        end)
    end

    if ability then
        ability:SetLevel(ability:GetMaxLevel())
        if ability.ApplyDataDrivenModifier then
            ability:ApplyDataDrivenModifier(caster, unit, self:GetName(), {duration = duration})
        else
            unit:AddNewModifier(caster, ability, self:GetName(), {duration = duration})
        end
        self:Destroy()
        return true
    end
    return false
end