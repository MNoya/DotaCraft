if not Units then
    Units = class({})
end

-- Initializes one unit with all its required modifiers and functions
function Units:Init( unit )

    -- Apply armor and damage modifier (for visuals)
    local attack_type = unit:GetAttackType()
    if attack_type ~= 0 and unit:GetAttackDamage() > 0 then
        ApplyModifier(unit, "modifier_attack_"..attack_type)
    end

    local armor_type = unit:GetArmorType()
    if armor_type ~= 0 then
        ApplyModifier(unit, "modifier_armor_"..armor_type)
    end

    if HasSplashAttack(unit) then
        ApplyModifier(unit, "modifier_splash_attack")
    end

    local bBuilder = IsBuilder(unit)
    if bBuilder then
        unit.oldIdle = unit.IsIdle
        function unit:IsIdle()
            return unit:oldIdle() and unit.state == "idle"
        end

        function unit:GetLumberCapacity()
            local gather_ability = FindGatherAbility( unit )
            return gather_ability and gather_ability:GetLevelSpecialValueFor("lumber_capacity", gather_ability:GetLevel()-1) or 0
        end

        if CanGatherLumber(unit) then
            unit:SetCanAttackTrees(true)
        end
    end

    -- Attack system, only applied to units and buildings with an attack
    local attacks_enabled = GetAttacksEnabled(unit)
    if attacks_enabled ~= "none" then
        if bBuilder then
            ApplyModifier(unit, "modifier_attack_system_passive")
        else
            ApplyModifier(unit, "modifier_attack_system")
        end

        -- Neutral AI aggro and leashing
        if unit:GetTeamNumber() == DOTA_TEAM_NEUTRALS and string.match(unit:GetUnitName(), "neutral_") then
            ApplyModifier(unit,"modifier_neutral_idle_aggro")

            NeutralAI:Start( unit )
        end
    end

    ApplyModifier(unit, "modifier_specially_deniable")

    -- Adjust Hull
    local collision_size = GetCollisionSize(unit)
    local hull_radius = unit:GetHullRadius()
    if collision_size and collision_size > hull_radius+10 then
        unit:SetHullRadius(GetCollisionSize(unit))
    end
end

-- Returns Int
function GetFoodProduced( unit )
    if unit and IsValidEntity(unit) then
        if GameRules.UnitKV[unit:GetUnitName()] and GameRules.UnitKV[unit:GetUnitName()].FoodProduced then
            return GameRules.UnitKV[unit:GetUnitName()].FoodProduced
        end
    end
    return 0
end

-- Returns Int
function GetFoodCost( unit )
    if unit and IsValidEntity(unit) then
        if GameRules.UnitKV[unit:GetUnitName()] and GameRules.UnitKV[unit:GetUnitName()].FoodCost then
            return GameRules.UnitKV[unit:GetUnitName()].FoodCost
        end
    end
    return 0
end

-- Returns Int
function GetGoldCost( unit )
    if unit and IsValidEntity(unit) then
        if GameRules.UnitKV[unit:GetUnitName()] and GameRules.UnitKV[unit:GetUnitName()].GoldCost then
            return GameRules.UnitKV[unit:GetUnitName()].GoldCost
        end
    end
    return 0
end

-- Returns Int
function GetLumberCost( unit )
    if unit and IsValidEntity(unit) then
        if GameRules.UnitKV[unit:GetUnitName()] and GameRules.UnitKV[unit:GetUnitName()].LumberCost then
            return GameRules.UnitKV[unit:GetUnitName()].LumberCost
        end
    end
    return 0
end

-- Returns float
function GetBuildTime( unit )
    if unit and IsValidEntity(unit) then
        if GameRules.UnitKV[unit:GetUnitName()] and GameRules.UnitKV[unit:GetUnitName()].BuildTime then
            return GameRules.UnitKV[unit:GetUnitName()].BuildTime
        end
    end
    return 0
end

function GetCollisionSize( unit )
    if unit and IsValidEntity(unit) then
        return GameRules.UnitKV[unit:GetUnitName()]["CollisionSize"] or 0
    end
    return 0
end

-- Returns a string with the race of the unit
function GetUnitRace( unit )
    local name = unit:GetUnitName()
    local name_split = split(name, "_")
    return name_split[1]
end

function GetOriginalModelScale( unit )
    return GameRules.UnitKV[unit:GetUnitName()]["ModelScale"] or unit:GetModelScale()
end

function GetRangedProjectileName( unit )
    return GameRules.UnitKV[unit:GetUnitName()]["ProjectileModel"] or ""
end

-- Checks the UnitLabel for "city_center"
function IsCityCenter( unit )
    return IsCustomBuilding(unit) and string.match(unit:GetUnitLabel(), "city_center")
end

-- Builders are stored in a nettable in addition to the builder label
function IsBuilder( unit )
    local label = unit:GetUnitLabel()
    if label == "builder" then
        return true
    end
    local table = CustomNetTables:GetTableValue("builders", tostring(unit:GetEntityIndex()))
    if table then
        return tobool(table["IsBuilder"])
    else
        return false
    end
end

function IsBase( unit )
    local race = GetUnitRace(unit)
    local unitName = unit:GetUnitName()
    if race == "human" then
        if unitName == "human_town_hall" or unitName == "human_keep" or unitName == "human_castle" then
            return true
        end
    elseif race == "nightelf" then
        if unitName == "nightelf_tree_of_life" or unitName == "nightelf_tree_of_ages" or unitName == "nightelf_tree_of_eternity" then
            return true
        end
    elseif race == "orc" then
        if unitName == "orc_great_hall" or unitName == "orc_stronghold" or unitName == "orc_fortress" then
            return true
        end
    elseif race == "undead" then
        if unitName == "undead_necropolis" or unitName == "undead_halls_of_the_dead" or unitName == "undead_black_citadel" then
            return true
        end
    end
    return false
end

-- Returns true if the unit is a valid lumberjack
function CanGatherLumber( unit )
    local unitName = unit:GetUnitName()
    local unitTable = GameRules.UnitKV[unitName]
    local gatherResources = unitTable and unitTable["GatherResources"]
    return gatherResources and string.match(gatherResources,"lumber")
end

-- Returns true if the unit is a gold miner
function CanGatherGold( unit )
    local unitName = unit:GetUnitName()
    local unitTable = GameRules.UnitKV[unitName]
    local gatherResources = unitTable and unitTable["GatherResources"]
    return gatherResources and string.match(gatherResources,"gold")
end

function FindGatherAbility( unit )
    local unitName = unit:GetUnitName()
    local unitTable = GameRules.UnitKV[unitName]
    local abilityName = unitTable and unitTable["GatherAbility"]
    return unit:FindAbilityByName(abilityName)
end

function FindReturnAbility( unit )
    local unitName = unit:GetUnitName()
    local unitTable = GameRules.UnitKV[unitName]
    local abilityName = unitTable and unitTable["ReturnAbility"]
    return unit:FindAbilityByName(abilityName)
end

function IsHuman( unit )
    return GetUnitRace(unit)=="human"
end

function IsOrc( unit )
    return GetUnitRace(unit)=="orc"
end

function IsNightElf( unit )
    return GetUnitRace(unit)=="nightelf"
end

function IsUndead( unit )
    return GetUnitRace(unit)=="undead"
end

function IsCustomBuilding( unit )
    local ability_building = unit:FindAbilityByName("ability_building")
    local ability_tower = unit:FindAbilityByName("ability_tower")
    if ability_building or ability_tower then
        return true
    else
        return false
    end
end

function IsAltar( unit )
    return string.match(unit:GetUnitName(), "_altar_")
end

function IsCustomTower( unit )
    return unit:HasAbility("ability_tower")
end

function IsCustomShop( unit )
    return unit:HasAbility("ability_shop")
end

function IsMechanical( unit )
    return unit:HasAbility("ability_siege")
end
-- Shortcut for a very common check
function IsValidAlive( unit )
    return (IsValidEntity(unit) and unit:IsAlive())
end

-- Auxiliar function that goes through every ability and item, checking for any ability being channelled
function IsChanneling ( unit )
    
    for abilitySlot=0,15 do
        local ability = unit:GetAbilityByIndex(abilitySlot)
        if ability and ability:IsChanneling() then 
            return true
        end
    end

    for itemSlot=0,5 do
        local item = unit:GetItemInSlot(itemSlot)
        if item and item:IsChanneling() then
            return true
        end
    end

    return false
end

-- Returns all visible enemies in radius of the unit/point
function FindEnemiesInRadius( unit, radius, point )
    local team = unit:GetTeamNumber()
    local position = point or unit:GetAbsOrigin()
    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
    return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, flags, FIND_CLOSEST, false)
end

-- Returns all units (friendly and enemy) in radius of the unit/point
function FindAllUnitsInRadius( unit, radius, point )
    local team = unit:GetTeamNumber()
    local position = point or unit:GetAbsOrigin()
    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
    return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, target_type, flags, FIND_ANY_ORDER, false)
end

-- Returns all units in radius of a point
function FindAllUnitsAroundPoint( unit, point, radius )
    local team = unit:GetTeamNumber()
    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
    return FindUnitsInRadius(team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, target_type, flags, FIND_ANY_ORDER, false)
end

function FindAlliesInRadius( unit, radius, point )
    local team = unit:GetTeamNumber()
    local position = point or unit:GetAbsOrigin()
    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local flags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE
    return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, flags, FIND_CLOSEST, false)
end

function HasGoldMineDistanceRestriction( unit_name )
    if GameRules.UnitKV[unit_name] then
        local restrict_distance = GameRules.UnitKV[unit_name]["RestrictGoldMineDistance"]
        if restrict_distance then
            return restrict_distance
        end
    end
    return false
end

function ReplaceUnit( unit, new_unit_name )
    --print("Replacing "..unit:GetUnitName().." with "..new_unit_name)

    local hero = unit:GetOwner()
    local playerID = hero:GetPlayerOwnerID()

    local position = unit:GetAbsOrigin()
    local relative_health = unit:GetHealthPercent()

    local new_unit = CreateUnitByName(new_unit_name, position, true, hero, hero, hero:GetTeamNumber())
    new_unit:SetOwner(hero)
    new_unit:SetControllableByPlayer(playerID, true)
    new_unit:SetHealth(new_unit:GetMaxHealth() * relative_health)
    FindClearSpaceForUnit(new_unit, position, true)

    if PlayerResource:IsUnitSelected(playerID, unit) then
        PlayerResource:AddToSelection(playerID, new_unit)
    end

    -- Add the new unit to the player units
    Players:AddUnit(playerID, new_unit)

    -- Remove replaced unit from the game
    Players:RemoveUnit(playerID, unit)
    unit:RemoveSelf()

    return new_unit
end

function HasTrainAbility( unit )
    for i=0,15 do
        local ability = unit:GetAbilityByIndex(i)
        if ability then
            local ability_name = ability:GetAbilityName()
            if string.match(ability_name, "_train_") then
                return true
            end
        end
    end
    return false
end

-- Returns if the builder is fully idle (not reparing or in a gathering process)
function IsIdleBuilder( unit )
    return (unit.state == "idle" and unit:IsIdle())
end

function ApplyConstructionEffect( unit )
    local item = CreateItem("item_apply_modifiers", nil, nil)
    item:ApplyDataDrivenModifier(unit, unit, "modifier_construction", {})
    item = nil
end

function RemoveConstructionEffect( unit )
    unit:RemoveModifierByName("modifier_construction")
end

function HoldPosition( unit )
    unit.bHold = true
    ApplyModifier(unit, "modifier_hold_position")
end

function IsAlliedUnit( unit, target )
    return (unit:GetTeamNumber() == target:GetTeamNumber())
end

function IsNeutralUnit( target )
    return (target:GetTeamNumber() == DOTA_TEAM_NEUTRALS)
end

function HasArtilleryAttack( unit )
    local unitTable = GameRules.UnitKV[unit:GetUnitName()]
    return unitTable and unitTable["Artillery"]
end

function CDOTA_BaseNPC:RenderTeamColor()
    return GameRules.UnitKV[self:GetUnitName()]["RenderTeamColor"]
end

-- All units should have DOTA_COMBAT_CLASS_DEFEND_HERO and DOTA_COMBAT_CLASS_DEFEND_HERO, or no CombatClassAttack/ArmorType defined
-- Returns a string with the wc3 damage name
function CDOTA_BaseNPC:GetAttackType()
    return GameRules.UnitKV[self:GetUnitName()]["AttackType"] or "normal"
end

-- Returns a string with the wc3 armor name
function CDOTA_BaseNPC:GetArmorType()
    return GameRules.UnitKV[self:GetUnitName()]["ArmorType"] or "normal"
end

-- Changes the Attack Type string defined in the KV, and the current visual tooltip
function CDOTA_BaseNPC:SetAttackType( attack_type )
    local current_attack_type = self:GetAttackType()
    self:RemoveModifierByName("modifier_attack_"..current_attack_type)

    GameRules.UnitKV[self:GetUnitName()]["AttackType"] = attack_type        
    ApplyModifier(self, "modifier_attack_"..attack_type)
end

-- Changes the Armor Type string defined in the KV, and the current visual tooltip
function CDOTA_BaseNPC:SetArmorType( armor_type )
    local current_armor_type = self:GetArmorType()
    self:RemoveModifierByName("modifier_armor_"..current_armor_type)

    GameRules.UnitKV[self:GetUnitName()]["ArmorType"] = armor_type
    ApplyModifier(self, "modifier_armor_"..armor_type)
end

-- Returns the damage factor this unit does against another
function CDOTA_BaseNPC:GetAttackFactorAgainstTarget( unit )
    local attack_type = self:GetAttackType()
    local armor_type = unit:GetArmorType()
    local damageTable = GameRules.Damage
    return damageTable[attack_type] and damageTable[attack_type][armor_type] or 1
end

-- Enables/disables the access to right-clicking
function CDOTA_BaseNPC:SetCanAttackTrees(bAble)
    if bAble then
        ApplyModifier(self, "modifier_attack_trees")
    else
        self:RemoveModifierByName("modifier_attack_trees")
    end
end