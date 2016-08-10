if not Upgrades then
    Upgrades = class({})
end

Upgrades.Debug = false
function Upgrades:Init()
    self.Requirements = LoadKeyValues("scripts/kv/tech_tree.kv")
end

-------------------------------------------------------------

-- Go through every ability and check if the requirements are met
-- Swaps abilities with _disabled to their non disabled version and viceversa
-- This is called in multiple events:
    -- On every unit & building after ResearchComplete or after a building is destroyed
    -- On single unit after spawning in MoveToRallyPoint
    -- On single building after spawning in OnConstructionStarted
function CheckAbilityRequirements( unit, playerID )

    local requirements = GameRules.Requirements
    local buildings = Players:GetBuildingTable(playerID)
    local upgrades = Players:GetUpgradeTable(playerID)
    local units = Players:GetUnits(playerID)
    local structures = Players:GetStructures(playerID)

    -- The disabled abilities end with this affix
    local len = string.len("_disabled")

    if IsValidEntity(unit) then
        -- Check the Researches for this player, adjusting the abilities that have been already upgraded
        CheckResearchRequirements( unit, playerID )

        for abilitySlot=0,15 do
            local ability = unit:GetAbilityByIndex(abilitySlot)

            -- If the ability exists
            if ability and IsValidEntity(ability) then
                local ability_name = ability:GetAbilityName()
                local disabled = false

                if ability:IsDisabled() then
                    -- Cut the disabled part from the name to check the requirements
                    ability_name = ability_name:gsub("_disabled","")
                    disabled = true
                end

                -- Check if it has requirements on the KV table
                local player_has_requirements = Players:HasRequirementForAbility(playerID, ability_name)
                
                if disabled then
                    if player_has_requirements then
                        ability:Enable()
                    end
                else
                    if not player_has_requirements then
                        ability:Disable()
                    end
                end
            end
        end
    else
        print("ERROR, called CheckAbilityRequirements on a invalid unit. Fixing all tables...")
        Players:FixAllTables(playerID)
    end    
end

-- In addition and run just before CheckAbilityRequirements, when a building starts construction
-- this will swap to the correct rank of each research_ or remove it if the max rank has been detected
function CheckResearchRequirements(unit, playerID)
    if not IsCustomBuilding(unit) then return end -- Only buildings have research abilities
    for abilitySlot=0,15 do
        local ability = unit:GetAbilityByIndex(abilitySlot)

        if ability and ability:IsResearch() then
            local ability_name = ability:GetAbilityName()
            local research_name = Upgrades:GetBaseResearchName(ability_name)

            if Players:HasResearch(playerID, research_name) then
                local current_research_rank = Players:GetCurrentResearchRank(playerID, research_name)
                local max_research_rank = Upgrades:GetMaxResearchRank(research_name)
                if max_research_rank > 1 and current_research_rank < max_research_rank then
                    local next_rank = tostring(current_research_rank + 1)
                    local new_research_name = research_name..next_rank
                    if not unit:HasAbility(new_research_name) then
                        local new_ability = unit:AddAbility(new_research_name)
                        unit:SwapAbilities(ability_name, new_research_name, false, true)
                        unit:RemoveAbility(ability_name)
                        new_ability:SetLevel(new_ability:GetMaxLevel())
                    end
                else
                    -- Max Rank researched. Remove it
                    ability:SetHidden(true)
                    unit:RemoveAbility(ability_name)                            
                end
            end
        end
    end
end

-- This function is called on every unit after ResearchComplete
function UpdateUnitUpgrades(unit, playerID, research_name)
    if not IsValidEntity(unit) then return end    
    local unit_name = unit:GetUnitName()
    local upgrades = Players:GetUpgradeTable(playerID)

    -- Research name is "(race)_research_(name)(rank)"
    -- The ability name is "(race)_(name)", so we need to  cut it accordingly
    
    local ability_name = Upgrades:GetBaseAbilityName(research_name)
    local rank = Players:GetCurrentResearchRank(playerID, research_name)

    if unit:BenefitsFrom(research_name) then
        if not rank then
            rank = 1

        -- If the unit already has a previous rank, remove it
        elseif rank > 1 then
            local old_rank = rank-1
            local old_ability_name = ability_name..old_rank
            local old_ability = unit:FindAbilityByName(old_ability_name)
            local new_ability_name = ability_name..rank

            -- Remove any of the modifiers before reapplying
            -- This is necessary because removing the ability doesn't remove the passive modifiers
            unit:RemoveModifiersAssociatedWith(old_ability_name)

            local new_ability = unit:AddAbility(new_ability_name)
            unit:SwapAbilities(old_ability_name, new_ability_name, false, true)
            unit:RemoveAbility(old_ability_name)
            new_ability:SetLevel(rank)
        
        -- If its the first rank of the ability, simply add it
        elseif rank == 1 then
            -- Learn the rank 1 ability
            local new_ability_name = ability_name..rank
            local new_ability = unit:AddAbility(new_ability_name)
            new_ability:SetLevel(rank)
        end

        -- Update cosmetics of the unit if possible
        local wearable_upgrade_type = unit:GetWearableType(research_name)
        if wearable_upgrade_type then
            unit:UpgradeWearables(wearable_upgrade_type, rank)
            -- Update rider cosmetics if there is possible
            if unit.rider then
                unit.rider:UpgradeWearables(wearable_upgrade_type, rank)
            end
        end
    end
end

-------------------------------------------------------------

function CDOTABaseAbility:Enable()
    local unit = self:GetCaster()
    local disabled_ability_name = self:GetAbilityName()
    local enabled_ability_name = disabled_ability_name:gsub("_disabled","")
    local ability = unit:AddAbility(enabled_ability_name)
    unit:SwapAbilities(disabled_ability_name, enabled_ability_name, false, true)
    unit:RemoveAbility(disabled_ability_name)
    ability:SetLevel(ability:GetMaxLevel())
    if ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_AUTOCAST) then
        unit.autocast_abilities = unit.autocast_abilities or {}
        table.insert(unit.autocast_abilities, ability)
    end
end

function CDOTABaseAbility:Disable()
    local unit = self:GetCaster()
    local enabled_ability_name = self:GetAbilityName()
    local disabled_ability_name = enabled_ability_name.."_disabled"
    unit:AddAbility(disabled_ability_name):SetLevel(0)                   
    unit:SwapAbilities(enabled_ability_name, disabled_ability_name, false, true)
    unit:RemoveAbility(enabled_ability_name)
end

function CDOTABaseAbility:IsResearch()
    return self:GetAbilityName():match("research_")
end

-- By default, all abilities that have a requirement start as _disabled
-- This is to prevent applying passive modifier effects that have to be removed later
-- The disabled ability is just a dummy for tooltip, precache and level 0.
-- Check if the ability is disabled or not
function CDOTABaseAbility:IsDisabled()
    return Upgrades:IsDisabled(self:GetAbilityName())
end

-- Abilities with multiple ranks have [123] at the end of their name
function CDOTABaseAbility:HasRankInName()
    return Upgrades:HasRankInName(self:GetAbilityName())
end

-- Returns string with the "short" ability name, without any rank or suffix
function CDOTABaseAbility:GetBaseAbilityName()
    return Upgrades:GetBaseAbilityName(self:GetAbilityName())
end

function CDOTA_BaseNPC:GetWearableType(name)
    local upgrades = self:GetKeyValue("Upgrades")
    if not upgrades then return end
    return upgrades[name]
end

-------------------------------------------------------------

function Upgrades:IsDisabled(name)
    return name:match("_disabled")
end

-- Abilities with multiple ranks have [123] at the end of their name
function Upgrades:HasRankInName(name)
    return tonumber(name:sub(name:len(),name:len())) -- last digit can be a letter (nil number) or a number
end

function Upgrades:GetBaseAbilityName(name)
    if self:IsDisabled(name) then
        name = name:gsub("_disabled", "")
    end
    local rank = self:HasRankInName(name)
    if rank then
        name = name:sub(1,name:len()-1) -- cut last digit
    end
    return name:gsub("_research", "")
end

function Upgrades:GetBaseResearchName(name)
    if self:IsDisabled(name) then
        name = name:gsub("_disabled", "")
    end
    local rank = self:HasRankInName(name)
    if rank then
        name = name:sub(1,name:len()-1) -- cut last digit
    end
    return name
end

-- Returns int, 0 if it doesnt exist
function Upgrades:GetMaxResearchRank(research_name)
    local rank = 0
    for i=1,3 do
        if GetKeyValue(research_name..i) then
            rank = i
        end
    end
    return rank
end

if not Upgrades.Players then Upgrades:Init() end