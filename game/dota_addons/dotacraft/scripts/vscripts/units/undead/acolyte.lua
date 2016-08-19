function unsummon(keys)
    local caster = keys.caster
    local target = keys.target
    if caster:GetPlayerOwnerID() == target:GetPlayerOwnerID() then
       Unsummon(target, function() print("Finished unsummon") end)
    end
end

------------------------------------------------------------------------------

function Sacrifice(event)
    local target = event.target
    local caster = event.caster
    local ability = event.ability
    local playerID = caster:GetPlayerOwnerID()
    local buildingOrigin = caster:GetAbsOrigin()

    if ability.acolyte then
        SendErrorMessage(playerID, "error_already_sacrificing")
        return
    else
        caster:Stop()
    end
    
    if playerID == target:GetPlayerOwnerID() and target:GetUnitName() == "undead_acolyte" then
        ability:ApplyDataDrivenModifier(caster, target, "modifier_sacrificing", {}) 
        target:MoveToPosition(caster:GetAbsOrigin())
        
        target.sacrifice_MoveTimer = Timers:CreateTimer(0.03, function()
            if not IsValidAlive(target) or not IsValidAlive(caster) then return end
            if ability.acolyte then -- another targeted acolyte entered the pit earlier
                target:Stop()
                return
            end
        
            local distance = (target:GetAbsOrigin() - buildingOrigin):Length2D()            
            
            if distance < 300 then
                target:Stop()

                -- Start sacrifice
                ability.acolyte = target
                ability.acolyte_entrance = target:GetAbsOrigin()
                ability:SetChanneling(true)
                target:AddNoDraw()
                target:RemoveModifierByName("modifier_sacrificing")
                target:AddNewModifier(caster,ability,"modifier_builder_hidden",{})
                target:SetAbsOrigin(buildingOrigin)
                ability.queue_item = caster:AddItem(CreateItem("item_undead_shade_sacrifice",caster,caster))

                -- Sacrifice wasn't cancelled
                Timers:CreateTimer(ability:GetChannelTime(), function()
                    if IsValidAlive(caster) and IsValidEntity(ability.queue_item) then
                        ability:EndChannel(false)
                    end
                end)
                return
            end
            
            return 1
        end)
        
    end
end

-- Cancel an ongoing sacrifice, via item queue cancel
function CancelSacrifice(event)
    local caster = event.caster
    local item = event.ability
    local ability = caster:FindAbilityByName("undead_train_shade")
    ability:EndChannel(true)

    local acolyte = ability.acolyte
    acolyte:SetAbsOrigin(ability.acolyte_entrance)
    acolyte:RemoveModifierByName("modifier_builder_hidden")
    acolyte:RemoveNoDraw()
    ability.acolyte = nil

    UTIL_Remove(item)
end

-- Stop moving an acolyte to sacrifice
function StopSacrifice(event)
    local target = event.unit
    target:RemoveModifierByName("modifier_sacrificing") 
    if target.sacrifice_MoveTimer then
        Timers:RemoveTimer(target.sacrifice_MoveTimer)
    end
end

function CreateShade(event)
    local caster = event.caster
    local ability = event.ability
    local playerID = caster:GetPlayerOwnerID()
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    -- Remove the acolyte
    local acolyte = ability.acolyte
    acolyte:ForceKill(true)
    acolyte:AddNoDraw()
    ability.acolyte = nil
    UTIL_Remove(ability.queue_item)
    ability.queue_item = nil

    local shade = CreateUnitByName("undead_shade", caster:GetAbsOrigin(), true, hero,  hero, caster:GetTeamNumber())
    shade:SetControllableByPlayer(playerID, true)
    shade:AddNewModifier(caster, nil, "modifier_phased", { duration = 0.03 })
    shade:SetOwner(hero)
    shade:SetControllableByPlayer(playerID, true)
    shade:SetNoCorpse()
    
    dotacraft:ResolveRallyPointOrder(shade, caster)

    Players:ModifyFoodUsed(playerID, 1)
    Players:AddUnit(playerID, shade)
end

------------------------------------------------------------------------------

function HauntGoldMine( event )
    local ability = event.ability
    local caster = event.caster
    local playerID = caster:GetPlayerOwnerID()
    local teamNumber = caster:GetTeamNumber()
    local building_name = "undead_haunted_gold_mine"
    local construction_size = BuildingHelper:GetConstructionSize(building_name)
    local gold_cost = ability:GetSpecialValueFor("gold_cost")
    local lumber_cost = ability:GetSpecialValueFor("lumber_cost")

    Players:ModifyGold(playerID, gold_cost)

    if not Players:HasEnoughLumber( playerID, lumber_cost ) then
        return
    end

    BuildingHelper:AddBuilding(event)
    
    -- Callbacks
    event:OnPreConstruction(function(vPos)
        -- Building check
        local target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
        local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
        local units = FindUnitsInRadius(teamNumber, vPos, nil, construction_size, DOTA_UNIT_TARGET_TEAM_BOTH, target_type, flags, FIND_ANY_ORDER, false)
        for _,v in pairs(units) do
            if IsCustomBuilding(v) then
                SendErrorMessage(playerID, "#error_invalid_build_position")
                return false
            end
        end

        return true
    end)

    -- Position for a building was confirmed and valid
    event:OnBuildingPosChosen(function(vPos) return true end)

    event:OnConstructionFailed(function()
        SendErrorMessage(playerID, "#error_invalid_build_position")
    end)

    event:OnConstructionCancelled(function(work)
        -- Refund resources for this cancelled work
        if work.refund then
            Players:ModifyGold(playerID, gold_cost)
            Players:ModifyLumber(playerID, lumber_cost)
        end
    end)

    event:OnConstructionStarted(function(unit)

        caster:StartGesture(ACT_DOTA_ATTACK)

        -- Give item to cancel
        local item = CreateItem("item_building_cancel", playersHero, playersHero)
        unit:AddItem(item)

        -- Hide the targeted gold mine
        local units = FindUnitsInRadius(unit:GetTeamNumber(), unit:GetAbsOrigin(), nil, 100, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE+DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
        local mine = units[1]
        unit.mine = mine -- A reference to the mine that the haunted mine is associated with
        mine.building_on_top = unit -- A reference to the building that haunts this gold mine
        HideGoldMine({caster = unit})
        unit:SetMana(mine:GetHealth())

        -- Particle effect
        ApplyModifier(unit, "modifier_construction")

        -- Add the building handle to the list of structures
        Players:AddStructure(playerID, unit)


    end)

    event:OnConstructionCompleted(function(unit)

        -- Show the gold counter and initialize the mine builders list
        local mine_pos = unit.mine:GetAbsOrigin()
        unit.counter_particle = ParticleManager:CreateParticle("particles/custom/gold_mine_counter.vpcf", PATTACH_CUSTOMORIGIN, unit)
        ParticleManager:SetParticleControl(unit.counter_particle, 0, Vector(mine_pos.x,mine_pos.y,mine_pos.z+200))
        unit.builders = {} -- The builders list on the haunted gold mine

        -- Let the building cast abilities
        unit:RemoveModifierByName("modifier_construction")

        -- Remove item_building_cancel and reorder
        RemoveItemByName(unit, "item_building_cancel")

        -- Add blight
        Blight:Create(unit, "small")
    end)
end

-- Makes the mine unselectable and adds props
function HideGoldMine( event )
    if not event.caster.state then return end --Exit out on building dummy

    Timers:CreateTimer(0.05, function() 
        local building = event.caster
        local mine = building.mine -- This is set when the building is built on top of the mine

        --building:SetForwardVector(mine:GetForwardVector())
        ApplyModifier(mine, "modifier_unselectable")

        local pos = mine:GetAbsOrigin()
        local modelName = "models/props_magic/bad_sigil_ancient001.vmdl"
        building.sigil = SpawnEntityFromTableSynchronous("prop_dynamic", {model = modelName, DefaultAnim = 'bad_sigil_ancient001_rotate'})
        building.sigil:SetAbsOrigin(Vector(pos.x, pos.y, pos.z-60))
        building.sigil:SetModelScale(building:GetModelScale())

        print("Hide Gold Mine")
    end)
end

-- Show the mine (when killed either through unsummoning or attackers)
function ShowGoldMine( event )
    local building = event.caster
    local ability = event.ability
    local mine = building.mine
    local city_center = building.city_center

    print("Removing Haunted Gold Mine")
    mine:RemoveNoDraw()
    mine:RemoveModifierByName("modifier_unselectable")

    -- Stop all builders
    local acolytes = mine:GetGatherers()
    for _,acolyte in pairs(acolytes) do
        acolyte:CancelGather()
    end

    if building.counter_particle then
        ParticleManager:DestroyParticle(building.counter_particle, true)
    end

    -- Set the area back to GoldMine squares
    BuildingHelper:BlockGridSquares(8, 0, building:GetAbsOrigin(), "GoldMine")
    building:AddNoDraw()
    mine.building_on_top = nil

    print("Removed Haunted Gold Mine successfully")
end