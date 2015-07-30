-- ability that picks up bodies
function get_corpse(keys)
	local caster = keys.caster
	local ability = keys.ability

	-- durations have be inverted due to some weird parsing bug
	local RADIUS = keys.ability:GetSpecialValueFor("radius")
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)
	local MAX_CORPSES = keys.ability:GetSpecialValueFor("max_corpses")
	
	-- if equal to max allowed corpses, return
	if StackCount >= MAX_CORPSES then
		return
	end
	
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), RADIUS)
	
	for k,corpse in pairs(targets) do
		if corpse.corpse_expiration ~= nil then		

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
end

-- autocast for picking up bodies
function get_corpse_autocast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local RADIUS = keys.ability:GetSpecialValueFor("radius")
	local MAX_CORPSES = keys.ability:GetSpecialValueFor("max_corpses")
	
	Timers:CreateTimer(function()
		local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)
		-- stop timer if the unit doesn't exist
		if not IsValidEntity(caster) then 
			return 
		end	
		
		-- if not equal to max corpses
		if StackCount < MAX_CORPSES then
			-- if ability is OFF Cooldown and AutoCastState
			if ability:GetCooldownTimeRemaining() == 0 and ability:GetAutoCastState() then
				local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), RADIUS)
				
				for k,corpse in pairs(targets) do
					if corpse.corpse_expiration ~= nil then
						caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())			
					end	
				end						
			end
		end
		
		return 0.2
	end)
	
end

-- dropses corses periodically
function drop_corpse(keys)
	local caster = keys.caster
	local ability = keys.ability
	local get_corpse_ability = caster:FindAbilityByName("undead_get_corpse")
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster) 

	-- turn off autocast so that the meat wagon doesn't automatically pick up the corpse again
	if get_corpse_ability:GetAutoCastState() then
		get_corpse_ability:ToggleAutoCast()
	end
	
	Timers:CreateTimer(caster:GetEntityIndex().."_meat_wagon", {
	callback = function()
		local StackCount = caster:GetModifierStackCount("modifier_corpses", caster) 
	
		if StackCount == 0 then
			return
		end
	
		DecreaseCorpseCount(keys)
		CreateCorpses(keys, 1)
		
		return 0.5
	end})
end

-- called on death to drop all corpses
function drop_all_corpse(keys)
	local caster = keys.caster
	local ability = keys.ability
	local get_corpse_ability = caster:FindAbilityByName("undead_get_corpse")
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)

	-- turn off autocast so that the meat wagon doesn't automatically pick up the corpse again
	if get_corpse_ability:GetAutoCastState() then
		get_corpse_ability:ToggleAutoCast()
	end
	
	Timers:CreateTimer(function()
		-- check current stack count and generate random pos
		StackCount = caster:GetModifierStackCount("modifier_corpses", caster) 

		if StackCount == 0 then
			return
		end
	
		-- remove 1 modifier stack and create corpses accordingly
		DecreaseCorpseCount(keys)		
		CreateCorpses(keys, 1)
		
		return 0.04
	end)

end

-- create the corpses
function CreateCorpses(keys, state)
	local caster = keys.caster
	local randomX = RandomInt(-100,100)
	local randomY = RandomInt(-100,100)
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster) 
		
-- taken from dotacraft.lua with some changes
	-- Create and set model
	local targetposition
	if state == 1 then
		targetposition = keys.caster:GetAbsOrigin()
	else -- if 2(can be anything else to)
		targetposition = keys.target:GetAbsOrigin()
	end
	
	local corpse = CreateUnitByName("dummy_unit", targetposition + Vector(randomX, randomY, targetposition.z), true, nil, nil, caster:GetTeamNumber())
	corpse:SetModel(CORPSE_MODEL)
	
	-- Keep a reference to its name and expire time
	corpse.corpse_expiration = GameRules:GetGameTime() + CORPSE_DURATION
	corpse.unit_name = caster.corpse_name[StackCount]
	
	-- corpse timer
	Timers:CreateTimer(CORPSE_DURATION, function()
		if corpse and IsValidEntity(corpse) then
			print("removing corpse")
			corpse:RemoveSelf()
		end
	end)
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
		DecreaseCorpseCount(keys)
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
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)
		
	caster:SetModifierStackCount("modifier_corpses", caster, StackCount + 1)
end

function DecreaseCorpseCount (keys)
	local caster = keys.caster
	local get_corpse_ability = caster:FindAbilityByName("undead_get_corpse")
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)
		
	caster:SetModifierStackCount("modifier_corpses", caster, StackCount - 1)	
end
-- Automatically toggled on
function ToggleOnAutocast(event)
	local caster = event.caster
	local ability = event.ability

	-- initialise corpse_name table
	if not caster.corpse_name then
		caster.corpse_name = {}
	end
	
	ability:ToggleAutoCast()
end