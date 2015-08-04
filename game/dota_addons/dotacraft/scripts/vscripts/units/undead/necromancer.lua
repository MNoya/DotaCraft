function undead_raise_dead ( keys )
	local target = keys.target
	local caster = keys.caster
	local ability = keys.ability

	-- durations have be inverted due to some weird parsing bug
	local RADIUS = keys.ability:GetSpecialValueFor("radius")
	local SKELETON_DURATION = keys.ability:GetSpecialValueFor("duration")
	local duration
	
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), RADIUS)
	
	for k,corpse in pairs(targets) do
		local abilitylevel = ability:GetLevel()
		local spawnlocation = corpse:GetAbsOrigin()
		
		if corpse.corpse_expiration ~= nil and not corpse.being_eaten then					
			--if PlayerHasResearch( player, "undead_research_skeletal_longevity" ) then
			--	duration = SKELETON_DURATION + 15
			--else
				duration = SKELETON_DURATION
			--end
			
			-- create units
			CreateUnit(caster, spawnlocation, abilitylevel, duration)
			
			-- Leave no corpses
			corpse.no_corpse = true
			corpse:RemoveSelf()
			return
		end
		
		if corpse:GetUnitName() == "undead_meat_wagon" and corpse:GetModifierStackCount("modifier_corpses", corpse) > 0 and caster:GetPlayerOwnerID() == corpse:GetPlayerOwnerID() then	
			local StackCount = corpse:GetModifierStackCount("modifier_corpses", corpse)
			if  StackCount > 0 then
				corpse:SetModifierStackCount("modifier_corpses",corpse, StackCount - 1)
					print("stackcount is greatert then 0")
					
				--if PlayerHasResearch( player, "undead_research_skeletal_longevity" ) then
				--	duration = SKELETON_DURATION + 15
				--else
					duration = SKELETON_DURATION
				--end
				
				-- create units
				CreateUnit(caster, spawnlocation, abilitylevel, duration)		
				return
			end		
		end
		
	end
end

function CreateUnit(caster, spawnlocation, techIndex, duration)
	local playerID = caster:GetPlayerOwnerID()
	local player = PlayerResource:GetPlayer(playerID)
	local warrior = "undead_skeleton_warrior"
	local mage = "undead_skeletal_mage"

	for i=0, 1, 1 do
		local unitname = warrior
		if i == 1 and techIndex == 2 then
			unitname = mage
		end
	
		local CreatedUnit = CreateUnitByName(unitname, spawnlocation, true, player:GetAssignedHero(),  player:GetAssignedHero(), caster:GetTeamNumber())
		CreatedUnit:SetControllableByPlayer(playerID, true)
		CreatedUnit:AddNewModifier(CreatedUnit, nil, "modifier_kill", {duration = duration})
		ParticleManager:CreateParticle("particles/neutral_fx/skeleton_spawn.vpcf", 0, CreatedUnit)
		
		CreatedUnit.no_corpse = true
		table.insert(player.units, CreatedUnit)
	end

end

-- Denies casting if no corpses near, with a message
function AnimateDeadPrecast( event )
	local ability = event.ability
	local RADIUS = event.ability:GetSpecialValueFor("radius")
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", event.caster:GetAbsOrigin(), RADIUS)
	local pID = event.caster:GetPlayerOwnerID()
	
	-- check if there's any valid targets around
	local targetfound = false
	for k,corpse in pairs(targets) do
		if corpse.corpse_expiration ~= nil or (corpse:GetUnitName() == "undead_meat_wagon" and corpse:GetModifierStackCount("modifier_corpses", corpse) > 0 and event.caster:GetPlayerOwnerID() == corpse:GetPlayerOwnerID()) then
			targetfound = true
			break
		end
	end
	
	-- if no targets are found then
	if not targetfound then
		event.caster:Interrupt()
		SendErrorMessage(pID, "#error_no_usable_corpses")
		
		local mana = event.caster:GetMana()
		ability:EndCooldown()
		
		Timers:CreateTimer(function() event.caster:SetMana(mana) end)
	end
end

function undead_raise_dead_autocast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local playerID = caster:GetPlayerOwnerID()
	
	Timers:CreateTimer(function()	
		-- stop timer if the unit doesn't exist
		if not IsValidEntity(caster) then 
			--print("deleting banshee(timer)") 
			return 
		end

		-- if the ability is not toggled, don't proceed any further
		if ability:GetAutoCastState() and ability:GetCooldownTimeRemaining() == 0 then
			caster:CastAbilityNoTarget(ability, 0) 
		end
		
		return 1
	end)
	
end