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
	local cast_time = ability:GetCastPoint()
	Timers:CreateTimer(cast_time, function()
		print("Root End")

		caster:AddAbility("ability_building")
		caster:AddAbility("ability_building_queue")

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

	-- Hide all train and research abilities, show eat tree
	for i=0,15 do
		local ability = caster:GetAbilityByIndex(i)
		if ability then
			if ( string.match(ability:GetAbilityName(), "train_") or string.match(ability:GetAbilityName(), "research_")) then
				ability:SetHidden(true)
			elseif ability:GetAbilityName() == "nightelf_eat_tree" then
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