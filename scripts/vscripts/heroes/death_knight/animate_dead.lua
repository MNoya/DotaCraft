function animate_dead_cast( event )
	local owner = event.caster
	local ability = event.ability
	local player_id = event.caster:GetPlayerID()
	local team_id = event.caster:GetTeamNumber()
	local number_of_resurrections = 0
	local group = Entities:FindAllByNameWithin("npc_dota_creature", event.caster:GetAbsOrigin(), ability:GetCastRange())
	local resurrections_duration = event.ability:GetLevelSpecialValueFor( "resurrections_duration", (ability:GetLevel() - 1))
	local resurrections_limit = event.ability:GetLevelSpecialValueFor( "resurrections_limit", (ability:GetLevel() - 1))
	for number, unit in pairs(group) do
		if number_of_resurrections < resurrections_limit and unit.corpse_expiration ~= nil then
			local resurected = CreateUnitByName(unit.unit_name, unit:GetAbsOrigin(), true, owner, owner, team_id)
			resurected:SetControllableByPlayer(player_id, true)
			resurected:AddNewModifier(owner, event.ability, "modifier_kill", {duration = resurrections_duration})
			resurected:AddNewModifier(owner, event.ability, "modifier_invulnerable", nil)
			unit:RemoveSelf()
			number_of_resurrections = number_of_resurrections + 1
		end
	end
end