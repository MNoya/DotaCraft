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

	local ability = event.ability
	local cast_time = 2--ability:GetCastPoint()
	Timers:CreateTimer(cast_time, function()
		print("Root End")

		caster:AddAbility("ability_building")
		caster:AddAbility("ability_building_queue")
		caster:FindAbilityByName("ability_building"):SetLevel(1)
		caster:FindAbilityByName("ability_building_queue"):SetLevel(1)

		-- Show all train and research abilities
		for i=0,15 do
			local ability = caster:GetAbilityByIndex(i)
			if ability then
				if ability:IsHidden() and ( string.match(ability:GetAbilityName(), "train_") or string.match(ability:GetAbilityName(), "research_")) then
					ability:SetHidden(false)
				elseif ability:GetAbilityName() == "nightelf_eat_tree" or ability:GetAbilityName() == "nightelf_entangle_gold_mine" then
					ability:SetHidden(true)
				end
			end
		end

		-- Look for a gold mine to entangle
		local closest_mine = GetClosestGoldMineToPosition(location)
		print(caster:GetRangeToUnit(closest_mine))
		if caster:GetRangeToUnit(closest_mine) <= 900 and not closest_mine.building_on_top then

			-- Entangle the closest gold mine
			local player = caster:GetPlayerOwner()
			local hero = player:GetAssignedHero()
			local playerID = player:GetPlayerID()
			local closest_mine_pos = closest_mine:GetAbsOrigin()
			local entangled_gold_mine = CreateUnitByName("nightelf_entangled_gold_mine", closest_mine_pos, false, hero, hero, hero:GetTeamNumber())
			entangled_gold_mine:SetOwner(hero)
			entangled_gold_mine:SetControllableByPlayer(playerID, true)

			entangled_gold_mine.mine = closest_mine -- A reference to the mine that the entangled mine is associated with
			caster.entangled_gold_mine = entangled_gold_mine -- A reference to the entangled building of the city center
			closest_mine.building_on_top = entangled_gold_mine -- A reference to the building that entangles this gold mine
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
	caster:RemoveModifierByName("modifier_building")
	caster:RemoveAbility("ability_building_queue")
	caster:RemoveModifierByName("modifier_building_queue")
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

	-- BuildingHelper (There is a problem with Base upgrades, need to handle that later...)
	caster:RemoveBuilding( false )

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

	-- Kill the entangled gold mine and eject the wisps
	if caster.entangled_gold_mine and IsValidEntity(caster.entangled_gold_mine) then
		print("Removing Entangled Gold Mine")

		--nightelf_unload_all

		ShowGoldMine(event)

	end
end

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

-- Uproots the tree next to a gold mine
function EntangleGoldMine( event )
	local target = event.target

	if target:GetUnitName() ~= "gold_mine" then
		print("Must target a gold mine")
		return
	else
		RootStart(event)
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
		print(building:GetUnitName(), mine:GetUnitName())

	end)
end

-- Show it back
function ShowGoldMine( event )
	local caster = event.caster
	local mine = caster.entangled_gold_mine.mine

	mine:RemoveNoDraw()
	mine:RemoveModifierByName("modifier_unselectable_mine")
	ParticleManager:DestroyParticle(mine.counter_particle, true)
	caster.entangled_gold_mine:RemoveSelf()

	caster.entangled_gold_mine = nil
	mine.building_on_top = nil
end

-- Once the entangled mine has finished building
function GoldMineCounter( event )
	Timers:CreateTimer(function() 
		local building = event.caster
		local mine = building.mine
		mine.counter_particle = ParticleManager:CreateParticle("particles/custom/gold_mine_counter.vpcf", PATTACH_CUSTOMORIGIN, mine)
		local pos = mine:GetAbsOrigin()
		ParticleManager:SetParticleControl(mine.counter_particle, 0, Vector(pos.x,pos.y,pos.z+200))
	end)
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
	ToggleOn(ability)
end


function UnloadAll( event )
	for i=1,5 do
		Timers:CreateTimer(0.03*i, function() 
			UnloadWisp(event)
		end)
	end
end