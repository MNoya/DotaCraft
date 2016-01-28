function dotacraft:RepositionPlayerCamera( event )
	DeepPrintTable(event)
	local pID = event.PlayerID
	local entIndex = event.entIndex
	local entity = EntIndexToHScript(entIndex)
	if entity and IsValidEntity(entity) then
		PlayerResource:SetCameraTarget(pID, entity)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(pID, nil)
		end)
	end
end

function dotacraft:RotateCamera( playerID )
    local player = PlayerResource:GetPlayer(playerID)
    CustomGameEventManager:Send_ServerToPlayer(player, "rotate_camera", {})
    GameRules:SendCustomMessage("Arteezy was left", 0, 0)
end