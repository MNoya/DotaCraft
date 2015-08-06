function RootStart( event )
	print("Root Start")
	local caster = event.caster
	
	caster:StartGesture(ACT_DOTA_CAST_ABILITY_5) --Treant protector overgrowth
	caster:RemoveModifierByName("modifier_uprooted")
	caster:SwapAbilities("nightelf_uproot", "nightelf_root", true, false)
	caster:FindAbilityByName("nightelf_root"):SetLevel(1)

	-- Apply rooted particles
	local uproot_ability = caster:FindAbilityByName("nightelf_uproot")
	uproot_ability:ApplyDataDrivenModifier(caster, caster, "modifier_rooted_ancient", {})

	-- Block the area
	local location = caster:GetAbsOrigin()
	local size = 5
	local gridNavBlockers = BuildingHelper:BlockGridNavSquare(size, location)
    
    caster.blockers = gridNavBlockers
    caster:SetAbsOrigin(location)

    caster:AddAbility("ability_building")
	caster:AddAbility("ability_building_queue")
	caster:FindAbilityByName("ability_building"):SetLevel(1)
	caster:FindAbilityByName("ability_building_queue"):SetLevel(1)

	local ability = event.ability
	local cast_time = 2--ability:GetCastPoint()
	Timers:CreateTimer(cast_time, function()
		print("Root End")

		-- Show all train and research abilities
		for i=0,15 do
			local ability = caster:GetAbilityByIndex(i)
			if ability then
				if ability:IsHidden() and ( string.match(ability:GetAbilityName(), "train_") or string.match(ability:GetAbilityName(), "research_")) then
					ability:SetHidden(false)
				elseif ability:GetAbilityName() == "nightelf_eat_tree" then
					ability:SetHidden(true)
				end
			end
		end

		-- Look for a gold mine to entangle if its a tree of Life/Ages/Eternity
		local unitName = caster:GetUnitName()
		if (unitName == "nightelf_tree_of_life" or unitName == "nightelf_tree_of_ages" or unitName == "nightelf_tree_of_eternity") then
			local closest_mine = GetClosestGoldMineToPosition(location)
			if caster:GetRangeToUnit(closest_mine) <= 900 and not closest_mine.building_on_top then
				event.target = closest_mine
				EntangleGoldMine(event)
			end
		end
	end)
end

function UpRootStart( event )
	print("UpRoot Start")
	local caster = event.caster
	if caster:HasModifier("modifier_construction") then
		print("Stop, this ancient is in construction")
		caster:Stop()
		return
	end

	caster:RemoveAbility("ability_building")
	caster:RemoveAbility("ability_building_queue")
	caster:RemoveModifierByName("modifier_building_queue")
	caster:RemoveBuilding( false )

	if IsValidEntity(caster.entangled_gold_mine) then
		caster.entangled_gold_mine:RemoveModifierByName("modifier_entangled_mine")
	end
end

function UpRoot( event )
	print("Finish UpRooting")
	local caster = event.caster

	-- Specific to the night elf tower unit: Reduce its damage by 20, (1.5 BAT) and make it melee (128 range)
	if caster:GetUnitName() == "nightelf_ancient_protector" then
		caster:RemoveAbility("ability_tower")
		caster:RemoveModifierByName("modifier_tower")

		event.ability:ApplyDataDrivenModifier(caster, caster, "modifier_uprooted_ancient_protector", {})
		caster:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
	end

	caster:RemoveModifierByName("modifier_building")

	-- There's no way to change the armor/unit type...
	
	if not caster:HasAbility("nightelf_root") then
		caster:AddAbility("nightelf_root")
	end
	caster:FindAbilityByName("nightelf_root"):SetLevel(1)
	caster:SwapAbilities("nightelf_uproot", "nightelf_root", false, true)

	if caster.flag and IsValidEntity(caster.flag) then
		caster.flag:RemoveSelf()
	end

	-- Hide all train and research abilities, show eat tree
	for i=0,15 do
		local ability = caster:GetAbilityByIndex(i)
		if ability then
			if ( string.match(ability:GetAbilityName(), "train_") or string.match(ability:GetAbilityName(), "research_")) then
				ability:SetHidden(true)
			elseif ability:GetAbilityName() == "nightelf_eat_tree" or ability:GetAbilityName() == "nightelf_entangle_gold_mine" then
				ability:SetHidden(false)
			end
		end
	end

	-- Remove the rooted particle
	caster:RemoveModifierByName("modifier_rooted_ancient")

	-- Cancel anything on the buildings queue
	for j=0,5 do
		local item = caster:GetItemInSlot(j)
		if item and IsValidEntity(item) then
			caster:CastAbilityImmediately(item, caster:GetPlayerOwnerID())
		end
	end
	-- Gotta remove one extra time for some reason
	local item = caster:GetItemInSlot(0)
	if item then
		caster:CastAbilityImmediately(item, caster:GetPlayerOwner():GetEntityIndex())
	end

end

-- Roots the tree next to a gold mine and starts the construction of a entangled mine
function EntangleGoldMine( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	if target:GetUnitName() ~= "gold_mine" then
		print("Must target a gold mine")
		return
	else
		if caster:HasModifier("modifier_uprooted") then
			RootStart(event)
		else
			print("Begining construction of a Entangled Gold Mine")

			-- Show passive indicating this ancient has a gold mine entangled
			caster:SwapAbilities("nightelf_entangle_gold_mine", "nightelf_entangle_gold_mine_passive", false, true)

			local player = caster:GetPlayerOwner()
			local hero = player:GetAssignedHero()
			local playerID = player:GetPlayerID()
			local mine_pos = target:GetAbsOrigin()

			local building = CreateUnitByName("nightelf_entangled_gold_mine", mine_pos, false, hero, hero, hero:GetTeamNumber())
			building:SetOwner(hero)
			building:SetControllableByPlayer(playerID, true)
			building.state = "building"

			local entangle_ability = caster:FindAbilityByName("nightelf_entangle_gold_mine")
			local build_time = entangle_ability:GetSpecialValueFor("build_time")
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
						building.builders = {} -- The builders list on the entangled gold mine
						RemoveConstructionEffect(building)

	        			building.constructionCompleted = true
	       				building.state = "complete"

	       				return
	        		end
	    		
	    		else
	      			-- Building destroyed
	      			print("Entangled gold mine was destroyed during the construction process!")

	                return
	    		end
	    		return update_health_interval
	 		end)
	 		---------------------------------

			building.mine = target -- A reference to the mine that the entangled mine is associated with
			building.city_center = caster -- A reference to the city center that entangles this mine
			caster.entangled_gold_mine = building -- A reference to the entangled building of the city center
			target.building_on_top = building -- A reference to the building that entangles this gold mine
		end
	end
end

-- Makes the mine pseudo invisible
function HideGoldMine( event )
	Timers:CreateTimer(function() 
		local building = event.caster
		local ability = event.ability
		local mine = building.mine -- This is set when the building is built on top of the mine

		mine:AddNoDraw()
		building:SetForwardVector(mine:GetForwardVector())
		ability:ApplyDataDrivenModifier(building, mine, "modifier_unselectable_mine", {})

	end)
end

-- Show the mine (when killed either through uprooting or attackers)
function ShowGoldMine( event )
	local building = event.caster
	local ability = event.ability
	local mine = building.mine
	local city_center = building.city_center

	print("Removing Entangled Gold Mine")

	mine:RemoveNoDraw()
	mine:RemoveModifierByName("modifier_unselectable_mine")

	-- Eject all wisps 
	local builders = mine.builders
	for i=1,5 do	
		local wisp
		if builders and #builders > 0 then
			wisp = mine.builders[#builders]
			mine.builders[#builders] = nil
		else
			break
		end

		FindClearSpaceForUnit(wisp, mine.entrance, true)

		-- Cancel gather effects
		wisp:RemoveModifierByName("modifier_on_order_cancel_gold")
		wisp:RemoveModifierByName("modifier_gathering_gold")
		wisp.state = "idle"

		local ability = wisp:FindAbilityByName("nightelf_gather")
		ability.cancelled = true
		ToggleOff(ability)
	end

	if building.counter_particle then
		ParticleManager:DestroyParticle(building.counter_particle, true)
	end

	building:RemoveSelf()

	city_center.entangled_gold_mine = nil

	-- Show an ability to re-entangle a gold mine on the city center if it is still rooted
	city_center:SwapAbilities("nightelf_entangle_gold_mine", "nightelf_entangle_gold_mine_passive", true, false)

	mine.building_on_top = nil

	print("Removed Entangled Gold Mine successfully")
end

-- Orders a wisp to use its gather ability on this entangled gold mine
function LoadWisp( event )
	local caster = event.caster --The entangled gold mine
	local target = event.target

	if target:GetUnitName() ~= "nightelf_wisp" then
		print("Must target a wisp")
		return
	else
		local gather = target:FindAbilityByName("nightelf_gather")
		if gather and gather:IsFullyCastable() then
			ExecuteOrderFromTable({ UnitIndex = target:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_TARGET, TargetIndex = caster:GetEntityIndex(), AbilityIndex = gather:GetEntityIndex(), Queue = false}) 
		end
	end
end

-- Ejects the first wisp on the mine.builders
function UnloadWisp( event )
	local caster = event.caster
	local mine = caster.mine
	local builders = mine.builders

	local wisp
	if builders and #builders > 0 then
		wisp = mine.builders[#builders]
		mine.builders[#builders] = nil
	else
		return
	end

	FindClearSpaceForUnit(wisp, mine.entrance, true)

	-- Cancel gather effects
	wisp:RemoveModifierByName("modifier_on_order_cancel_gold")
	wisp:RemoveModifierByName("modifier_gathering_gold")
	wisp.state = "idle"

	local ability = wisp:FindAbilityByName("nightelf_gather")
	ability.cancelled = true
	ToggleOff(ability)

	-- Set gold mine counter
	local entangled_gold_mine = mine.building_on_top
	local count = #builders
	print(count,"builders left inside ", entangled_gold_mine:GetUnitName())
	for i=count+1,5 do
		ParticleManager:SetParticleControl(entangled_gold_mine.counter_particle, i, Vector(0,0,0))
	end
end


function UnloadAll( event )
	for i=1,5 do
		Timers:CreateTimer(0.03*i, function() 
			UnloadWisp(event)
		end)
	end
end



-- Applies natures blessing bonus with ancient protector exception
function NaturesBlessing( event )
	local building = event.caster
	local ability = event.ability

	if building:GetUnitName() == "nightelf_ancient_protector" then
		ability:ApplyDataDrivenModifier(building, building, "modifier_natures_blessing_tower", {})
	else
		ability:ApplyDataDrivenModifier(building, building, "modifier_natures_blessing_tree", {})
	end

end

-- Cuts down a tree
function EatTree( event )	
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	caster:StartGesture(ACT_DOTA_ATTACK)
	
	Timers:CreateTimer(0.5, function()
		target:CutDown(caster:GetTeamNumber())
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_leech_seed.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 3, target:GetAbsOrigin())
	end)

	Timers:CreateTimer(1, function()
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_eat_tree", {})
	end)
end