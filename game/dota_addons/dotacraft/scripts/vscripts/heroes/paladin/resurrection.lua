--[[
	Author: Noya
	Date: 26.01.2015.
	Resurrects friendly units near the caster, using the corpse mechanic.
]]
function Resurrection( event )
	local caster = event.caster
	local ability = event.ability
	local player = caster:GetPlayerID()
	local team = caster:GetTeamNumber()
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	local max_units_resurrected = ability:GetLevelSpecialValueFor( "max_units_resurrected", ability:GetLevel() - 1 )

	-- Find all corpse entities in the radius and start the counter of units resurrected.
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), radius)
	local units_resurrected = 0

	-- Go through the units
	for _, unit in pairs(targets) do
		if units_resurrected < max_units_resurrected and unit.corpse_expiration ~= nil and unit:GetTeamNumber() == team then

			-- The corpse has a unit_name associated.
			local resurected = CreateUnitByName(unit.unit_name, unit:GetAbsOrigin(), true, caster, caster, team)
			resurected:SetControllableByPlayer(player, true)

			-- Apply modifiers for the summon properties
			ability:ApplyDataDrivenModifier(caster, resurected, "modifier_resurrection", nil)

			-- Leave no corpses
			resurected.no_corpse = true
			unit:RemoveSelf()

			-- Increase the counter of units resurrected
			units_resurrected = units_resurrected + 1
		end
	end
end

-- Denies casting if no friendly corpses near, with a message
function ResurrectionPrecast( event )
	local caster = event.caster
	local team = caster:GetTeamNumber()
	local ability = event.ability
	local targets = Entities:FindAllByNameWithin("npc_dota_creature", caster:GetAbsOrigin(), ability:GetCastRange()) 
	
	-- Remove units that aren't corpses or corpses of enemy units
	for k,unit in pairs(targets) do
		if unit.corpse_expiration == nil or unit:GetTeamNumber() ~= team then
			table.remove(targets,k)
		end
	end

	-- End the spell if no targets found
	if #targets == 0 then
		event.caster:Interrupt()
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "No Usable Corpses of Friendly Units Near" } )
	end
end