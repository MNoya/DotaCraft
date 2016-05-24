modifier_client_convars = class({})

function modifier_client_convars:OnCreated( params )
    if IsClient() then
        SendToConsole("dota_player_add_summoned_to_selection 0")
        SendToConsole("dota_player_units_auto_attack 1")
        SendToConsole("dota_player_units_auto_attack_after_spell 1")
    end
end

function modifier_client_convars:IsHidden()
    return true
end