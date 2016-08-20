if not Units then
    Units = class({})
end

-- Initializes one unit with all its required modifiers and functions
function Units:Init( unit )
    if unit.bFirstSpawned and not unit:IsRealHero() then return
    else unit.bFirstSpawned = true end

    -- Apply armor and damage modifier (for visuals)
    local attack_type = unit:GetAttackType()
    if attack_type and unit:GetAttackDamage() > 0 then
        ApplyModifier(unit, "modifier_attack_"..attack_type)
    end

    local armor_type = unit:GetArmorType()
    if armor_type then
        ApplyModifier(unit, "modifier_armor_"..armor_type)
    end

    if unit:HasSplashAttack() then
        ApplyModifier(unit, "modifier_splash_attack")
    end

    local bBuilder = IsBuilder(unit)
    local bBuilding = IsCustomBuilding(unit)
    if bBuilder then
        function unit:IsIdle()
            return not unit:IsMoving() and unit.state == "idle"
        end
    end

    -- Attack system, only applied to units and buildings with an attack
    local attacks_enabled = unit:GetAttacksEnabled()
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
    if not bBuilding and collision_size then
        unit:SetHullRadius(collision_size)
    end

    -- Disable Gold Bounty for non-neutral kills
    if unit:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
        unit:SetMaximumGoldBounty(0)
        unit:SetMinimumGoldBounty(0)
    end

    -- Special Tree-Attacking units
    if unit:GetKeyValue("AttacksTrees") then
        unit:SetCanAttackTrees(true)
    end

    -- Store autocast abilities to iterate over them later. Note that we also need to store more abilities after research
    local autocast_abilities = {}
    for i=0,15 do
        local ability = unit:GetAbilityByIndex(i)
        if ability and ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_AUTOCAST) then
            table.insert(autocast_abilities, ability)
        end
    end
    if #autocast_abilities > 0 then
        unit.autocast_abilities = autocast_abilities
    end
    
    Timers:CreateTimer(0.03, function()
        if not IsValidAlive(unit) then return end
        
        -- Flying Height Z control
        if unit:GetKeyValue("MovementCapabilities") == "DOTA_UNIT_CAP_MOVE_FLY" then
            unit:AddNewModifier(unit,nil,"modifier_flying_control",{})
        end

        -- Building Queue
        if unit:GetKeyValue("HasQueue") then
            Queue:Init(unit)
        end

        if unit:IsCreature() and PlayerResource:IsValidPlayerID(unit:GetPlayerOwnerID()) then
            unit:ApplyRankUpgrades()
        end
    end)
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
            if HULL_SIZES[hullName] ~= collisionSize and HULL_SIZES[hullName]+10 <= collisionSize then
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
    local collision_size = self:GetKeyValue("CollisionSize")
    return collision_size
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

function IsCustomBuilding(unit)
    return unit:HasModifier("modifier_building") or IsUprooted(unit)
end

function IsUprooted(unit)
    return unit:HasModifier("modifier_uprooted")
end

function IsUnsummoning(unit)
    return unit:HasModifier("modifier_unsummoning")
end

function IsNightElfAncient(unit)
    return unit:HasAbility("nightelf_eat_tree")
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

function IsAltar( unit )
    return string.match(unit:GetUnitName(), "_altar_")
end

function IsCustomShop( unit )
    return unit:HasAbility("ability_shop")
end

function CDOTA_BaseNPC:IsMechanical()
    return self:GetUnitLabel():match("mechanical")
end

function CDOTA_BaseNPC:IsWard()
    return self:GetUnitLabel():match("ward")
end

function CDOTA_BaseNPC:IsEthereal()
    return self:HasModifier("modifier_ethereal")
end

function CDOTA_BaseNPC:IsFlyingUnit()
    return self:GetKeyValue("MovementCapabilities") == "DOTA_UNIT_CAP_MOVE_FLY"
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
            return ability
        end
    end

    for itemSlot=0,5 do
        local item = unit:GetItemInSlot(itemSlot)
        if item and item:IsChanneling() then
            return ability
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

-- Filters buildings and mechanical units
function FindOrganicAlliesInRadius( unit, radius, point )
    local team = unit:GetTeamNumber()
    local position = point or unit:GetAbsOrigin()
    local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
    local flags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE
    local allies = FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, flags, FIND_CLOSEST, false)
    local organic_allies = {}
    for _,ally in pairs(allies) do
        if not IsCustomBuilding(ally) and not ally:IsMechanical() then
            table.insert(organic_allies, ally)
        end
    end
    return organic_allies
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
    local relative_health = unit:GetHealthPercent() * 0.01
    local fv = unit:GetForwardVector()
    local new_unit = CreateUnitByName(new_unit_name, position, true, hero, hero, hero:GetTeamNumber())
    new_unit:SetOwner(hero)
    new_unit:SetControllableByPlayer(playerID, true)
    new_unit:SetHealth(new_unit:GetMaxHealth() * relative_health)
    new_unit:SetForwardVector(fv)
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

function HasRallyPoint(building)
    return HasTrainAbility(building) and not building:GetUnitName():match("_tower")
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

-- Overrides dota method, use modifier_summoned MODIFIER_STATE_DOMINATED
function CDOTA_BaseNPC:IsSummoned()
    return self:IsDominated()
end

function CDOTA_BaseNPC:HasArtilleryAttack()
    return self:GetKeyValue("Artillery")
end

function CDOTA_BaseNPC:HasSplashAttack()
    return self:GetKeyValue("SplashAttack")
end

function CDOTA_BaseNPC:HasDeathAnimation()
    return self:GetKeyValue("HasDeathAnimation")
end

function CDOTA_BaseNPC:IsDummy()
    return self:GetUnitName():match("dummy_") or self:GetUnitLabel():match("dummy")
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

-- Default by omission is "none", other possible returns should be "ground,air" or "air"
function CDOTA_BaseNPC:GetAttacksEnabled()
    return self.attacksEnabled or self:GetKeyValue("AttacksEnabled") or "none"
end

-- Overrides the keyvalue and sets nettable index for that unit
function CDOTA_BaseNPC:SetAttacksEnabled( attacks )
    self.attacksEnabled = attacks
    CustomNetTables:SetTableValue("attacks_enabled", tostring(self:GetEntityIndex()), {enabled = attacks})
end

-- MODIFIER_PROPERTY_HEALTH_BONUS doesn't work on npc_dota_creature
function CDOTA_BaseNPC_Creature:IncreaseMaxHealth(bonus)
    local newHP = self:GetMaxHealth() + bonus
    local relativeHP = self:GetHealthPercent() * 0.01
    self:SetMaxHealth(newHP)
    self:SetBaseMaxHealth(newHP)
    self:SetHealth(newHP * relativeHP)
end

-- Increases levels keeping up relative HP
function CDOTA_BaseNPC_Creature:LevelUp(levels)
    local relativeHP = self:GetHealthPercent() * 0.01
    local relativeMana = self:GetMana()/self:GetMaxMana()

    self:CreatureLevelUp(levels)
    self:SetHealth(self:GetMaxHealth() * relativeHP)
    self:SetMana(self:GetMaxMana() * relativeMana)
end

function CDOTA_BaseNPC_Creature:TransferOwnership(newOwnerID)
    local oldOwnerID = self:GetPlayerOwnerID()

    -- Remove the unit from the enemy player unit list
    local foodCost = GetFoodCost(self) or 0
    if PlayerResource:IsValidPlayer(oldOwnerID) and oldOwnerID ~= newOwnerID then
        Players:RemoveUnit(oldOwnerID, self)
        Players:ModifyFoodUsed(newOwnerID, -foodCost)
    end
    
    self:SetOwner(PlayerResource:GetSelectedHeroEntity(newOwnerID))
    self:SetControllableByPlayer(newOwnerID, true)
    self:SetTeam(PlayerResource:GetTeam(newOwnerID))
    Players:AddUnit(newOwnerID, self)
    Players:ModifyFoodUsed(newOwnerID, foodCost)            
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

function CDOTA_BaseNPC:FindClearSpace(origin)
    local collisionSize = self:GetCollisionSize()
    if not collisionSize then return end
    local gridSize = math.ceil(collisionSize/32)+1
    origin = origin or self:GetAbsOrigin()
    if gridSize >= 2 then
        local position
        local originX = GridNav:WorldToGridPosX(origin.x)
        local originY = GridNav:WorldToGridPosY(origin.y)

        local boundX1 = originX + 10
        local boundX2 = originX - 10
        local boundY1 = originY + 10
        local boundY2 = originY - 10

        local lowerBoundX = math.min(boundX1, boundX2)
        local upperBoundX = math.max(boundX1, boundX2)
        local lowerBoundY = math.min(boundY1, boundY2)
        local upperBoundY = math.max(boundY1, boundY2)

        -- Restrict to the map edges
        lowerBoundX = math.max(lowerBoundX, -BuildingHelper.squareX/2+1)
        upperBoundX = math.min(upperBoundX, BuildingHelper.squareX/2-1)
        lowerBoundY = math.max(lowerBoundY, -BuildingHelper.squareY/2+1)
        upperBoundY = math.min(upperBoundY, BuildingHelper.squareY/2-1)

        -- Adjust even size
        if (gridSize % 2) == 0 then
            upperBoundX = upperBoundX-1
            upperBoundY = upperBoundY-1
        end
        
        local closestDistance = math.huge
        for x = lowerBoundX, upperBoundX do
            for y = lowerBoundY, upperBoundY do
                local pos = GetGroundPosition(Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0), nil)
                if not BuildingHelper:IsAreaBlocked(gridSize, pos) then
                    local distance = (pos - origin):Length2D()
                    if distance < closestDistance then
                        position = pos
                        closestDistance = distance
                    end
                end
            end
        end

        if position then
            FindClearSpaceForUnit(self, position, true)
            return
        end
    end
    
    FindClearSpaceForUnit(self, origin, true)
end

function Unsummon(target, callback)
    local playerID = target:GetPlayerOwnerID()
    if IsUnsummoning(target) or not IsCustomBuilding(target) or target:IsUnderConstruction() then
        SendErrorMessage(playerID, "#error_invalid_unsummon_target")
        return true
    end

    target:AddNewModifier(target,nil,"modifier_unsummoning",{})

    -- remove abilities, refund items, stop channels
    for i=0,5 do
        local item = target:GetItemInSlot(i)
        if item then
            target:CastAbilityImmediately(item, playerID)
        end
    end
    for i=0,15 do
        local ability = target:GetAbilityByIndex(i)
        if ability and not ability:IsHidden() then
            ability:SetHidden(true)
        end
    end
    
    -- 50% refund
    local goldCost = (0.5 * GetGoldCost(target))
    local lumberCost = (0.5 * GetLumberCost(target))
    
    -- calculate refund per tick
    local steps = target:GetMaxHealth() / 50
    local lumberGain = (lumberCost / steps)
    local goldGain = (goldCost / steps)
    
    Timers:CreateTimer(function()
        if not IsValidEntity(target) then return end
              
        Players:ModifyGold(playerID, goldGain)
        Players:ModifyLumber(playerID, lumberGain)
        if target:GetHealth() <= 50 then -- refund resource + kill unit
            target:ForceKill(true)
            callback()
            return
        else -- refund resource + apply damage
            target:SetHealth(target:GetHealth() - 50)
        end
        return 1
    end)
end


-- Removes the modifiers associated to an ability name on this unit
function CDOTA_BaseNPC:RemoveModifiersAssociatedWith(ability_name)
    local modifiers = self:FindAllModifiers()

    for _,modifier in pairs(modifiers) do
        local ability = modifier:GetAbility()
        if IsValidEntity(ability) and ability:GetAbilityName() == ability_name then
            modifier:Destroy()
        end
    end
end

-- Checks all rank upgrades and set them to the correct ability level
function CDOTA_BaseNPC_Creature:ApplyRankUpgrades()
    local upgrades = self:GetKeyValue("Upgrades")
    if not upgrades then return end
    local playerID = self:GetPlayerOwnerID()
    for research_name,wearable_type in pairs(upgrades) do
        local level = Players:GetCurrentResearchRank(playerID, research_name)
        if level > 0 then
            local ability_name = Upgrades:GetBaseAbilityName(research_name)
            if not self:HasAbility(ability_name..level) and self:BenefitsFrom(research_name) then
                self:AddAbility(ability_name..level):SetLevel(level)
                if wearable_type then
                    self:UpgradeWearables(wearable_type, level)
                end
            end
        end
    end
end

function CDOTA_BaseNPC_Creature:BenefitsFrom(research_name)
    local upgrades = self:GetKeyValue("Upgrades")
    if not upgrades then return false end

    -- Handle modifier requirements
    if upgrades["RequiresModifier"] then
        for name,modifier in pairs(upgrades["RequiresModifier"]) do
            if name == research_name and not self:HasModifier(modifier) then
                return false
            end
        end
    end

    return upgrades[research_name] ~= nil
end

-- Read the wearables.kv, check the unit name, swap all models to the correct level
function CDOTA_BaseNPC_Creature:UpgradeWearables(wearable_type, level)
    local unit_table = GameRules.Wearables[self:GetUnitName()]
    if unit_table then
        local sub_table = unit_table[wearable_type]
        if not sub_table then return end
        local wearables = self:GetChildren()
        for k,v in pairs(sub_table) do
            local original_wearable = v[tostring(0)]
            local old_wearable = v[tostring((level)-1)]
            local new_wearable = v[tostring(level)]
            
            for _,wearable in pairs(wearables) do
                if wearable:GetClassname() == "dota_item_wearable" then
                    -- Unit just spawned, it has the default weapon
                    if wearable:GetModelName() == original_wearable then
                        wearable:SetModel(new_wearable)

                    -- In this case, the unit is already on the field and might have an upgrade
                    elseif old_wearable and old_wearable == wearable:GetModelName() then
                        wearable:SetModel(new_wearable)
                    end
                end
            end
        end
    end
end

function CDOTA_BaseNPC:QuickPurge(bRemovePositiveBuffs, bRemoveDebuffs)
    self:Purge(bRemovePositiveBuffs, bRemoveDebuffs, false, false, false)
    self:RemoveModifierByName("modifier_brewmaster_storm_cyclone")
end

function CDOTA_BaseNPC:SetAttackRange(value)
    if self:HasModifier("modifier_attack_range") then self:RemoveModifierByName("modifier_attack_range") end
    self:AddNewModifier(self,nil,"modifier_attack_range",{range=value})
end


Units:start()