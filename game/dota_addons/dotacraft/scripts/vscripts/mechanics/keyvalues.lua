-- Works for heroes and units on the same table due to merging both tables on game init
function CDOTA_BaseNPC:GetKeyValues()
    return GameRules.UnitKV[self:GetUnitName()]
end

-- Dynamic version of CDOTABaseAbility:GetAbilityKeyValues()
function CDOTABaseAbility:GetKeyValues()
    return GameRules.AbilityKV[self:GetAbilityName()]
end

-- Item version
function CDOTA_Item:GetKeyValues()
    return GameRules.ItemKV[self:GetAbilityName()]
end