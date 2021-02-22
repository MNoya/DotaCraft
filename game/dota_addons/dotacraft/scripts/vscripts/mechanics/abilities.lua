function CDOTABaseAbility:IsAllowedTarget(target)
    local bIgnoreAir = target:HasFlyMovementCapability() and not self:AffectsAir()
    if bIgnoreAir then
        if not self:AffectsMechanical() then
            return false,"error_must_target_organic_ground"
        else
            return false,"error_cant_target_air"
        end
    end

    local bIgnoreMechanical = target:IsMechanical() and not self:AffectsMechanical()
    if bIgnoreMechanical then
        if not self:AffectsAir() then
            return false,"error_must_target_organic_ground"
        else
            return false,"error_must_target_organic"
        end
    end

    local bIgnoreBuilding = IsCustomBuilding(target) and not self:AffectsBuildings()
    if bIgnoreBuilding then
        return false,"error_cant_target_buildings"
    end

    local bIgnoreGround = not target:IsFlyingUnit() and not self:AffectsGround() and self:AffectsAir()
    if bIgnoreGround then
        return false,"error_must_target_air"
    end

    local bIgnoreWard = target:IsWard() and not self:AffectsWards()
    if bIgnoreWard then
        return false,"error_cant_target_wards"
    end

    local maxLevel = self:GetKeyValue("MaxCreepLevel")
    if maxLevel and target:GetLevel() > maxLevel then
        return false,"error_cant_target_level6"
    end

    local bRequiresTargetMana = self:GetKeyValue("RequiresTargetMana")
    local maxMana = target:GetMaxMana()
    if bRequiresTargetMana and maxMana == 0 then
        return false,"error_must_target_mana_unit"
    end

    local bNeedsAnyDeficit = self:GetKeyValue("RequiresAnyDeficit")
    if bNeedsAnyDeficit and target:GetHealthDeficit() == 0 and target:GetMana() == maxMana then
        if maxMana > 0 then
            return false,"error_full_mana_health"
        else
            return false,"error_full_health"
        end
    end

    local bNeedsHealthDeficit = self:GetKeyValue("RequiresHealthDeficit")
    if bNeedsHealthDeficit then
        if bNeedsHealthDeficit == "self" then
            if self:GetCaster():GetHealthDeficit() == 0 then
                return false,"error_full_health"
            end
        elseif bNeedsHealthDeficit == "target" then
            if target:GetHealthDeficit() == 0 then
                return false,"error_full_health"
            end
        end
    end

    local bNeedsManaDeficit = self:GetKeyValue("RequiresManaDeficit")
    if bNeedsManaDeficit then
        if bNeedsManaDeficit == "self" then
            if self:GetCaster():GetMaxMana() == self:GetCaster():GetMana() then
                return false,"error_full_mana"
            end

        elseif target:GetMana() == maxMana then
            return false,"error_full_mana"
        end
    end

    return true
end

-- All abilities that affect buildings must have DOTA_UNIT_TARGET_BUILDING in its AbilityUnitTargetType
function CDOTABaseAbility:AffectsBuildings()
    return self:HasTargetType(DOTA_UNIT_TARGET_BUILDING)
end

-- Keyword 'organic' in TargetsAllowed will prevent the ability from affecting (targeting/damaging/modifying) units marked labeled "mechanical"
function CDOTABaseAbility:AffectsMechanical()
    local targets = self:GetKeyValue("TargetsAllowed") or ""
    return not targets:match("organic")
end

-- Keyword 'ground' in TargetsAllowed will prevent the ability from affecting (targeting/damaging/modifying) units with DOTA_UNIT_CAP_MOVE_FLY
function CDOTABaseAbility:AffectsAir()
    local targets = self:GetKeyValue("TargetsAllowed") or ""
    return not targets:match("ground")
end

-- Keyword 'air' in TargetsAllowed will prevent the ability from affecting (targeting/damaging/modifying) units without DOTA_UNIT_CAP_MOVE_FLY
function CDOTABaseAbility:AffectsGround()
    local targets = self:GetKeyValue("TargetsAllowed") or ""
    return not targets:match("air")
end

-- Keyword 'ward' in TargetsAllowed will allow the ability to affect units marked labeled "ward"
function CDOTABaseAbility:AffectsWards()
    local targets = self:GetKeyValue("TargetsAllowed") or ""
    return targets:match("ward")
end

function CDOTABaseAbility:HasTargetType(flag)
    return bit.band(self:GetAbilityTargetType(), flag) == flag
end

function CDOTABaseAbility:HasTargetFlag(flag)
    return bit.band(self:GetAbilityTargetFlags(), flag) == flag
end

function CDOTABaseAbility:HasBehavior(flag)
    return bit.band(tonumber(tostring(self:GetBehavior())), flag) == flag
end

-- Deals damage to units with an optional buildingFactor, if the total passes maxDamage, the damage each unit receives is split
function CDOTABaseAbility:ApplyDamageUnitsMax(damage, units, maxDamage)
    local caster = self:GetCaster()
    local expectedDamage = 0
    local buildingFactor = self:GetKeyValue("BuildingReduction") or 1
    for k,target in pairs(units) do
        if not target:IsDummy() then
            if IsCustomBuilding(target) then
                expectedDamage = expectedDamage + damage*buildingFactor
            else
                expectedDamage = expectedDamage + damage
            end
        end
    end

    local factor = 1
    if expectedDamage > maxDamage then
        factor = maxDamage/expectedDamage
    end

    for k,target in pairs(units) do
        if not target:IsDummy() then
            local damageDone = damage * factor
            if IsCustomBuilding(target) then
                DamageBuilding(target, damageDone*buildingFactor, self, caster)
            else
                ApplyDamage({ victim = target, attacker = caster, damage = damageDone, ability = self, damage_type = self:GetAbilityDamageType() })
            end
        end
    end
end

-- A BuildingHelper ability is identified by the "Building" key.
function IsBuildingAbility( ability )
    if not IsValidEntity(ability) then
        return
    end

    local ability_name = ability:GetAbilityName()
    local ability_table = GameRules.AbilityKV[ability_name]
    if ability_table and ability_table["Building"] then
        return true
    else
        ability_table = GameRules.ItemKV[ability_name]
        if ability_table and ability_table["Building"] then
            return true
        end
    end

    return false
end

function PrintAbilities( unit )
    print("List of Abilities in "..unit:GetUnitName())
    for i=0,15 do
        local ability = unit:GetAbilityByIndex(i)
        if ability then print(i.." - "..ability:GetAbilityName()) end
    end
    print("---------------------")
end

-- Adds an ability to the unit by its name
function TeachAbility( unit, ability_name )
    unit:AddAbility(ability_name)
    local ability = unit:FindAbilityByName(ability_name)
    if ability then
        ability:SetLevel(1)
    else
        print("ERROR, failed to teach ability "..ability_name)
    end
end

function GenerateAbilityString(player, ability_table)
    local abilities_string = ""
    local index = 1
    while ability_table[tostring(index)] do
        local ability_name = ability_table[tostring(index)]
        local ability_available = false
        if FindAbilityOnStructures(player, ability_name) or FindAbilityOnUnits(player, ability_name) then
            ability_available = true
        end
        index = index + 1
        if ability_available then
            abilities_string = abilities_string.."1,"
        else
            abilities_string = abilities_string.."0,"
        end
    end
    return abilities_string
end

-- ToggleAbility On only if its turned Off
function ToggleOn( ability )
    if ability:GetToggleState() == false then
        ability:ToggleAbility()
    end
end

-- ToggleAbility Off only if its turned On
function ToggleOff( ability )
    if ability:GetToggleState() == true then
        ability:ToggleAbility()
    end
end

function IsMultiOrderAbility( ability )
    return IsValidEntity(ability) and ability:GetKeyValue("AbilityMultiOrder")
end

function SetAbilityLayout( unit, layout_size )
    if unit:HasModifier("modifier_ability_layout"..layout_size) then
        return
    else
        unit:RemoveModifierByName("modifier_ability_layout4")
        unit:RemoveModifierByName("modifier_ability_layout5")
        unit:RemoveModifierByName("modifier_ability_layout6")
        ApplyModifier(unit, "modifier_ability_layout"..layout_size)
    end
end

function AdjustAbilityLayout( unit )
    local required_layout_size = GetVisibleAbilityCount(unit)

    if required_layout_size > 6 then
        required_layout_size = 6
    elseif required_layout_size < 4 then
        required_layout_size = 4
    end

    SetAbilityLayout(unit, required_layout_size)
end

function GetVisibleAbilityCount( unit )
    local count = 0
    for i=0,15 do
        local ability = unit:GetAbilityByIndex(i)
        if ability and not ability:IsHidden() then
            count = count + 1
            --ability:MarkAbilityButtonDirty()
        end
    end
    return count
end

function FindAbilityWithName( unit, ability_name_section )
    for i=0,15 do
        local ability = unit:GetAbilityByIndex(i)
        if ability and string.match(ability:GetAbilityName(), ability_name_section) then
            return ability
        end
    end
end

function GetAbilityOnVisibleSlot( unit, slot )
    local visible_slot = 0
    for i=0,15 do
        local ability = unit:GetAbilityByIndex(i)
        if ability and not ability:IsHidden() then
            visible_slot = visible_slot + 1
            if visible_slot == slot then
                return ability
            end
        end
    end
end

-- Used by abilities that should be automatically toggled on spawn
function ToggleOnAutocast(event)
    if not event.ability:GetAutoCastState() then
        event.ability:ToggleAutoCast()
    end
end

-- Used by root abilities
function Interrupt(event)
    event.target:Interrupt()
end