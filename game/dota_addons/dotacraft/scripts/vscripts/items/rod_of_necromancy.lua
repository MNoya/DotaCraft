function RaiseDead ( keys )
	local caster = keys.caster
	local ability = keys.ability
	local player = caster:GetPlayerOwner()
	local pID = caster:GetPlayerOwnerID()

	local radius = ability:GetSpecialValueFor("radius")
	local duration = ability:GetSpecialValueFor("duration") --Does not scale with Skeletal Mastery
	
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), radius)
	
	-- check if there's any valid corpse around
	local target
	for k,corpse in pairs(targets) do
		if corpse.corpse_expiration ~= nil and not corpse.being_eaten then
			target = corpse
		elseif (corpse:GetUnitName() == "undead_meat_wagon" and corpse:GetModifierStackCount("modifier_corpses", corpse) > 0 and pID == corpse:GetPlayerOwnerID()) then
			target = corpse
			break
		end
	end
	
	-- If no valid target, refund and show an error message
	if not target then
		caster:Interrupt()
		SendErrorMessage(pID, "#error_no_usable_corpses")
		
		ability:EndCooldown()
		return
	end

	-- Raise Dead
	local spawnlocation = target:GetAbsOrigin()
	caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
	ability:SetCurrentCharges(ability:GetCurrentCharges() - 1)
	
	if target.corpse_expiration ~= nil and not target.being_eaten then		
		
		-- create units
		CreateUnit(caster, spawnlocation, duration)
			
		-- Leave no corpses
		target.no_corpse = true
		target:RemoveSelf()

		return

	-- Take a corpse from a meat wagon
	elseif target:GetUnitName() == "undead_meat_wagon" 
		   and target:GetModifierStackCount("modifier_corpses", target) > 0 
		   and target:GetPlayerOwnerID() == target:GetPlayerOwnerID() then	

		local StackCount = target:GetModifierStackCount("modifier_corpses", target)
		if StackCount > 0 then
			target:SetModifierStackCount("modifier_corpses", target, StackCount - 1)					
				
			CreateUnit(caster, spawnlocation, duration)		
			return	
		end	
	end
end

function CreateUnit(caster, spawnlocation, duration)
	local playerID = caster:GetPlayerOwnerID()
	local player = PlayerResource:GetPlayer(playerID)
	local unitname = "undead_skeleton_warrior"

	for i=0, 1 do
		local CreatedUnit = CreateUnitByName(unitname, spawnlocation, true, player:GetAssignedHero(),  player:GetAssignedHero(), caster:GetTeamNumber())
		CreatedUnit:SetControllableByPlayer(playerID, true)
		CreatedUnit:AddNewModifier(CreatedUnit, nil, "modifier_kill", {duration = duration})
		ParticleManager:CreateParticle("particles/neutral_fx/skeleton_spawn.vpcf", 0, CreatedUnit)
		
		CreatedUnit:SetIdleAcquire(false)
		Timers:CreateTimer(0.5, function() CreatedUnit:SetIdleAcquire(true) end)

		CreatedUnit.no_corpse = true
		Players:AddUnit(playerID, CreatedUnit)

		-- Summoned skeleton warriors don't benefit from the skeletal longevity upgrade, remove it
		if CreatedUnit:HasAbility("undead_skeletal_longevity") then
			CreatedUnit:RemoveAbility("undead_skeletal_longevity")
		else
			CreatedUnit:RemoveAbility("undead_skeletal_longevity_disabled")
		end

		-- Apply upgrades
		CheckAbilityRequirements(CreatedUnit, playerID)
		ApplyMultiRankUpgrade(CreatedUnit, "undead_research_unholy_strength", "weapon")
		ApplyMultiRankUpgrade(CreatedUnit, "undead_research_unholy_armor", "armor")
	end
end