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
		if corpse.corpse_expiration ~= nil then		
			local abilitylevel = ability:GetLevel()
			local spawnlocation = corpse:GetAbsOrigin()
			
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
		CreatedUnit:SetControllableByPlayer(0, true)
		CreatedUnit:AddNewModifier(CreatedUnit, nil, "modifier_kill", {duration = duration})
		ParticleManager:CreateParticle("particles/neutral_fx/skeleton_spawn.vpcf", 0, CreatedUnit)
		
		CreatedUnit.no_corpse = true
		table.insert(player.units, CreatedUnit)
	end

end

-- Denies casting if no corpses near, with a message
function AnimateDeadPrecast( event )
	local ability = event.ability
	local corpse = Entities:FindByModelWithin(nil, CORPSE_MODEL, event.caster:GetAbsOrigin(), ability:GetCastRange()) 
	local pID = event.caster:GetPlayerOwnerID()
	if corpse == nil then
		event.caster:Interrupt()
		SendErrorMessage(pID, "#error_no_usable_corpses")
		
		local mana = event.caster:GetMana()
		
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