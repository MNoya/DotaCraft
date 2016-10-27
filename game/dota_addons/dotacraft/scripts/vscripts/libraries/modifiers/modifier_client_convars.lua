modifier_client_convars = class({})

function modifier_client_convars:OnCreated( params )
    if IsClient() then
        SendToConsole("dota_player_add_summoned_to_selection 0")
        SendToConsole("dota_player_units_auto_attack_mode 2") --Always
        SendToConsole("dota_summoned_units_auto_attack_mode -1") --Same as hero
        SendToConsole("dota_force_right_click_attack 0")
        SendToConsole("dota_player_multipler_orders 0")
        SendToConsole("dota_hud_disable_damage_numbers 1")
        SendToConsole("dota_hud_healthbar_disable_status_display 1")
    end
end

function modifier_client_convars:IsHidden()
    return true
end

function modifier_client_convars:IsPurgable()
    return false
end