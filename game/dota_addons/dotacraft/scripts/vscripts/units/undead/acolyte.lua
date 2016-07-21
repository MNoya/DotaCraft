function unsummon (keys)
	local caster = keys.caster
	local target = keys.target
	local playerID = caster:GetPlayerOwnerID()
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()

	-- target is already unsummoning
	if target.unsummoning or not IsCustomBuilding(target) or caster:GetPlayerOwnerID() ~= target:GetPlayerOwnerID() or not target.constructionCompleted then
		SendErrorMessage(playerID, "#error_invalid_unsummon_target")
		return
	end

	-- set flag
	target.unsummoning = true
	
	-- damage taken by building per tick	
	local UNSUMMON_DAMAGE_PER_SECOND = keys.ability:GetSpecialValueFor("accumulation_step")
	
	-- 50% refund
	local goldcost = (0.5 * GetGoldCost(target))
	local lumbercost = (0.5 * GetLumberCost(target))
	
	-- calculate refund per tick
	local StepsNeededToUnsummon = target:GetMaxHealth() / 50
	local LumberGain = (lumbercost / StepsNeededToUnsummon)
	local GoldGain = (goldcost / StepsNeededToUnsummon)
	
	Timers:CreateTimer(function()
		if not IsValidEntity(target) then 
			return 
		end
		
		ParticleManager:CreateParticle("particles/base_destruction_fx/gbm_lvl3_glow.vpcf", 0, target)
		
		if target:GetHealth() <= 50 then -- refund resource + kill unit
			GiveResources(GoldGain, LumberGain, playerID)
			RemoveTarget(target)
		else -- refund resource + apply damage
			GiveResources(GoldGain, LumberGain, playerID)
			target:SetHealth(target:GetHealth() - UNSUMMON_DAMAGE_PER_SECOND)
		end

		return 1
	end)

end

function RemoveTarget(target)
	target:ForceKill(true)
	target:RemoveBuilding()
	target:SetAbsOrigin(Vector(0,0,-9000))
end

function GiveResources(gold, lumber, playerID)
	Players:ModifyGold(playerID, gold)
	Players:ModifyLumber(playerID, lumber)
end

function sacrifice ( keys )
	local target = keys.target
	local caster = keys.caster
	
	if caster:GetPlayerOwnerID() == target:GetPlayerOwnerID() and target:GetUnitName() == "undead_acolyte" then
	
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_sacrificing", nil) 
		target:MoveToPosition(caster:GetAbsOrigin())
		
		keys.ability.sacrifice = Timers:CreateTimer(function()
			if not IsValidEntity(target) or not IsValidEntity(caster) then
				return
			end
		
			local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
			
			
			if distance < 300 then
				print("in range")
				target:Stop()
				create_shade(keys)
			end
			
			return 1
		end)
		
	end
end

function create_shade(keys)
	local caster = keys.caster
	local target = keys.target
	local playerID = caster:GetPlayerOwnerID()
	local player = PlayerResource:GetPlayer(playerID)
	
	local shade = CreateUnitByName("undead_shade", target:GetAbsOrigin(), true, player:GetAssignedHero(),  player:GetAssignedHero(), caster:GetTeamNumber())
	shade:SetControllableByPlayer(playerID, true)
	
	target.no_corpse = true
	target:RemoveSelf()
end

function stop_sacrifice ( keys )
	local caster = keys.caster

	caster:RemoveModifierByName("modifier_sacrificing")	
	
	Timers:RemoveTimer(keys.ability.sacrifice)
end

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

	mine:RemoveModifierByName("modifier_unselectable")

	-- Stop all builders
	local builders = mine.builders
	for i=1,5 do	
		local acolyte
		if builders and #builders > 0 then
			acolyte = mine.builders[#builders]
			mine.builders[#builders] = nil
		else
			break
		end

		-- Cancel gather effects
		acolyte:RemoveModifierByName("modifier_on_order_cancel_gold")
		acolyte:RemoveModifierByName("modifier_gathering_gold")
		acolyte.state = "idle"

		local ability = acolyte:FindAbilityByName("undead_gather")
		ability.cancelled = true
		ToggleOff(ability)
	end

	if building.counter_particle then
		ParticleManager:DestroyParticle(building.counter_particle, true)
	end

     -- Set the area back to GoldMine squares
    BuildingHelper:BlockGridSquares(8, 0, building:GetAbsOrigin(), "GoldMine")

	building.sigil:RemoveSelf()
	building:AddNoDraw()

	mine.building_on_top = nil

	print("Removed Haunted Gold Mine successfully")
end