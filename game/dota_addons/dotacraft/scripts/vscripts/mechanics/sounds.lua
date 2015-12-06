if not Sounds then
  Sounds = class({})
end

function Sounds:Start()
    
end

function Sounds:EmitSoundOnClient( playerID, sound )
    local player = PlayerResource:GetPlayer(playerID)

    if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "emit_client_sound", {sound=sound})
        return true
    else
        print("ERROR - No player with ID",playerID)
    end
    return false
end

Sounds:Start()