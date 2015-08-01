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
			GiveResources(GoldGain, LumberGain, hero)
			RemoveTarget(target)
		else -- refund resource + apply damage
			GiveResources(GoldGain, LumberGain, hero)
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

function GiveResources(gold, lumber, hero)
	hero:ModifyGold(gold, true, 0)
	ModifyLumber(hero:GetPlayerOwner(), lumber)
end

function HauntGoldMine( event )

	local caster = event.caster
	local target = event.target
	local ability = event.ability

	if target:GetUnitName() ~= "gold_mine" then
		print("Must target a gold mine")
		--refund gold_cost lumber_cost
		return
	else
		print("Begining construction of a Haunted Gold Mine")

		local player = caster:GetPlayerOwner()
		local hero = player:GetAssignedHero()
		local playerID = player:GetPlayerID()
		local mine_pos = target:GetAbsOrigin()

		local building = CreateUnitByName("undead_haunted_gold_mine", mine_pos, false, hero, hero, hero:GetTeamNumber())
		building:SetOwner(hero)
		building:SetControllableByPlayer(playerID, true)
		building.state = "building"

		local ability = event.ability
		local build_time = ability:GetSpecialValueFor("build_time")
		local hit_points = building:GetMaxHealth()

		-- Start building construction ---
		local initial_health = 0.10 * hit_points
		local time_completed = GameRules:GetGameTime()+build_time
		local update_health_interval = build_time / math.floor(hit_points-initial_health) -- health to add every tick
		building:SetHealth(initial_health)
		building.bUpdatingHealth = true

		-- Particle effect
    	ApplyConstructionEffect(building)

		building.updateHealthTimer = Timers:CreateTimer(function()
    		if IsValidEntity(building) and building:IsAlive() then
      			local timesUp = GameRules:GetGameTime() >= time_completed
      			if not timesUp then
        			if building.bUpdatingHealth then
          				if building:GetHealth() < hit_points then
            				building:SetHealth(building:GetHealth() + 1)
          				else
            				building.bUpdatingHealth = false
         				end
        			end
      			else
        			-- Show the gold counter and initialize the mine builders list
					building.counter_particle = ParticleManager:CreateParticle("particles/custom/gold_mine_counter.vpcf", PATTACH_CUSTOMORIGIN, building)
					ParticleManager:SetParticleControl(building.counter_particle, 0, Vector(mine_pos.x,mine_pos.y,mine_pos.z+200))
					building.builders = {} -- The builders list on the haunted gold mine
					RemoveConstructionEffect(building)

        			building.constructionCompleted = true
       				building.state = "complete"

       				return
        		end
    		
    		else
      			-- Building destroyed
      			print("Haunted gold mine was destroyed during the construction process!")

                return
    		end
    		return update_health_interval
 		end)
 		---------------------------------

		building.mine = target -- A reference to the mine that the haunted mine is associated with
		target.building_on_top = building -- A reference to the building that haunts this gold mine
	end
end

-- Makes the mine pseudo invisible
function HideGoldMine( event )
	Timers:CreateTimer(0.05, function() 
		local building = event.caster
		local ability = event.ability
		local mine = building.mine -- This is set when the building is built on top of the mine

		--building:SetForwardVector(mine:GetForwardVector())
		ability:ApplyDataDrivenModifier(mine, mine, "modifier_unselectable_mine", {})

		local pos = mine:GetAbsOrigin()
		building.sigil = Entities:CreateByClassname("prop_dynamic")
		building.sigil:SetAbsOrigin(Vector(pos.x, pos.y, pos.z-60))
		building.sigil:SetModel("models/props_magic/bad_sigil_ancient001.vmdl")
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

	mine:RemoveModifierByName("modifier_unselectable_mine")

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

	building.sigil:RemoveSelf()
	building:RemoveSelf()

	mine.building_on_top = nil

	print("Removed Haunted Gold Mine successfully")
end

