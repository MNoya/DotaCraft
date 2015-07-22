--[[
	Author: Noya
	Date: April 2, 2015
	Creates a dummy unit to apply the Cloud thinker modifier
]]
function CloudStart( event )
	-- Variables
	local caster = event.caster
	local point = event.target_points[1]

	caster.cloud_dummy = CreateUnitByName("dummy_unit_vulnerable", point, false, caster, caster, caster:GetTeam())
	event.ability:ApplyDataDrivenModifier(caster, caster.cloud_dummy, "modifier_cloud_thinker", nil)
end

function CloudEnd( event )
	local caster = event.caster
	local ability = event.ability
	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1 )
	local origin = caster.cloud_dummy:GetAbsOrigin()

	local targets = FindUnitsInRadius(caster:GetTeamNumber(), origin, nil, radius, 
						   DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)


	print("Found ",#targets," units in "..radius.." radius of ",origin)

	for _,target in pairs(targets) do
		target:RemoveModifierByName("modifier_cloud")  -- This has the issue of not being able to detect different clouds
		-- If one is cancelled but there are others channeling over the same place, the whole effect is lost :(
		-- Use multiple stacks instead?
	end
	caster.cloud_dummy:RemoveSelf()
end


-- Applies the cloud modifier only to ranged buildings (i.e. towers)
function ApplyCloud( event )
	local caster = event.caster
	local ability = event.ability
	local targets = event.target_entities
	local cloud_duration = ability:GetLevelSpecialValueFor("cloud_duration", ability:GetLevel() - 1 )

	for _,target in pairs(targets) do
		local isBuilding = target:FindAbilityByName("ability_building")
		local isTower = target:FindAbilityByName("ability_tower")
		if target:IsRangedAttacker() and (isBuilding or isTower) then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_cloud", { duration = cloud_duration })
		end
	end
end

-- Prevents casting shackles on anything that doesnt fly
function AerialShacklesCheck( event )
	local caster = event.caster
	local pID = caster:GetOwner():GetPlayerID()
	local target = event.target

	if not target:HasFlyMovementCapability() then
		caster:Interrupt()
		SendErrorMessage(pID, "#error_must_target_air")
	end
end

-- Loses flying capability
function LoseFlying( event )
	local target = event.target
	target:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
end

-- Moves down a bit
function LoseHeight( event )
	local target = event.target
	local origin = target:GetAbsOrigin()
	local groundPos = GetGroundPosition(origin, target)

	print(origin.z, groundPos.z)
	if origin.z+128 > groundPos.z then
		target:SetAbsOrigin(Vector(origin.x, origin.y, origin.z - 2))
	end
end

-- Gains flying capability
function ReGainFlying( event )
	local target = event.target
	local origin = target:GetAbsOrigin()
	
	target:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
end