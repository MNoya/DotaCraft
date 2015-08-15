------------------------------------------
--   			Gather Scripts     
-- human_gather orc_gather share the same tree and behavior
-- undead_gather (ghoul) has the same tree behavior
-- undead_gather (acolyte) and nightelf_gather share the same mine behavior
-- All builders share the same building repair behavior except for humans who can also construct with multiple builders
------------------------------------------

MIN_DISTANCE_TO_TREE = 200
MIN_DISTANCE_TO_MINE = 250
TREE_FIND_RADIUS_FROM_TREE = 200
TREE_FIND_RADIUS_FROM_TOWN = 2000
DURATION_INSIDE_MINE = 1
BASE_LUMBER_CARGO = 10
DAMAGE_TO_TREE = 1
DAMAGE_TO_MINE = 10
THINK_INTERVAL = 0.5
DEBUG_TREES = false
VALID_DEPOSITS = LoadKeyValues("scripts/kv/buildings.kv")

-- Gather Start - Decides what behavior to use
function Gather( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local target_class = target:GetClassname()

	caster:Interrupt() -- Stops any instance of Hold/Stop the builder might have

	-- Builder race
	local race = GetUnitRace(caster)

	-- Initialize variables to keep track of how much resource is the unit carrying
	if not caster.lumber_gathered then
		caster.lumber_gathered = 0
	end

	-- Possible states
		-- moving_to_tree
		-- moving_to_mine
		-- moving_to_repair
		-- moving_to_build (set on Building Helper when a order is confirmed)
		-- returning_lumber
		-- returning_gold
		-- gathering_lumber
		-- gathering_gold
		-- repairing
		-- idle

	-- Gather Lumber
	if target_class == "ent_dota_tree" then
		
		local tree = target

		-- Disable this for Acolytes
		if caster:GetUnitName() == "undead_acolyte" then
			print("Interrupt")
			caster:Interrupt()
			return
		end

		-- Check for empty tree for Wisps
		if IsNightElf(caster) and (tree.builder ~= nil and tree.builder ~= caster) then
			print(" The Tree already has a wisp in it, find another one!")
			caster:Interrupt()
			return
		end

		local tree_pos = tree:GetAbsOrigin()
		local particleName = "particles/ui_mouseactions/ping_circle_static.vpcf"
		local particle = ParticleManager:CreateParticleForPlayer(particleName, PATTACH_CUSTOMORIGIN, caster, caster:GetPlayerOwner())
		ParticleManager:SetParticleControl(particle, 0, Vector(tree_pos.x, tree_pos.y, tree_pos.z+20))
		ParticleManager:SetParticleControl(particle, 1, Vector(0,255,0))
		Timers:CreateTimer(3, function() 
			ParticleManager:DestroyParticle(particle, true)
		end)

		-- If the caster already had a tree targeted but changed with a right click to another tree, destroy the old move timer
		if caster.moving_timer then
			Timers:RemoveTimer(caster.moving_timer)
		end
		caster.state = "moving_to_tree"
		caster.target_tree = tree
		ability.cancelled = false
		if not tree.health then
			tree.health = TREE_HEALTH
		end

		tree.builder = caster
		local tree_pos = tree:GetAbsOrigin()

		-- Fake toggle the ability, cancel if any other order is given
		ToggleOn(ability)

		-- Recieving another order will cancel this
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_on_order_cancel_lumber", {})

		caster.moving_timer = Timers:CreateTimer(function() 

			-- End if killed
			if not (caster and IsValidEntity(caster) and caster:IsAlive()) then
				return
			end

			-- Move towards the tree until close range
			if not ability.cancelled and caster:HasModifier("modifier_on_order_cancel_lumber") and caster.state == "moving_to_tree" then
				local distance = (tree_pos - caster:GetAbsOrigin()):Length()
				
				if distance > MIN_DISTANCE_TO_TREE then
					caster:MoveToPosition(tree_pos)
					return THINK_INTERVAL
				else
					--print("Tree Reached")

					if IsNightElf(caster) then
						tree_pos.z = tree_pos.z - 28
						caster:SetAbsOrigin(tree_pos)

						tree.wisp_gathering = true
					end

					ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_lumber", {})
					return
				end
			else
				return
			end
		end)

		-- Hide Return
		if IsHuman(caster) or IsOrc(caster) then
			local return_ability = caster:FindAbilityByName(race.."_return_resources")
			return_ability:SetHidden(true)
			ability:SetHidden(false)
			--print("Gathering Lumber ON, Return OFF")
		end

	-- Gather Gold
	elseif string.match(target:GetUnitName(),"gold_mine") then

		-- Disable this for Ghouls
		if caster:GetUnitName() == "undead_ghoul" then
			caster:Interrupt()
			return
		end

		local mine
		if IsHuman(caster) or IsOrc(caster) then
			if target:GetUnitName() ~= "gold_mine" then
				print("Must target a gold mine, not a "..target:GetUnitName())
				return
			else
				mine = target
			end
		elseif IsNightElf(caster) then
			if target:GetUnitName() ~= "nightelf_entangled_gold_mine" then
				print("Must target a entangled gold mine, not a "..target:GetUnitName())
				return
			else
				mine = target.mine
			end
		elseif IsUndead(caster) then
			if target:GetUnitName() ~= "undead_haunted_gold_mine" then
				print("Must target a haunted gold mine, not a "..target:GetUnitName())
				return
			else
				mine = target.mine
			end
		end		

		local mine_pos = mine:GetAbsOrigin()
		caster.gold_gathered = 0
		caster.target_mine = mine
		ability.cancelled = false
		caster.state = "moving_to_mine"

		-- Destroy any old move timer
		if caster.moving_timer then
			Timers:RemoveTimer(caster.moving_timer)
		end

		-- Fake toggle the ability, cancel if any other order is given
		if ability:GetToggleState() == false then
			ability:ToggleAbility()
		end

		-- Recieving another order will cancel this
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_on_order_cancel_gold", {})

		local mine_entrance_pos = mine.entrance+RandomVector(75)
		caster.moving_timer = Timers:CreateTimer(function() 

			-- End if killed
			if not (caster and IsValidEntity(caster) and caster:IsAlive()) then
				return
			end

			-- Move towards the mine until close range
			if not ability.cancelled and caster:HasModifier("modifier_on_order_cancel_gold") and caster.state == "moving_to_mine" then
				local distance = (mine_pos - caster:GetAbsOrigin()):Length()
				
				if distance > MIN_DISTANCE_TO_MINE then
					caster:MoveToPosition(mine_entrance_pos)
					print("Moving to Mine, distance ", distance)
					return THINK_INTERVAL
				else
					--print("Mine Reached")

					-- 2 Possible behaviours: Human/Orc vs NE/UD
					-- NE/UD requires another building on top (Missing at the moment)

					if race == "human" or race == "orc" then
						if mine.builder then
							--print("Waiting for the builder inside to leave")
							return THINK_INTERVAL
						elseif mine and IsValidEntity(mine) then
							mine.builder = caster
							ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_gold", {duration = DURATION_INSIDE_MINE})
							caster:SetAbsOrigin(mine:GetAbsOrigin()) -- Send builder inside
							return
						else
							caster:RemoveModifierByName("modifier_on_order_cancel_gold")
							CancelGather(event)
						end

					elseif race == "undead" or race == "nightelf" then
						if not IsMineOccupiedByTeam(mine, caster:GetTeamNumber()) then
							print("Mine must be occupied by your team, fool")
							return
						end

						if target.state == "building" then
							--print("Extraction Building is still in construction, wait...")
							return THINK_INTERVAL
						end

						if not mine.builders then
							mine.builders = {}
						end

						local counter = #mine.builders
						print(counter, "Builders inside")
						if counter >= 5 then
							print(" Mine full")
							return
						end

						local distance = 0
						local height = 0
						if race == "undead" then
							distance = 250
						elseif race == "nightelf" then
							distance = 100
							height = 25
						end
						
						ability:ApplyDataDrivenModifier(caster, caster, "modifier_gathering_gold", {})

						-- Find first empty position
						local free_pos
						for i=1,5 do
							if not mine.builders[i] then
								mine.builders[i] = caster
								free_pos = i
								break
							end
						end		

						-- 5 positions = 72 degrees
						local mine_origin = mine:GetAbsOrigin()
						local fv = mine:GetForwardVector()
						local front_position = mine_origin + fv * distance
						local pos = RotatePosition(mine_origin, QAngle(0, 72*free_pos, 0), front_position)
						caster:Stop()
						caster:SetAbsOrigin(Vector(pos.x, pos.y, pos.z+height))
						caster:SetForwardVector( (mine_origin - caster:GetAbsOrigin()):Normalized() )
						Timers:CreateTimer(0.06, function() 
							caster:Stop() 
							caster:SetForwardVector( (mine_origin - caster:GetAbsOrigin()):Normalized() )
							RemoveUnitFromSelection(caster)
						end)

						-- Particle Counter on overhead
						counter = #mine.builders
						SetGoldMineCounter(mine, counter)

					end
				end
			else
				return
			end
		end)
			
		-- Hide Return
		local return_ability = caster:FindAbilityByName(race.."_return_resources")
		if return_ability then
			return_ability:SetHidden(true)
		end

	-- Repair Building / Siege
	elseif target_class == "npc_dota_creature" then
		if (IsCustomBuilding(target) or IsMechanical(target)) and target:GetHealthDeficit() > 0 and not target.unsummoning and not target.frozen then

			-- Only Humans can assist building construction
			if race ~= "human" and target.state == "building" then
				caster:Interrupt()
				return
			end

			-- Ghouls don't repair
			if caster:GetUnitName() == "undead_ghoul" then
				caster:Interrupt()
				return
			end

			caster.repair_target = target

			local target_pos = target:GetAbsOrigin()
			
			ability.cancelled = false
			caster.state = "moving_to_repair"

			-- Destroy any old move timer
			if caster.moving_timer then
				Timers:RemoveTimer(caster.moving_timer)
			end

			-- Fake toggle the ability, cancel if any other order is given
			if ability:GetToggleState() == false then
				ability:ToggleAbility()
			end

			-- Recieving another order will cancel this
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_on_order_cancel_repair", {})

			local collision_size = GetCollisionSize(target)*2 + 64

			caster.moving_timer = Timers:CreateTimer(function()

				-- End if killed
				if not (caster and IsValidEntity(caster) and caster:IsAlive()) then
					return
				end

				-- Move towards the target until close range
				if not ability.cancelled and caster.state == "moving_to_repair" then
					if caster.repair_target and IsValidEntity(caster.repair_target) then
						local distance = (target_pos - caster:GetAbsOrigin()):Length()
						
						if distance > collision_size then
							caster:MoveToNPC(target)
							return THINK_INTERVAL
						else
							ability:ApplyDataDrivenModifier(caster, caster, "modifier_builder_repairing", {})
							print("Reached target, starting the Repair process")
							return
						end
					else
						print("Building was killed in the way of a builder to repair it")
						caster:RemoveModifierByName("modifier_on_order_cancel_repair")
						CancelGather(event)
					end
				else
					return
				end
			end)
		else
			print("Not a valid repairable unit or already on full health")
		end
	else
		print("Not a valid target for this ability")
		caster:Stop()
	end
end

-- Toggles Off Gather
function CancelGather( event )
	local caster = event.caster
	local ability = event.ability

	local ability_order = event.event_ability
	if ability_order then
		local order_name = ability_order:GetAbilityName()
		--print("CancelGather Order: "..order_name)
		if string.match(order_name,"build_") then
			--print(" return")
			return
		end
	end

	caster:RemoveModifierByName("modifier_on_order_cancel_lumber")
	caster:RemoveModifierByName("modifier_gathering_lumber")
	caster:RemoveModifierByName("modifier_on_order_cancel_gold")

	ability.cancelled = true
	caster.state = "idle"

	-- Builder race
	local race = GetUnitRace(caster)

	local tree = caster.target_tree
	if tree then
		caster.target_tree = nil
		tree.builder = nil
	end

	if race == "nightelf" then
		-- Give 1 extra second of fly movement
		caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
		Timers:CreateTimer(2,function() 
			caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
			caster:AddNewModifier(caster, nil, "modifier_phased", {duration=0.03})
		end)
	end

	local mine = caster.target_mine
	if mine and mine.builders then
		if race == "nightelf" or race == "undead" then
			local caster_key = TableFindKey(mine.builders, caster)
			if caster_key then
				mine.builders[caster_key] = nil

				local count = 0
				for k,v in pairs(mine.builders) do
					count=count+1
				end
				print("Count is ", count, "key removed was ",caster_key)
				SetGoldMineCounter(mine, count)

				
			end
		end
	end
	
	ToggleOff(ability)
	if gather_ability then
		ToggleOff(gather_ability)
	end
end

-- Toggles Off Return because of an order (e.g. Stop)
function CancelReturn( event )
	local caster = event.caster
	local ability = event.ability

	local ability_order = event.event_ability
	if ability_order then
		local order_name = ability_order:GetAbilityName()
		if string.match(order_name,"build_") then
			return
		end
	end

	-- Builder race
	local race = GetUnitRace(caster)

	local gather_ability = caster:FindAbilityByName(race.."_gather")
	gather_ability.cancelled = true
	caster.state = "idle"

	local tree = caster.target_tree
	if tree then
		tree.builder = nil
	end
	
	ToggleOff(ability)
	if gather_ability then
		ToggleOff(gather_ability)
	end
end

-- Used in Human and Orc Gather Lumber
-- Gets called every second, increases the carried lumber of the builder by 1 until it can't carry more
-- Also does tree cutting and reacquiring of new trees when necessary.
function GatherLumber( event )
	
	local caster = event.caster
	local ability = event.ability
	local player = caster:GetPlayerOwner()
	local max_lumber_carried = BASE_LUMBER_CARGO
	local tree = caster.target_tree

	-- Builder race
	local race = GetUnitRace(caster)

	caster.state = "gathering_lumber"

	--print("Tree Health: ", tree.health)

	-- Upgraded on LumberResearchComplete
	if player.LumberCarried then 
		max_lumber_carried = player.LumberCarried
	end

	-- Undead Ghouls can carry up to 20
	if IsUndead(caster) then
		max_lumber_carried = 20
	end

	local return_ability = caster:FindAbilityByName(race.."_return_resources")

	caster.lumber_gathered = caster.lumber_gathered + 1
	if tree and tree.health then

		-- Hit particle
		local particleName = "particles/custom/tree_pine_01_destruction.vpcf"
		local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, tree:GetAbsOrigin())

		tree.health = tree.health - DAMAGE_TO_TREE
		if tree.health <= 0 then
			tree:CutDown(caster:GetTeamNumber())

			-- Move to a new tree nearby
			local a_tree = FindEmptyNavigableTreeNearby(caster, tree:GetAbsOrigin(), TREE_FIND_RADIUS_FROM_TREE)
			if a_tree then
				caster.target_tree = a_tree
				caster:MoveToTargetToAttack(a_tree)
				if DEBUG_TREES then DebugDrawCircle(a_tree:GetAbsOrigin(), Vector(0,255,0), 255, 64, true, 10) end
			else
				-- Go to return resources (where it will find a tree nearby the town instead)
				local player = caster:GetPlayerOwnerID()
				return_ability:SetHidden(false)
				ability:SetHidden(true)
				
				caster:CastAbilityNoTarget(return_ability, player)
			end
		end
	end
		
	-- Show the stack of resources that the unit is carrying
	if not caster:HasModifier("modifier_carrying_lumber") then
        return_ability:ApplyDataDrivenModifier( caster, caster, "modifier_carrying_lumber", nil)
    end
    caster:SetModifierStackCount("modifier_carrying_lumber", caster, caster.lumber_gathered)
 
	-- Increase up to the max, or cancel
	if caster.lumber_gathered < max_lumber_carried and tree:IsStanding() then
		caster:StartGesture(ACT_DOTA_ATTACK)

		-- Show the return ability
		if return_ability:IsHidden() then
			caster:SwapAbilities(race.."_gather", race.."_return_resources", false, true)
		end
	else
		-- RETURN
		local player = caster:GetOwner():GetPlayerID()
		caster:RemoveModifierByName("modifier_gathering_lumber")

		-- Cast Return Resources	
		caster:CastAbilityNoTarget(return_ability, player)
	end
end

-- Used in Human and Orc Gather Gold
-- Gets called after the builder goes outside the mine
-- Takes DAMAGE_TO_MINE hit points away from the gold mine and starts the return
function GatherGold( event )
	local caster = event.caster
	local ability = event.ability
	local mine = caster.target_mine

	-- Builder race
	local race = GetUnitRace(caster)

	mine:SetHealth( mine:GetHealth() - DAMAGE_TO_MINE )
	caster.gold_gathered = DAMAGE_TO_MINE
	mine.builder = nil --Set the mine free for other builders to enter
	caster.state = "gathering_gold"

	-- If the gold mine has no health left for another harvest
	if mine:GetHealth() < DAMAGE_TO_MINE then

		-- Destroy the nav blockers associated with it
		for k, v in pairs(mine.blockers) do
	      DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
	      DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
	    end
	    print("Gold Mine Collapsed at ", mine:GetHealth())
	    mine:RemoveSelf()

		caster.target_mine = nil
	end

	local return_ability = caster:FindAbilityByName(race.."_return_resources")
	return_ability:SetHidden(false)
	return_ability:ApplyDataDrivenModifier( caster, caster, "modifier_carrying_gold", nil)
	
	ability:SetHidden(true)

	caster:SetModifierStackCount("modifier_carrying_gold", caster, DAMAGE_TO_MINE)

	local player = caster:GetOwner():GetPlayerID()
					
	-- Find where to put the builder outside the mine
	local position = mine.entrance
	FindClearSpaceForUnit(caster, position, true)

	-- Cast ReturnResources
	caster:CastAbilityNoTarget(return_ability, player)
end

-- Used in Night Elf Gather Lumber
function LumberGain( event )
	local ability = event.ability
	local caster = event.caster
	local lumber_gain = ability:GetSpecialValueFor("lumber_per_interval")
	ModifyLumber( caster:GetPlayerOwner(), lumber_gain )
	PopupLumber( caster, lumber_gain)
end

-- Used in Nigh Elf and Undead Gather Gold
function GoldGain( event )
	local ability = event.ability
	local caster = event.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local race = GetUnitRace(caster)
	local gold_gain = ability:GetSpecialValueFor("gold_per_interval")
	hero:ModifyGold(gold_gain, false, 0)
	PopupGoldGain( caster, gold_gain)

	-- Reduce the health of the main and mana on the entangled/haunted mine to show the remaining gold
	local mine = caster.target_mine
	mine:SetHealth( mine:GetHealth() - gold_gain )
	mine.building_on_top:SetMana( mine:GetHealth() - gold_gain )

	-- If the gold mine has no health left for another harvest
	if mine:GetHealth() < gold_gain then

		-- Destroy the nav blockers associated with it
		for k, v in pairs(mine.blockers) do
	      DoEntFireByInstanceHandle(v, "Disable", "1", 0, nil, nil)
	      DoEntFireByInstanceHandle(v, "Kill", "1", 1, nil, nil)
	    end
	    print("Gold Mine Collapsed at ", mine:GetHealth())

	    -- Stop all builders
		local builders = mine.builders
		for k,builder in pairs(builders) do

			-- Cancel gather effects
			builder:RemoveModifierByName("modifier_on_order_cancel_gold")
			builder:RemoveModifierByName("modifier_gathering_gold")
			builder.state = "idle"

			local ability = builder:FindAbilityByName(race.."_gather")
			ability.cancelled = true
			ToggleOff(ability)

			if race == "nightelf" then
				FindClearSpaceForUnit(builder, mine.entrance, true)
			end
		end

		ParticleManager:DestroyParticle(mine.building_on_top.counter_particle, true)
	    mine.building_on_top:RemoveSelf()

	    mine:RemoveSelf()

		caster.target_mine = nil
	end
end

function SetGoldMineCounter( mine, count )
	local building_on_top = mine.building_on_top

	print("SetGoldMineCounter ",count)

	for i=1,count do
		--print("Set ",i," turned on")
		ParticleManager:SetParticleControl(building_on_top.counter_particle, i, Vector(1,0,0))
	end
	for i=count+1,5 do
		--print("Set ",i," turned off")
		ParticleManager:SetParticleControl(building_on_top.counter_particle, i, Vector(0,0,0))
	end
end

-- Called when the race_return_resources ability is cast
function ReturnResources( event )
	local caster = event.caster
	local ability = event.ability
	local hero = caster:GetOwner()
	local player = caster:GetPlayerOwner()
	local pID = hero:GetPlayerID()
	
	caster:Interrupt() -- Stops any instance of Hold/Stop the builder might have
	
	-- Builder race
	local race = GetUnitRace(caster)

	-- Return Ability On
	ability.cancelled = false
	if ability:GetToggleState() == false then
		ability:ToggleAbility()
	end

	local gather_ability = caster:FindAbilityByName(race.."_gather")

	-- Destroy any old move timer
	if caster.moving_timer then
		Timers:RemoveTimer(caster.moving_timer)
	end

	-- LUMBER
	if caster:HasModifier("modifier_carrying_lumber") then
		-- Find where to return the resources
		local building = FindClosestResourceDeposit( caster, "lumber" )
		caster.target_building = building
		caster.state = "returning_lumber"

		local collision_size = building:GetHullRadius()*2 + 64

		-- Move towards it
		caster.moving_timer = Timers:CreateTimer(function() 

			-- End if killed
			if not (caster and IsValidEntity(caster) and caster:IsAlive()) then
				return
			end

			if not ability.cancelled then
				if caster.target_building and IsValidEntity(caster.target_building) and caster.state == "returning_lumber" then
					local building_pos = caster.target_building:GetAbsOrigin()
					local distance = (building_pos - caster:GetAbsOrigin()):Length()
				
					if distance > collision_size then
						caster:MoveToNPC(caster.target_building)					
						return THINK_INTERVAL
					elseif caster.lumber_gathered and caster.lumber_gathered > 0 then
						--print("Building Reached at ",distance)
						caster:RemoveModifierByName("modifier_carrying_lumber")
						PopupLumber(caster, caster.lumber_gathered)
						ModifyLumber(player, caster.lumber_gathered)

						-- Also handle possible gold leftovers if its being deposited in a city center
						if caster:HasModifier("modifier_carrying_gold") then
							caster:RemoveModifierByName("modifier_carrying_gold")
							local upkeep = GetUpkeep( player )
							local gold_gain = caster.gold_gathered * upkeep
							hero:ModifyGold(gold_gain, false, 0)
							PopupGoldGain(caster, gold_gain)
							caster.gold_gathered = 0
						end

						caster.lumber_gathered = 0
						--print("Back to the trees")
						if caster.target_tree and caster.target_tree:IsStanding() then
							caster:CastAbilityOnTarget(caster.target_tree, gather_ability, pID)
						else
							-- Find closest near the city center in a huge radius
							if caster.target_building then
								caster.target_tree = FindEmptyNavigableTreeNearby(caster, caster.target_building:GetAbsOrigin(), TREE_FIND_RADIUS_FROM_TOWN)
								if caster.target_tree and DEBUG_TREES then
									DebugDrawCircle(caster.target_building:GetAbsOrigin(), Vector(255,0,0), 5, TREE_FIND_RADIUS_FROM_TOWN, true, 60)
									DebugDrawCircle(caster.target_tree:GetAbsOrigin(), Vector(0,255,0), 255, 64, true, 10)
								end
							end
														
							if caster.target_tree then
								if DEBUG_TREES then DebugDrawCircle(caster.target_tree:GetAbsOrigin(), Vector(0,255,0), 255, 64, true, 10) end
								if caster.target_tree then
									caster:CastAbilityOnTarget(caster.target_tree, gather_ability, pID)
								end
							else
								-- Cancel ability, couldn't find moar trees...
								ToggleOff(gather_ability)

								caster:SwapAbilities(race.."_gather", race.."_return_resources", true, false)
							end
						end
						return
					end
				else
					-- Find a new building deposit
					building = FindClosestResourceDeposit( caster, "lumber" )
					caster.target_building = building
					return THINK_INTERVAL
				end
			else
				return
			end
		end)

	-- GOLD
	elseif caster:HasModifier("modifier_carrying_gold") then
		-- Find where to return the resources
		local building = FindClosestResourceDeposit( caster, "gold" )
		caster.target_building = building
		caster.state = "returning_gold"
		local collision_size = building:GetHullRadius()*2 + 64

		-- Move towards it
		caster.moving_timer = Timers:CreateTimer(function() 

			-- End if killed
			if not (caster and IsValidEntity(caster) and caster:IsAlive()) then
				return
			end

			if not ability.cancelled then
				if caster.target_building and IsValidEntity(caster.target_building) and caster.state == "returning_gold" then
					local building_pos = building:GetAbsOrigin()
					local distance = (building_pos - caster:GetAbsOrigin()):Length()
				
					if distance > collision_size then
						caster:MoveToNPC(building)
						return THINK_INTERVAL
					elseif caster.gold_gathered and caster.gold_gathered > 0 then
						--print("Building Reached at ",distance)
						local upkeep = GetUpkeep( player )
						local gold_gain = caster.gold_gathered * upkeep

						hero:ModifyGold(gold_gain, false, 0)
						PopupGoldGain(caster, gold_gain)

						caster:RemoveModifierByName("modifier_carrying_gold")

						-- Also handle possible lumber leftovers
						if caster:HasModifier("modifier_carrying_lumber") then
							caster:RemoveModifierByName("modifier_carrying_lumber")
							PopupLumber(caster, caster.lumber_gathered)
							ModifyLumber(player, caster.lumber_gathered)
							caster.lumber_gathered = 0
						end

						caster.gold_gathered = 0

						if caster.target_mine and IsValidEntity(caster.target_mine) then
							--print("Back to the Mine")

							caster:SwapAbilities(race.."_gather",race.."_return_resources", true, false)

							caster:CastAbilityOnTarget(caster.target_mine, gather_ability, pID)
						else
							--print("Mine Collapsed")
							ToggleOff(gather_ability)
							caster:SwapAbilities(race.."_gather",race.."_return_resources", true, false)
							caster:RemoveModifierByName("modifier_on_order_cancel_gold")
						end
						return
					end
				else
					-- Find a new building deposit
					building = FindClosestResourceDeposit( caster, "gold" )
					caster.target_building = building
					return THINK_INTERVAL
				end
			else
				return
			end
		end)
	
	-- No resources to return, give the gather ability back
	else
		--print("TRIED TO RETURN NO RESOURCES")
		ToggleOff(gather_ability)
		caster:SwapAbilities(race.."_gather",race.."_return_resources", true, false)
		caster:RemoveModifierByName("modifier_on_order_cancel_gold")
	end
end

--------------------------------
--       Repair Scripts       --
--------------------------------

-- These are the Repair ratios for any race
-- Repair Cost Ratio = 0.35 - Takes 105g to fully repair a building that costs 300. Also applies to lumber
-- Repair Time Ratio = 1.5 - Takes 150 seconds to fully repair a building that took 100seconds to build

-- Humans can assist the construction with multiple peasants
-- Rest of the races can assist the repairing (takes 1+ builder in consideration)
-- In that case, extra resources are consumed
-- Powerbuild Cost = THINK_INTERVAL5 - Added for every extra builder repairing the same building
-- Powerbuild Rate = 0.60 - Fastens the ratio by 60%?
	
-- Values are taken from the UnitKV GoldCost LumberCost and BuildTime

function Repair( event )
	local caster = event.caster -- The builder
	local ability = event.ability
	local building = event.target -- The building to repair

	local hero = caster:GetOwner()
	local player = caster:GetPlayerOwner()
	local pID = hero:GetPlayerID()

	local building_name = building:GetUnitName()
	local building_info = GameRules.UnitKV[building_name]
	local gold_cost = building_info.GoldCost
	local lumber_cost = building_info.LumberCost
	local build_time = building_info.BuildTime

	local state = building.state -- "completed" or "building"
	local health_deficit = building:GetHealthDeficit()

	ToggleOn(ability)

	-- If its an unfinished building, keep track of how much does it require to mark as finished
	if not building.constructionCompleted and not building.health_deficit then
		building.missingHealthToComplete = health_deficit
	end

	-- Scale costs/time according to the stack count of builders reparing this
	if health_deficit > 0 then
		-- Initialize the tracking
		if not building.health_deficit then
			building.health_deficit = health_deficit
			building.gold_used = 0
			building.lumber_used = 0
			building.HPAdjustment = 0
			building.GoldAdjustment = 0
			building.time_started = GameRules:GetGameTime()
		end
		
		local stack_count = building:GetModifierStackCount( "modifier_repairing_building", ability )

		-- HP
		local health_per_second = building:GetMaxHealth() /  ( build_time * 1.5 ) * stack_count
		local health_float = health_per_second - math.floor(health_per_second) -- floating point component
		health_per_second = math.floor(health_per_second) -- round down

		-- Don't expend resources for the first peasant repairing the building if its a construction
		if not building.constructionCompleted then
			stack_count = stack_count - 1
		end

		-- Gold
		local gold_per_second = gold_cost / ( build_time * 1.5 ) * 0.35 * stack_count
		local gold_float = gold_per_second - math.floor(gold_per_second) -- floating point component
		gold_per_second = math.floor(gold_per_second) -- round down

		-- Lumber takes floats just fine
		local lumber_per_second = lumber_cost / ( build_time * 1.5 ) * 0.35 * stack_count

		--[[print("Building is repaired for "..health_per_second)
		if gold_per_second > 0 then
			print("Cost is "..gold_per_second.." gold and "..lumber_per_second.." lumber per second")
		else
			print("Cost is "..gold_float.." gold and "..lumber_per_second.." lumber per second")
		end]]
			
		local healthGain = 0
		if PlayerHasEnoughGold( player, math.ceil(gold_per_second+gold_float) ) and PlayerHasEnoughLumber( player, lumber_per_second ) then
			-- Health
			building.HPAdjustment = building.HPAdjustment + health_float
			if building.HPAdjustment > 1 then
				healthGain = health_per_second + 1
				building:SetHealth(building:GetHealth() + healthGain)
				building.HPAdjustment = building.HPAdjustment - 1
			else
				healthGain = health_per_second
				building:SetHealth(building:GetHealth() + health_per_second)
			end
			
			-- Consume Resources
			building.GoldAdjustment = building.GoldAdjustment + gold_float
			if building.GoldAdjustment > 1 then
				hero:ModifyGold( -gold_per_second - 1, false, 0)
				building.GoldAdjustment = building.GoldAdjustment - 1
				building.gold_used = building.gold_used + gold_per_second + 1
			else
				hero:ModifyGold( -gold_per_second, false, 0)
				building.gold_used = building.gold_used + gold_per_second
			end
			
			ModifyLumber( player, -lumber_per_second )
			building.lumber_used = building.lumber_used + lumber_per_second
		else
			-- Remove the modifiers on the building and the builders
			building:RemoveModifierByName("modifier_repairing_building")
			for _,builder in pairs(building.units_repairing) do
				if builder and IsValidEntity(builder) then
					builder:RemoveModifierByName("modifier_builder_repairing")
				end
			end
			print("Repair Ended, not enough resources!")
			building.health_deficit = nil
			building.missingHealthToComplete = nil

			-- Toggle off
			ToggleOff(ability)
		end

		-- Decrease the health left to finish construction and mark building as complete
		if building.missingHealthToComplete then
			building.missingHealthToComplete = building.missingHealthToComplete - healthGain
		end

	-- Building Fully Healed
	else
		-- Remove the modifiers on the building and the builders
		building:RemoveModifierByName("modifier_repairing_building")
		for _,builder in pairs(building.units_repairing) do
			if builder and IsValidEntity(builder) then
				builder:RemoveModifierByName("modifier_builder_repairing")
			end
		end
		-- Toggle off
		ToggleOff(ability)

		print("Repair End")
		print("Start HP/Gold/Lumber/Time: ", building.health_deficit, gold_cost, lumber_cost, build_time)
		print("Final HP/Gold/Lumber/Time: ", building:GetHealth(), building.gold_used, math.floor(building.lumber_used), GameRules:GetGameTime() - building.time_started)
		building.health_deficit = nil
	end

	-- Construction Ended
	if building.missingHealthToComplete and building.missingHealthToComplete <= 0 then
		building.missingHealthToComplete = nil
		building.constructionCompleted = true -- BuildingHelper will track this and know the building ended
	else
		--print("Missing Health to Complete building: ",building.missingHealthToComplete)
	end
end

function BuilderRepairing( event )
	local caster = event.caster
	local ability = event.ability
	local target = caster.repair_target
	
	caster.state = "repairing"

	-- Apply a modifier stack to the building, to show how many peasants are working on it (and scale the Powerbuild costs)
	local modifierName = "modifier_repairing_building"
	if target:HasModifier(modifierName) then
		target:SetModifierStackCount( modifierName, ability, target:GetModifierStackCount( modifierName, ability ) + 1 )
	else
		ability:ApplyDataDrivenModifier( caster, target, modifierName, { Duration = duration } )
		target:SetModifierStackCount( modifierName, ability, 1 )
	end

	-- Keep a list of the units repairing this building
	if not target.units_repairing then
		target.units_repairing = {}
		table.insert(target.units_repairing, caster)
	else
		table.insert(target.units_repairing, caster)
	end
end

function BuilderStopRepairing( event )
	local caster = event.caster
	local ability = event.ability
	local building = caster.repair_target

	local ability_order = event.event_ability
	if ability_order then
		local order_name = ability_order:GetAbilityName()
		if string.match(order_name,"build_") then
			return
		end
	end
	
	caster:RemoveModifierByName("modifier_on_order_cancel_repair")
	caster:RemoveModifierByName("modifier_builder_repairing")
	caster:RemoveGesture(ACT_DOTA_ATTACK)

	caster.state = "idle"

	-- Apply a modifier stack to the building, to show how many builders are working on it (and scale the Powerbuild costs)
	local modifierName = "modifier_repairing_building"
	if building and IsValidEntity(building) and building:HasModifier(modifierName) then
		local current_stack = building:GetModifierStackCount( modifierName, ability )
		if current_stack > 1 then
			building:SetModifierStackCount( modifierName, ability, current_stack - 1 )
		else
			building:RemoveModifierByName( modifierName )
		end
	end

	-- Remove the builder from the list of units repairing the building
	local builder = getIndex(building.units_repairing, caster)
	if builder and builder ~= -1 then
		table.remove(building.units_repairing, builder)
	end
end

function RepairAnimation( event )
	local caster = event.caster
	caster:StartGesture(ACT_DOTA_ATTACK)
end