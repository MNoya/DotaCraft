--[[
		still need to complete longevity and include it into the duration 
--]]

function undead_raise_dead ( keys )
	local target = keys.target
	local caster = keys.caster
	local ability = keys.ability

	-- durations have be inverted due to some weird parsing bug
	local RADIUS = keys.ability:GetSpecialValueFor("radius")
	local SKELETON_DURATION = keys.ability:GetSpecialValueFor("duration")
	
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), RADIUS)
	
	for k,corpse in pairs(targets) do
		if corpse.corpse_expiration ~= nil then		
			local abilitylevel = ability:GetLevel()
			local spawnlocation = corpse:GetAbsOrigin()
			
			local ManaCost = ability:GetManaCost(-1)
			caster:SetMana(caster:GetMana() - ManaCost)
			ability:StartCooldown(ability:GetCooldown(-1))
			
			-- create units
			CreateUnit(caster, spawnlocation, abilitylevel, SKELETON_DURATION)
			
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
	end
end

function undead_raise_dead_autocast(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	Timers:CreateTimer(function()	
	print("lol")
		-- stop timer if the unit doesn't exist
		if not IsValidEntity(caster) then 
			--print("deleting banshee(timer)") 
			return 
		end

		-- if the ability is not toggled, don't proceed any further
		if ability:GetAutoCastState() and ability:GetCooldownTimeRemaining() == 0 then
			undead_raise_dead(keys)
		end
		
		return 1
	end)
	
end