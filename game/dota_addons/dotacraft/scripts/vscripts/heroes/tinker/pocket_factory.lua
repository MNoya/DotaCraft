--[[
	Author: Noya
	Date: January 2016
	Creates a building, adds ability to spawn units every at an interval which decreases with engineering_upgrade levels
]]
function BuildPocketFactory( event )
	-- Variables
	local caster = event.caster
	local ability = event.ability
	local point = event.target_points[1]
	local factory_duration =  ability:GetLevelSpecialValueFor( "factory_duration" , ability:GetLevel() - 1  )
	local ability_level = ability:GetLevel()
	local building_name = "tinker_pocket_factory_building"..ability_level
	local construction_size = BuildingHelper:GetConstructionSize(building_name)
	local pathing_size = BuildingHelper:GetBlockPathingSize(building_name)

	-- Create the building, set to time out after a duration
	caster.pocket_factory = BuildingHelper:PlaceBuilding(caster:GetPlayerOwner(), building_name, point, construction_size, pathing_size, 0)
	caster.pocket_factory:AddNewModifier(caster, nil, "modifier_kill", {duration = factory_duration})
	caster.pocket_factory.no_corpse = true

	-- Add the ability and set its level
	caster.pocket_factory:AddAbility("tinker_pocket_factory_train_goblin")
	local spawn_ability = caster.pocket_factory:FindAbilityByName("tinker_pocket_factory_train_goblin")
	spawn_ability:SetLevel(ability_level)
end

-- When the building is created, check level of engineering and start spawning every interval
function StartGoblinSpawn( event )
	local caster = event.caster
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local player = hero:GetPlayerID()
	local ability = event.ability
	local ability_level = ability:GetLevel()
	local spawn_ratio = ability:GetLevelSpecialValueFor( "spawn_ratio" , ability:GetLevel() - 1  )
	local goblin_duration = ability:GetLevelSpecialValueFor( "goblin_duration" , ability:GetLevel() - 1  )
	local engineering_ability = hero:FindAbilityByName("tinker_engineering_upgrade")
	local unit_name = "tinker_clockwerk_goblin"
	local goblin_ability_name = "tinker_clockwerk_goblin_kaboom"

	-- If the upgrade is found, check if it has been leveled up
	local engineering_level = 0
	if engineering_ability and engineering_ability:GetLevel() > 0 then

		-- Get the spawn timer reduction value and update
		local spawn_eng_reduce = engineering_ability:GetLevelSpecialValueFor( "factory_spawn_time_reduced" , engineering_level -1  )
		spawn_ratio = spawn_ratio - spawn_eng_reduce
	end

	-- Display the spawn ability as cooling down, this is purely cosmetic but helps showing the interval
	ability:StartCooldown(spawn_ratio)

	-- Start the repeated spawn
	Timers:CreateTimer(spawn_ratio, function()

		if caster and IsValidEntity(caster) and caster:IsAlive() then
			-- Start another cooldown
			ability:StartCooldown(spawn_ratio)

			-- Create the unit, making it controllable by the building owner, and time out after a duration.
			local goblin = CreateUnitByName(unit_name, caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
			goblin:SetControllableByPlayer(player, true)
			goblin:AddNewModifier(caster, nil, "modifier_kill", {duration = goblin_duration})
			goblin.no_corpse = true

			-- Move to rally point
			MoveToRallyPoint({caster=caster, target=goblin})

			-- Add the ability and set its level to the main ability level
			goblin:AddAbility(goblin_ability_name)
			local goblin_ability = goblin:FindAbilityByName(goblin_ability_name)
			goblin_ability:SetLevel(ability_level)

			-- Spawn sound
			goblin:EmitSound("Hero_Tinker.March_of_the_Machines.Cast")

			return spawn_ratio
		end
	end)

end