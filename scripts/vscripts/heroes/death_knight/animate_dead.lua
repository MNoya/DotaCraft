--[[
	Author: Noya
	Date: 21.01.2015.
	Resurrects units near the caster, using the corpse mechanic.
]]
function AnimateDead( event )
	local caster = event.caster
	local ability = event.ability
	local player = event.caster:GetPlayerID()
	local team = event.caster:GetTeamNumber()
	local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	local max_units_resurrected = ability:GetLevelSpecialValueFor( "max_units_resurrected", ability:GetLevel() - 1 )

	-- Find all corpse entities in the radius and start the counter of units resurrected.
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), radius)
	local units_resurrected = 0

	-- Go through the units
	for _, unit in pairs(targets) do
		if units_resurrected < max_units_resurrected and unit.corpse_expiration ~= nil then

			-- The corpse has a unit_name associated.
			local resurected = CreateUnitByName(unit.unit_name, unit:GetAbsOrigin(), true, caster, caster, team)
			resurected:SetControllableByPlayer(player, true)

			-- Apply modifiers for the summon properties
			resurected:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
			ability:ApplyDataDrivenModifier(caster, resurected, "modifier_animate_dead", nil)

			-- Leave no corpses
			resurected.no_corpse = true
			unit:RemoveSelf()

			-- Increase the counter of units resurrected
			units_resurrected = units_resurrected + 1
		end
	end
end

-- Denies casting if no corpses near, with a message
function AnimateDeadPrecast( event )
	local ability = event.ability
	local corpse = Entities:FindByModelWithin(nil, CORPSE_MODEL, event.caster:GetAbsOrigin(), ability:GetCastRange()) 
	local pID = event.caster:GetPlayerID()
	if corpse == nil then
		event.caster:Interrupt()
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "No Usable Corpses Near" } )
	end
end