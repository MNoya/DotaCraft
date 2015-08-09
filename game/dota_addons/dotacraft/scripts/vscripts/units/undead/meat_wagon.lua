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
		if corpse.corpse_expiration ~= nil and not corpse.being_eaten then		

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
	
		DecreaseCorpseCount(keys, 1)
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
		DecreaseCorpseCount(keys, 1)		
		CreateCorpses(keys, 1)
		
		return 0.04
	end)
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
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)
		
	caster:SetModifierStackCount("modifier_corpses", caster, StackCount + 1)
		
	for i=1,StackCount, 8 do
		ParticleManager:SetParticleControl(caster.counter_particle, i, Vector(1,0,0))
	end
end

function DecreaseCorpseCount (keys, state)
local caster
	if state == 1 then
		caster = keys.caster
	else
		caster = keys.ability.corpse
	end
	
	local get_corpse_ability = caster:FindAbilityByName("undead_get_corpse")
	local StackCount = caster:GetModifierStackCount("modifier_corpses", caster)
		
	caster:SetModifierStackCount("modifier_corpses", caster, StackCount - 1)

	for i=1, StackCount,8 do
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

function AttackGround( event )
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]
	local start_time = caster:GetAttackAnimationPoint() -- Time to wait to fire the projectile
	local speed = caster:GetProjectileSpeed()
	local particle = "particles/neutral_fx/mud_golem_hurl_boulder.vpcf"
	local minimum_range = ability:GetSpecialValueFor("minimum_range")

	if (point - caster:GetAbsOrigin()):Length() < minimum_range then
		SendErrorMessage(caster:GetPlayerOwnerID(), "#error_minimum_range")
		caster:Interrupt()
		return
	end

	ToggleOn(ability)

	-- Create a dummy to fake the attacks
	if IsValidEntity(ability.attack_ground_dummy) then ability.attack_ground_dummy:RemoveSelf() end
	ability.attack_ground_dummy = CreateUnitByName("dummy_unit", point, false, nil, nil, DOTA_TEAM_NEUTRALS)

	ability.attack_ground_timer = Timers:CreateTimer(function()
		caster:StartGesture(ACT_DOTA_ATTACK)
		ability.attack_ground_timer_animation = Timers:CreateTimer(start_time, function() 
			local projectileTable = {
				EffectName = particle,
				Ability = ability,
				Target = ability.attack_ground_dummy,
				Source = caster,
				bDodgeable = true,
				bProvidesVision = true,
				vSpawnOrigin = caster:GetAbsOrigin(),
				iMoveSpeed = 900,
				iVisionRadius = 100,
				iVisionTeamNumber = caster:GetTeamNumber(),
				iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
			}
			ProjectileManager:CreateTrackingProjectile( projectileTable )

		end)
		local time = 1 / caster:GetAttacksPerSecond()	
		return 	time
	end)

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_attacking_ground", {})
end

function AttackGroundDamage( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local position = target:GetAbsOrigin()
	local damage = caster:GetAttackDamage()
	local splash_radius = ability:GetSpecialValueFor("splash_radius")
	local AbilityDamageType = ability:GetAbilityDamageType()

	local damage_to_trees = 10
	local trees = GridNav:GetAllTreesAroundPoint(position, 100, true)

	for _,tree in pairs(trees) do
		if tree:IsStanding() then
			tree.health = tree.health - damage_to_trees

			-- Hit tree particle
			local particleName = "particles/custom/tree_pine_01_destruction.vpcf"
			local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(particle, 0, tree:GetAbsOrigin())
		end
		if tree.health <= 0 then
			tree:CutDown(caster:GetPlayerOwnerID())
		end
	end

	-- Hit ground particle
	ParticleManager:CreateParticle("particles/units/heroes/hero_magnataur/magnus_dust_hit.vpcf", PATTACH_ABSORIGIN, target)
	
	meat_wagon_disease_cloud(event)
	
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, splash_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _,enemy in pairs(enemies) do
		print(_,enemy,enemy:GetUnitName(),enemy:GetHealth())
		damage = damage * GetDamageForAttackAndArmor( GetAttackType(caster), GetArmorType(enemy) )

		ApplyDamage({ victim = enemy, attacker = caster, damage = damage, damage_type = AbilityDamageType })
	end
	
end

function StopAttackGround( event )	
	local caster = event.caster
	local ability = event.ability
	
	if IsValidEntity(ability.attack_ground_dummy) then ability.attack_ground_dummy:RemoveSelf() end

	Timers:RemoveTimer(ability.attack_ground_timer)
	Timers:RemoveTimer(ability.attack_ground_timer_animation)

	ToggleOff(ability)

	caster:RemoveGesture(ACT_DOTA_ATTACK)
end