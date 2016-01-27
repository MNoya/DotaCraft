function dotacraft:TrackIdleWorkers( hero )
	local player = hero:GetPlayerOwner()
	local playerID = hero:GetPlayerID()
	-- Keep track of the Idle Builders and send them to the panorama UI every time the count updates
	Timers:CreateTimer(1, function() 
		local idle_builders = {}
		local playerUnits = Players:GetUnits(playerID)
		for k,unit in pairs(playerUnits) do
			if IsValidAlive(unit) and IsBuilder(unit) and IsIdleBuilder(unit) then
				table.insert(idle_builders, unit:GetEntityIndex())
			end
		end
		if #idle_builders ~= #hero.idle_builders then
			--print("#Idle Builders changed: "..#idle_builders..", was "..#hero.idle_builders)
			hero.idle_builders = idle_builders
			CustomGameEventManager:Send_ServerToPlayer(player, "player_update_idle_builders", { idle_builder_entities = idle_builders })
		end
		return 0.3
	end)
end

