function SpawnUnit( event )
	local caster = event.caster
	local playerID = caster:GetPlayerOwnerID()
	local hero = caster:GetOwner()
	local unit_name = event.UnitName
	local position = caster.initial_spawn_position
	local teamID = caster:GetTeam()

	-- Adjust Mountain Giant secondary unit
	if Players:HasResearch( playerID, "nightelf_research_resistant_skin") then
		unit_name = unit_name.."_resistant_skin"
	end

	-- Adjust Troll Berkserker upgraded unit
	if Players:HasResearch( playerID, "orc_research_berserker_upgrade") then
		unit_name = "orc_troll_berserker"
	end
		
	local unit = CreateUnitByName(unit_name, position, true, hero, hero, caster:GetTeamNumber())
	unit:AddNewModifier(caster, nil, "modifier_phased", { duration = 0.03 })
	unit:SetOwner(hero)
	unit:SetControllableByPlayer(playerID, true)
	
	event.target = unit
	MoveToRallyPoint(event)

	-- Add MG upgrades
	if string.match(unit_name, "mountain_giant") then
		ApplyMultiRankUpgrade(unit, "nightelf_research_strength_of_the_wild", "weapon")
   		ApplyMultiRankUpgrade(unit, "nightelf_research_reinforced_hides", "armor")
   	end

   	-- Recolor Huskar
   	if string.match(unit_name, "orc_troll_berserker") then
   		unit:SetRenderColor(255, 255, 0)
   	end

   	-- Add Troll Headhunter/Berserker upgrades
   	if string.match(unit_name, "orc_troll") then
   		ApplyMultiRankUpgrade(unit, "orc_research_ranged_weapons", "weapon")
   		ApplyMultiRankUpgrade(unit, "orc_research_unit_armor", "armor")
   	end

end

-- Creates a rally point flag for this unit, removing the old one if there was one
function SetRallyPoint( event )
	local caster = event.caster
	if not HasTrainAbility( caster ) then return end

	Timers:CreateTimer(2/30, function()
		local origin = caster:GetAbsOrigin()
		
		-- Find vector towards 0,0,0 for the initial rally point
		local forwardVec = Vector(0,0,0) - origin
		forwardVec = forwardVec:Normalized()

		-- For the initial rally point, get point away from the building looking towards (0,0,0)
		local position = origin + forwardVec * 250
		position = GetGroundPosition(position, caster)

		-- Keep track of this position so that every unit is autospawned there (avoids going around the)
		caster.initial_spawn_position = position

		caster.flag_type = "position"
		caster.flag = position
	end)
end

-- Queues a movement command for the spawned unit to the rally point
-- Also adds the unit to the players army and looks for upgrades
function MoveToRallyPoint( event )
	local caster = event.caster
	local target = event.target
	local entityIndex = target:GetEntityIndex() -- The spawned unit
	local playerID = caster:GetPlayerOwnerID()

	-- Set the builders idle when they spawn
	if IsBuilder(target) then 
		target.state = "idle" 
	end

	dotacraft:ResolveRallyPointOrder(target, caster)

	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	target:SetOwner(hero)
	Players:AddUnit(playerID, target)
	CheckAbilityRequirements(target, playerID)
end

function GetInitialRallyPoint( event )
	local caster = event.caster
	local initial_spawn_position = caster.initial_spawn_position

	local result = {}
	if initial_spawn_position then
		table.insert(result,initial_spawn_position)
	else
		print("Fail, no initial rally point, this shouldn't happen")
	end

	return result
end