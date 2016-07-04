if not Units then
    Units = class({})
end

function Units:start()
    self.Races = LoadKeyValues("scripts/kv/races.kv")

    -- Validate BoundsHullName with CollisionSize
    local builds = {}
    local units = {}
    for k,v in pairs(KeyValues.UnitKV) do
        local hullName = GetUnitKV(k, "BoundsHullName")
        local collisionSize = GetUnitKV(k, "CollisionSize")
        if hullName and collisionSize and HULL_SIZES[hullName] then
            if HULL_SIZES[hullName] ~= collisionSize then
                local bestHull = 999
                local bestName
                for name,value in pairs(HULL_SIZES) do
                    if value >= collisionSize then
                        local difference = value-collisionSize
                        if difference < bestHull-collisionSize then
                            bestHull = value
                            bestName = name
                        end
                    end
                end
                if bestName then
                    if bestName ~= hullName then
                        if GetUnitKV(k, "MovementSpeed") == 0 then
                            table.insert(builds, string.format("%-40s -> %-23s", k, bestName))
                        else
                            table.insert(units, string.format("%-40s -> %-23s", k, bestName))
                        end
                    end
                elseif hullName ~= "DOTA_HULL_SIZE_BARRACKS" then
                    if GetUnitKV(k, "MovementSpeed") == 0 then
                        table.insert(builds, string.format("%-40s -> %-23s", k, "DOTA_HULL_SIZE_BARRACKS"))
                    else
                        table.insert(units, string.format("%-40s -> %-23s", k, "DOTA_HULL_SIZE_BARRACKS"))
                    end
                end
            end
        end
    end
    if #units > 0 or #builds > 0 then
        print("Problematic BoundsHullName-CollisionSize values found.\nProposed changes:")
        for k,v in pairs(units) do
            print(v)
        end
        for k,v in pairs(builds) do
            print(v)
        end
    end
end

-- Initializes one unit with all its required modifiers and functions
function Units:Init( unit )

    -- Apply armor and damage modifier (for visuals)
    local attack_type = unit:GetAttackType()
    if attack_type and unit:GetAttackDamage() > 0 then
        ApplyModifier(unit, "modifier_attack_"..attack_type)
    end

    local armor_type = unit:GetArmorType()
    if armor_type then
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
    unit:AddNewModifier(nil,nil,"modifier_phased",{duration=0.1})
    local collision_size = unit:GetCollisionSize()
    if collision_size then
        local offset = unit:GetKeyValue("BoundsHullName") == "DOTA_HULL_SIZE_HUGE" and 10 or 0
        unit:SetHullRadius(collision_size+offset)
    end

    -- Special Tree-Attacking units
    if unit:GetKeyValue("AttacksTrees") then
        unit:SetCanAttackTrees(true)
    end

    -- Flying Height Z control
    Timers:CreateTimer(0.03, function()
        if unit:GetKeyValue("MovementCapabilities") == "DOTA_UNIT_CAP_MOVE_FLY" then
            unit:AddNewModifier(unit,nil,"modifier_flying_control",{})
        end
    end)
end

function Units:GetBaseHeroNameForRace(raceName)
    return Units.Races[raceName]["BaseHero"]
end

function Units:GetBuilderNameForRace(raceName)
    return Units.Races[raceName]["BuilderName"]
end

function Units:GetCityCenterNameForRace(raceName)
    return Units.Races[raceName]["CityCenterName"]
end

function Units:GetNumInitialBuildersForRace(raceName)
    return Units.Races[raceName]["BuilderCount"]
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

HULL_SIZES = {
    ["DOTA_HULL_SIZE_BARRACKS"]=144,
    ["DOTA_HULL_SIZE_BUILDING"]=81,
    ["DOTA_HULL_SIZE_FILLER"]=96,
    ["DOTA_HULL_SIZE_HERO"]=24,
    ["DOTA_HULL_SIZE_HUGE"]=80,
    ["DOTA_HULL_SIZE_REGULAR"]=16,
    ["DOTA_HULL_SIZE_SIEGE"]=16,
    ["DOTA_HULL_SIZE_SMALL"]=8,
    ["DOTA_HULL_SIZE_TOWER"]=144,
}

function CDOTA_BaseNPC:GetCollisionSize()
    return self:GetKeyValue("CollisionSize")
end

-- Resolve to the method in CDOTA_BaseNPC_Creature or CDOTA_BaseNPC_Hero if its a hero
function GetUnitRace( unit )
    return unit:GetRace() 
end

-- Returns a string with the race of the unit
-- Format for creature unit names: race_unitName
function CDOTA_BaseNPC_Creature:GetRace()
    return split(self:GetUnitName(), "_")[1]
end

function GetOriginalModelScale( unit )
    return GameRules.UnitKV[unit:GetUnitName()]["ModelScale"] or unit:GetModelScale()
end

function SetRangedProjectileName( unit, pProjectileName )
    unit:SetRangedProjectileName(pProjectileName)
    unit.projectileName = pProjectileName
end

function GetOriginalRangedProjectileName( unit )
    return unit:GetKeyValue("ProjectileModel") or ""
end

function GetRangedProjectileName( unit )
    return unit.projectileName or unit:GetKeyValue("ProjectileModel") or ""
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

function CDOTA_BaseNPC:IsMechanical()
    return self:GetUnitLabel():match("mechanical")
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
    return (target:GetTeamNumber() == DOTA_TEAM_NEUTRALS and target.campCenter)
end

function HasArtilleryAttack( unit )
    local unitTable = GameRules.UnitKV[unit:GetUnitName()]
    return unitTable and unitTable["Artillery"]
end

function CDOTA_BaseNPC:IsDummy()
    return self:GetUnitName():match("dummy_")
end

-- Default 0 (melee)
function CDOTA_BaseNPC:GetFormationRank()
    return self:GetKeyValue("FormationRank") or 0
end

function CDOTA_BaseNPC:RenderTeamColor()
    return self:GetKeyValue("RenderTeamColor")
end

-- All units should have DOTA_COMBAT_CLASS_ATTACK_HERO and DOTA_COMBAT_CLASS_DEFEND_HERO, or no CombatClassAttack/ArmorType defined
-- Returns a string with the wc3 damage name
function CDOTA_BaseNPC:GetAttackType()
    return self.AttackType or self:GetKeyValue("AttackType")
end

-- Returns a string with the wc3 armor name
function CDOTA_BaseNPC:GetArmorType()
    return self.ArmorType or self:GetKeyValue("ArmorType")
end

-- Changes the AttackType and current visual tooltip of the unit
function CDOTA_BaseNPC:SetAttackType( attack_type )
    local current_attack_type = self:GetAttackType()
    self:RemoveModifierByName("modifier_attack_"..current_attack_type)
    self.AttackType = attack_type
    ApplyModifier(self, "modifier_attack_"..attack_type)
end

-- Changes the ArmorType and current visual tooltip of the unit
function CDOTA_BaseNPC:SetArmorType( armor_type )
    local current_armor_type = self:GetArmorType()
    self:RemoveModifierByName("modifier_armor_"..current_armor_type)
    self.ArmorType = armor_type
    ApplyModifier(self, "modifier_armor_"..armor_type)
end

-- Returns the damage factor this unit does against another
function CDOTA_BaseNPC:GetAttackFactorAgainstTarget( unit )
    local attack_type = self:GetAttackType()
    local armor_type = unit:GetArmorType()
    local damageTable = GameRules.Damage
    return damageTable[attack_type] and damageTable[attack_type][armor_type] or 1
end

function CDOTA_BaseNPC:FindItemByName(item_name)
    for i=0,5 do
        local item = self:GetItemInSlot(i)
        if item and item:GetAbilityName() == item_name then
            return item
        end
    end
    return nil
end

function CDOTA_BaseNPC:ShouldAbsorbSpell(caster, ability)
    if self:IsOpposingTeam(caster:GetTeamNumber()) then
        if ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) and not ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_ATTACK) then
            local item = self:FindItemByName("item_amulet_of_spell_shield") 
            if item and item:IsCooldownReady() then 
                ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_ABSORIGIN, self)
                Timers:CreateTimer(0.03, function()
                    self:EmitSound("DOTA_Item.LinkensSphere.Activate")
                    item:StartCooldown(item:GetCooldown(1))
                end)
                return true
            end
        end
    end
    return false
end

Units:start()