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

	local ability = event.ability
	local cast_time = ability:GetCastPoint()
	Timers:CreateTimer(cast_time, function()
		print("Root End")

		caster:AddAbility("ability_building")
		caster:AddAbility("ability_building_queue")

		-- Set all abilities back to level 1 except the possibly _disabled abilities
		for i=0,15 do
			local ability = caster:GetAbilityByIndex(i)
			if ability then
				--if and not string.match(ability:GetAbilityName(), "_disabled") then
				ability:SetLevel(1)
			end
		end

		local size = 5 --This should be gotten from the ability instead
		local location = caster:GetAbsOrigin()
		-- BuildingHelper - GridNav blockers & Placement
		local gridNavBlockers = {}
		  if size % 2 == 1 then
		    for x = location.x - (size / 2) * 32 , location.x + (size / 2) * 32 , 64 do
		      for y = location.y - (size / 2) * 32 , location.y + (size / 2) * 32 , 64 do
		        local blockerLocation = Vector(x, y, location.z)
		        local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
		        table.insert(gridNavBlockers, ent)
		      end
		    end
		  else
		    for x = location.x - (size / 2) * 32 + 16, location.x + (size / 2) * 32 - 16, 96 do
		      for y = location.y - (size / 2) * 32 + 16, location.y + (size / 2) * 32 - 16, 96 do
		        local blockerLocation = Vector(x, y, location.z)
		        local ent = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = blockerLocation})
		        table.insert(gridNavBlockers, ent)
		      end
		    end
		  end
	    
	    caster.blockers = gridNavBlockers
	    caster:SetAbsOrigin(location)

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
end

function UpRoot( event )
	print("Finish UpRooting")
	local caster = event.caster
	caster:RemoveAbility("ability_building")
	caster:RemoveModifierByName("modifier_building")
	caster:RemoveAbility("ability_building_queue")
	caster:RemoveModifierByName("modifier_building_queue")

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

	-- Set all abilities to level 0 except the root ability
	for i=0,15 do
		local ability = caster:GetAbilityByIndex(i)
		if ability and ability:GetAbilityName() ~= "nightelf_root" then
			ability:SetLevel(0)
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
end