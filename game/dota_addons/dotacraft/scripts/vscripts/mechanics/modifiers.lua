-- Global item applier
function ApplyModifier( unit, modifier_name )
    GameRules.Applier:ApplyDataDrivenModifier(unit, unit, modifier_name, {})
end

-- Takes a CDOTA_Buff handle and checks the Ability KV table for the IsPurgable key
function IsPurgableModifier( modifier_handle )
    local ability = modifier_handle:GetAbility()
    local modifier_name = modifier_handle:GetName()

    if ability and IsValidEntity(ability) then
        local ability_name = ability:GetAbilityName()
        local ability_table = GameRules.AbilityKV[ability_name]

        -- Check for item ability
        if not ability_table then
            --print(modifier_name.." might be an item")
            ability_table = GameRules.ItemKV[ability_name]
        end

        -- Proceed only if the ability is really found
        if ability_table then
            local modifier_table = ability_table["Modifiers"]
            if modifier_table then
                modifier_subtable = ability_table["Modifiers"][modifier_name]

                if modifier_subtable then
                    local IsPurgable = modifier_subtable["IsPurgable"]
                    if IsPurgable and IsPurgable == 1 then
                        --print(modifier_name.." from "..ability_name.." is purgable!")
                        return true
                    end
                else
                    --print("Couldn't find modifier table for "..modifier_name)
                end
            end
        end
    end

    return false
end

-- If it has the "IsDebuff" "1" key specified then it's a debuff, otherwise take it as a buff
function IsDebuff( modifier_handle )
    local ability = modifier_handle:GetAbility()
    local modifier_name = modifier_handle:GetName()

    if ability and IsValidEntity(ability) then
        local ability_name = ability:GetAbilityName()
        local ability_table = GameRules.AbilityKV[ability_name]

        -- Check for item ability
        if not ability_table then
            ability_table = GameRules.ItemKV[ability_name]
        end

        -- Proceed only if the ability is really found
        if ability_table then
            local modifier_table = ability_table["Modifiers"][modifier_name]
            if modifier_table then
                local IsDebuff = modifier_table["IsDebuff"]
                if IsDebuff and IsDebuff == 1 then
                    return true
                end
            end
        end
    end

    return false
end