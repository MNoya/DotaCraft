--------------------------------
--       Repair Scripts       --
--------------------------------

function Repair(event)
    local caster = event.caster
    local target = event.target

    if IsValidRepairTarget(target, caster) then
        print("Repair.lua - Target: "..target:GetUnitName())
        caster:Interrupt()
        BuildingHelper:AddRepairToQueue(caster, target, false)
    end
end

function IsValidRepairTarget(target, builder)
    return target:GetClassname() == "npc_dota_creature" and (IsCustomBuilding(target) or IsMechanical(target)) and target:GetHealthPercent() < 100 and not target.unsummoning and not target.frozen
end

-- Right before starting to move towards the target building. 
function BuildingHelper:OnPreRepair(builder, building)
    self:print("OnPreRepair "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> "..building:GetUnitName().." "..building:GetEntityIndex())

    -- Return false to stop the repair process
end

-- As soon as the builder reaches the building
function BuildingHelper:OnRepairStarted(builder, building)
    self:print("OnRepairStarted "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> "..building:GetUnitName().." "..building:GetEntityIndex())

    local repair_ability = self:GetRepairAbility(builder)
    if repair_ability and repair_ability:GetToggleState() == false then
        repair_ability:ToggleAbility() -- Fake toggle the ability
    end

    if not building.construction_particle and GetUnitRace(building) == "human" and IsCustomBuilding(building) and building:IsUnderConstruction() then
        building.construction_particle = ParticleManager:CreateParticle("particles/custom/construction_dust.vpcf", PATTACH_ABSORIGIN_FOLLOW, building)
    end

    builder:StartGesture(ACT_DOTA_ATTACK)
    builder.repair_animation_timer = Timers:CreateTimer(function()
        if builder.state == "repairing" then
            builder:StartGesture(ACT_DOTA_ATTACK)
        end
        return 1
    end)
end

function BuildingHelper:OnRepairTick(building, hpGain, costFactor)
    -- Can pay the resource cost?
    -- Important: can repair allied resources?

    local playerID = building:GetPlayerOwnerID()
    local goldCost = building:GetKeyValue("GoldCost")
    local lumberCost = building:GetKeyValue("LumberCost")
    local buildTime = building:GetKeyValue("BuildTime")
    building.GoldAdjustment = building.GoldAdjustment or 0
    building.gold_used = 0
    building.lumber_used = 0

    -- Keep adding the floating point values every tick
    local pct_healed = hpGain / building:GetMaxHealth()
    local gold_tick = pct_healed * goldCost * costFactor
    local gold_float = gold_tick - math.floor(gold_tick)
    gold_tick = math.floor(gold_tick)

    -- Lumber is custom so we can get away with storing the floating point value
    local lumber_tick = pct_healed * lumberCost * costFactor

    if Players:HasEnoughGold(playerID, gold_tick+gold_float) and Players:HasEnoughLumber(playerID, lumber_tick) then
        building.GoldAdjustment = building.GoldAdjustment + gold_float
        if building.GoldAdjustment > 1 then
            Players:ModifyGold(playerID, -gold_tick - 1)
            building.GoldAdjustment = building.GoldAdjustment - 1
            building.gold_used = building.gold_used + gold_tick + 1

        else
            Players:ModifyGold(playerID, -gold_tick)
            building.gold_used = building.gold_used + gold_tick
        end
        
        Players:ModifyLumber(playerID, -lumber_tick)
        building.lumber_used = building.lumber_used + lumber_tick


    else
        building.gold_used = nil
        building.lumber_used = 0
        return false -- cancels the repair on all builders
    end
end

-- After an ongoing move-to-building or repair process is cancelled
function BuildingHelper:OnRepairCancelled(builder, building)
    self:print("OnRepairCancelled "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> "..building:GetUnitName().." "..building:GetEntityIndex())

    if builder.repair_animation_timer then
        builder:RemoveGesture(ACT_DOTA_ATTACK)
        Timers:RemoveTimer(builder.repair_animation_timer)
    end

    if building.construction_particle and BuildingHelper:GetNumBuildersRepairing(building) == 0 then 
        ParticleManager:DestroyParticle(building.construction_particle, false)
        building.construction_particle = nil
    end
end

-- After a building is fully constructed via repair ("RequiresRepair" buildings), or is fully repaired
function BuildingHelper:OnRepairFinished(builder, building)
    self:print("OnRepairFinished "..builder:GetUnitName().." "..builder:GetEntityIndex().." -> "..building:GetUnitName().." "..building:GetEntityIndex())

    if builder.repair_animation_timer then 
        builder:RemoveGesture(ACT_DOTA_ATTACK)
        Timers:RemoveTimer(builder.repair_animation_timer)
    end

    if building.construction_particle and BuildingHelper:GetNumBuildersRepairing(building) == 0 then 
        ParticleManager:DestroyParticle(building.construction_particle, false)
        building.construction_particle = nil
    end
end