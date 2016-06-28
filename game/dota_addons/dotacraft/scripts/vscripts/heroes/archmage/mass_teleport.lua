--[[
	Author: Noya
	Date: 26.01.2015.
	Keeps track of the units that will be teleported
]]
function MassTeleportStart( event )
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	local targets = event.target_entities
	
	ability.teleport_units = targets
	local number = #targets+1

	print("Attempting to teleport "..number.." targets to "..target:GetUnitName())

	-- Apply particle on the units, destroyed when the channel stops
	local particleName = "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_recall.vpcf"
	for _,unit in pairs(targets) do
		unit.teleport_particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, unit)
	end

	if not IsCustomBuilding(target) then
		ability:ApplyDataDrivenModifier(caster,target,"modifier_mass_teleport_target",{})
	end		
end

-- Stops the channeling sound and particles
function MassTeleportStop( event )
	local caster = event.caster
	local ability = event.ability
	local targets = ability.teleport_units

	caster:StopSound("Hero_KeeperOfTheLight.Recall.Cast")
	for _,unit in pairs(targets) do
		ParticleManager:DestroyParticle(unit.teleport_particle,false)
	end
end

-- Teleports every initial target to the destination
function MassTeleport( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local targets = ability.teleport_units
	
    for _,unit in pairs(targets) do
     	FindClearSpaceForUnit(unit, target:GetAbsOrigin(), true)
     	ParticleManager:DestroyParticle(unit.teleport_particle,false)
     	unit:Stop()
    end
    FindClearSpaceForUnit(caster, target:GetAbsOrigin(), true)
    caster:StopSound("Hero_KeeperOfTheLight.Recall.Cast")
    print("Teleported to ",target:GetUnitName())
end

-- Check if the target is a custom building
function BuildingCheck( event )
	local ability = event.ability
	local caster = event.caster
	local target = event.target
	local pID = caster:GetPlayerID()
end