-- Picks up a corpse in range
function GetCorpse(keys)
	local caster = keys.caster
	local ability = keys.ability
	local playerID = caster:GetPlayerOwnerID()
	local search_radius = keys.ability:GetSpecialValueFor("search_radius")
	local stackCount = caster:GetModifierStackCount("modifier_corpses", caster)
	local max_corpses = keys.ability:GetSpecialValueFor("max_corpses")
	
	-- if equal to max allowed corpses, return
	if stackCount >= max_corpses then return end
	
	local corpses = Corpses:FindInRadiusOutside(playerID, caster:GetAbsOrigin(), search_radius)
	
	-- todo: move towards the corpse, instead of tele-grabbing them
	for _,corpse in pairs(corpses) do
		if not corpse.meat_wagon then
			AddCorpse(caster, corpse)
			break
		end
	end
end

-- Generates corpses every 15 seconds
function ExhumeCorpse(keys)
	local caster = keys.caster
	local ability = keys.ability
	local stackCount = caster:GetModifierStackCount("modifier_corpses", caster)
	local corpse_ability = caster:FindAbilityByName("undead_get_corpse")
	local max_corpses = corpse_ability:GetSpecialValueFor("max_corpses")

	-- if the unit doesn't have max corpses yet
	if stackCount < max_corpses then
		AddCorpse(caster, Corpses:CreateByNameOnPosition("undead_ghoul", caster:GetAbsOrigin(), caster:GetTeamNumber()))
		ability:StartCooldown(15)
	end	
end

-- Adds one corpse handle to the meat wagon
function AddCorpse(meat_wagon, corpse)
	corpse.meat_wagon = meat_wagon
	corpse.playerID = meat_wagon:GetPlayerOwnerID()
	corpse:AddNoDraw()
	corpse:StopExpiration()
	corpse:SetParent(meat_wagon,"attach_hitloc")
	table.insert(meat_wagon.corpses, corpse)

	-- Update indicators
	local stackCount = meat_wagon:GetModifierStackCount("modifier_corpses", meat_wagon)+1
	meat_wagon:SetModifierStackCount("modifier_corpses", meat_wagon, stackCount)		
	
	for i=1,stackCount do
		ParticleManager:SetParticleControl(meat_wagon.counter_particle, i, Vector(1,0,0))
	end
	if stackCount < 8 then
		for i=stackCount+1,8 do
			ParticleManager:SetParticleControl(meat_wagon.counter_particle, i, Vector(0,0,0))
		end
	end
end

-- Timer for picking up corpses
function GetCorpse_Autocast(keys)
	local caster = keys.caster
	local meat_wagon = caster
	local ability = keys.ability
	local search_radius = keys.ability:GetSpecialValueFor("search_radius")
	local max_corpses = keys.ability:GetSpecialValueFor("max_corpses")
	
	caster.corpses = {}
	caster.counter_particle = ParticleManager:CreateParticle("particles/custom/undead/corpse_counter.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)

	-- Removes one specific corpse from the meat wagon
	function meat_wagon:RemoveCorpse(corpse)
		corpse.meat_wagon = nil
		corpse:RemoveNoDraw()
		corpse:StartExpiration()
		corpse:SetParent(nil,"")
		local index = getIndexTable(meat_wagon.corpses, corpse)
		if index then
			table.remove(meat_wagon.corpses, index)
		end
		
		-- Update indicators
		local stackCount = meat_wagon:GetModifierStackCount("modifier_corpses", meat_wagon) - 1
		meat_wagon:SetModifierStackCount("modifier_corpses", meat_wagon, stackCount)

		if stackCount > 0 then
			for i=1,stackCount do
				ParticleManager:SetParticleControl(meat_wagon.counter_particle, i, Vector(1,0,0))
			end
		end
		for i=stackCount+1,8 do
			ParticleManager:SetParticleControl(meat_wagon.counter_particle, i, Vector(0,0,0))
		end
	end

	-- Removes and throws a corpse around the meat wagon
	function meat_wagon:ThrowCorpse(corpse)
		corpse = corpse or meat_wagon.corpses[#meat_wagon.corpses] -- Last one if no corpse is passed
		meat_wagon:RemoveCorpse(corpse)
		corpse:SetAbsOrigin(meat_wagon:GetAbsOrigin() + RandomVector(150))
		return corpse
	end

	Timers:CreateTimer(function()
		if not IsValidAlive(caster) or not caster:IsAlive() then return end	
		local stack_count = caster:GetModifierStackCount("modifier_corpses", caster) or 0
		
		-- Find corpses outside the meat wagon
		if stack_count < max_corpses then
			if caster:IsIdle() and ability:GetAutoCastState() and ability:IsCooldownReady() then
				local playerID = caster:GetPlayerOwnerID()
				local corpses = Corpses:FindInRadius(playerID, caster:GetAbsOrigin(), search_radius)
				for k,corpse in pairs(corpses) do
					if not corpse.meat_wagon then
						caster:CastAbilityNoTarget(ability, playerID)			
					end	
				end						
			end
		end
		return 1
	end)
end

-- Starts dropping corpses every 0.5 seconds or until ordered to do something else
function DropCorpse(keys)
	local caster = keys.caster
	local ability = keys.ability
	local get_corpse_ability = caster:FindAbilityByName("undead_get_corpse")
	local stackCount = caster:GetModifierStackCount("modifier_corpses", caster) 

	-- turn off autocast so that the meat wagon doesn't automatically pick up the corpse again
	if get_corpse_ability:GetAutoCastState() then
		get_corpse_ability:ToggleAutoCast()
	end
	-- cancel on order
	ability:ApplyDataDrivenModifier(caster,caster,"modifier_dropping_corpses",{})

	local stackCount = caster:GetModifierStackCount("modifier_corpses", caster)
	if stackCount == 0 then return end
	
	-- Pop the last corpse outside
	local corpse = caster:ThrowCorpse()

	if ability.drop_corpse_timer then Timers:RemoveTimer(ability.drop_corpse_timer) end
	ability.drop_corpse_timer = Timers:CreateTimer(0.5, function()
		if not IsValidEntity(caster) or not caster:IsAlive() then return end
		local stackCount = caster:GetModifierStackCount("modifier_corpses", caster)
		if caster:HasModifier("modifier_dropping_corpses") and stackCount > 0 then
			caster:ThrowCorpse()
			return 0.5
		end
	end)
end

-- Called OnOwnerDied, throwing all corpses immediately
function DropAllCorpses(keys)
	local caster = keys.caster
	local ability = keys.ability
	local origin = caster:GetAbsOrigin()
	
	for _,corpse in pairs(caster.corpses) do
		corpse.meat_wagon = nil
		corpse:RemoveNoDraw()
		corpse:SetParent(nil,"")
		caster:SetAbsOrigin(origin + RandomVector(150))
	end
	caster.corpses = {}
end

-------------------------------------------------------------------------------

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