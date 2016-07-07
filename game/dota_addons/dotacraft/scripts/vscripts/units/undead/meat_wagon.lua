-- ability that picks up bodies
function get_corpse(keys)
	local caster = keys.caster
	local ability = keys.ability
	local playerID = caster:GetPlayerOwnerID()
	local search_radius = keys.ability:GetSpecialValueFor("search_radius")
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)
	local max_corpses = keys.ability:GetSpecialValueFor("max_corpses")
	
	-- if equal to max allowed corpses, return
	if StackCount >= max_corpses then return end
	
	local corpses = Corpses:FindInRadius(playerID, caster:GetAbsOrigin(), search_radius)
	
	-- todo: should move towards the corpse, instead of tele-grabbing them

	for _,corpse in pairs(corpses) do
		-- increase count by 1
		IncreaseCorpseCount(keys)
		
		-- save corpse name
		caster.corpse_name[StackCount] = corpse.unit_name
		
		-- Leave no corpses
		corpse.no_corpse = true
		corpse:RemoveSelf()
		return
	end
end

-- autocast for picking up bodies
function get_corpse_autocast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local search_radius = keys.ability:GetSpecialValueFor("search_radius")
	local max_corpses = keys.ability:GetSpecialValueFor("max_corpses")
	
	Timers:CreateTimer(function()
		-- stop timer if the unit doesn't exist
		if not IsValidAlive(caster) then return end	

		local StackCount = caster:GetModifierStackCount("modifier_corpses", caster) or 0
		
		-- if not equal to max corpses
		if StackCount < max_corpses then
			-- if ability is OFF Cooldown and AutoCastState
			if ability:GetAutoCastState() and caster:IsIdle() and ability:GetCooldownTimeRemaining() == 0 then
				local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), search_radius)
				
				for k,corpse in pairs(targets) do
					if corpse.corpse_expiration ~= nil and not corpse.being_eaten then
						caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())			
					end	
				end						
			end
		end
		
		return 0.2
	end)
	
end

function drop_single_corpse(keys)
	DecreaseCorpseCount(keys, 3)
	
	return CreateCorpses(keys, 3)
end

-- Drop 1 corpse, called every 0.5 seconds
function drop_corpse(keys)
	local caster = keys.caster
	local ability = keys.ability
	local get_corpse_ability = caster:FindAbilityByName("undead_get_corpse")
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster) 

	-- turn off autocast so that the meat wagon doesn't automatically pick up the corpse again
	if get_corpse_ability:GetAutoCastState() then
		get_corpse_ability:ToggleAutoCast()
	end

	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)
	if StackCount == 0 then
		return
	end 
	
	DecreaseCorpseCount(keys, 1)
	CreateCorpses(keys, 1)
end

function drop_all_corpses(keys)
	local caster = keys.caster
	local ability = keys.ability
	local get_corpse_ability = caster:FindAbilityByName("undead_get_corpse")
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)
	
	print("drop_all_corpses StackCount: ", stackCount)

	if StackCount > 0 then
		for i=1,stackCount do
			CreateCorpses(keys, 1)
		end
	end
end

-- create the corpses
function CreateCorpses(keys, state)
	local caster = keys.caster
	local randomX = RandomInt(-100,100)
	local randomY = RandomInt(-100,100)
	local StackCount 
	
	-- state 3 is from cannibalize
	if state ~= 3 then 
		caster:GetModifierStackCount("modifier_corpses", caster) 
	else
		keys.ability.corpse:GetModifierStackCount("modifier_corpses", keys.ability.corpse) 
	end	
	
-- taken from dotacraft.lua with some changes
	-- Create and set model
	local targetposition
	if state == 1 then
		targetposition = keys.caster:GetAbsOrigin()
	elseif state == 3 then
		targetposition = keys.ability.corpse:GetAbsOrigin()
	else
	-- if 2(can be anything else to)
		targetposition = keys.target:GetAbsOrigin()
	end
	
	local corpse = CreateUnitByName("dummy_unit", targetposition + Vector(randomX, randomY, targetposition.z), true, nil, nil, caster:GetTeamNumber())
	corpse:SetModel(CORPSE_MODEL)
	
	-- Keep a reference to its name and expire time
	corpse.corpse_expiration = GameRules:GetGameTime() + CORPSE_DURATION
	
	-- state 3 is from cannibalize
	if state ~= 3 then
		corpse.unit_name = caster.corpse_name[StackCount]
	else
		corpse.unit_name = keys.ability.corpse.corpse_name[StackCount]
		corpse.being_eaten = true
	end
	
	-- corpse timer
	Timers:CreateTimer(CORPSE_DURATION, function()
		if corpse and IsValidEntity(corpse) then
			print("removing corpse")
			corpse:RemoveSelf()
		end
	end)
	
	return corpse
end

function meat_wagon_disease_cloud(keys)
	local target = keys.target
	local caster = keys.caster
	local RADIUS = 50
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)
	local MAX_CLOUDS = keys.ability:GetSpecialValueFor("maximum_clouds")
	
	-- initialise table
	if not caster.disease_clouds then
		caster.disease_clouds = {}
	end
	
	-- if caster has already MAX_CLOUDS, remove the first cloud
	if #caster.disease_clouds == MAX_CLOUDS then
		remove_disease_cloud(keys)
	end
	
	local cloud = FindUnitsInRadius(caster:GetTeamNumber(), 
							target:GetAbsOrigin(), 
							nil, 
							RADIUS, 
							DOTA_UNIT_TARGET_TEAM_FRIENDLY, 
							DOTA_UNIT_TARGET_ALL, 
							DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 
							FIND_CLOSEST, 
							false)
							
	local AnyClouds = false
	for k,clouds in pairs(cloud) do
	-- if unit is found with name set true to finding a cloud
		if clouds:GetUnitName() == "dummy_unit_disease_cloud" then
			AnyClouds = true
		end
	end
	
	if not AnyClouds then
		local diseaseDummy = CreateUnitByName("dummy_unit_disease_cloud", target:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())
		diseaseDummy:AddNewModifier(diseaseDummy, nil, "modifier_kill", {duration = 120})
		insert_into_table(caster.disease_clouds, diseaseDummy)
	end
	-- if he has stacks, throw corpse
	if StackCount > 0 then
		CreateCorpses(keys, 2)
		DecreaseCorpseCount(keys, 1)
	end
end

-- insert unit into the first nil index it finds inside the table, this will never go past 3 due to remove_disease_cloud
function insert_into_table(disease_clouds, dummy)
	for i=1, #disease_clouds+1, 1 do
		if disease_clouds[i] == nil then
			disease_clouds[i] = dummy
			break
		end
	end
end

-- remove the first cloud unit and push all units forward 1 and then set third index to nil
function remove_disease_cloud(keys)
	local caster = keys.caster

	for i=1, #caster.disease_clouds, 1 do	
		if i == 1 then
			-- set all properties to remove corpse
			caster.disease_clouds[i].corpse_expiration = nil
			caster.disease_clouds[i].no_corpse = true
		
			-- remove itself
			caster.disease_clouds[i]:RemoveSelf()	
		else
			caster.disease_clouds[i-1] = caster.disease_clouds[i]
			
			-- if third index(which we want removed)
			if i == 3 then
				caster.disease_clouds[i] = nil
			end
			
		end
	end
end

-- generate corpses every 15seconds
function exhume_corpse(keys)
	local caster = keys.caster
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)
	local corpse_ability = caster:FindAbilityByName("undead_get_corpse")
	local MAX_CORPSES = corpse_ability:GetSpecialValueFor("max_corpses")

	-- if the unit doesn't have max corpses yet
	if StackCount < MAX_CORPSES then
		IncreaseCorpseCount(keys)
		caster.corpse_name[StackCount] = "undead_ghoul"
	end	
end

function IncreaseCorpseCount(keys)
	local caster = keys.caster
	local get_corpse_ability = caster:FindAbilityByName("undead_get_corpse")
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster) + 1
		
	caster:SetModifierStackCount("modifier_corpses", caster, StackCount)
		
	for i=1,StackCount do
		ParticleManager:SetParticleControl(caster.counter_particle, i, Vector(1,0,0))
	end
	if StackCount < 8 then
		for i=StackCount+1,8 do
			ParticleManager:SetParticleControl(caster.counter_particle, i, Vector(0,0,0))
		end
	end
end

function DecreaseCorpseCount (keys, state)
	local caster
	if state == 1 then
		caster = keys.caster
	else
		caster = keys.ability.corpse
	end
	
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster) - 1
		
	caster:SetModifierStackCount("modifier_corpses", caster, StackCount)

	if StackCount > 0 then
		for i=1,StackCount do
			ParticleManager:SetParticleControl(caster.counter_particle, i, Vector(1,0,0))
		end
	end
	for i=StackCount+1,8 do
		ParticleManager:SetParticleControl(caster.counter_particle, i, Vector(0,0,0))
	end
end

-- Automatically toggled on
function ToggleOnAutocast(event)
	local caster = event.caster
	local ability = event.ability

	-- initialise corpse_name table
	if not caster.corpse_name then
		caster.corpse_name = {}
	end
	
	caster.counter_particle = ParticleManager:CreateParticle("particles/custom/undead/corpse_counter.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
	
	ability:ToggleAutoCast()
end