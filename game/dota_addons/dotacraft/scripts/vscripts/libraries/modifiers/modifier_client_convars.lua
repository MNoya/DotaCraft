modifier_client_convars = class({})

function modifier_client_convars:OnCreated( params )
    if not IsServer() then
        self.original_autoattack_value = Convars:GetBool("dota_player_units_auto_attack")
        self.original_addsummon_value = Convars:GetBool("dota_player_add_summoned_to_selection")
        self.original_autospell_value = Convars:GetBool("dota_player_units_auto_attack_after_spell")
        Convars:SetBool("dota_player_add_summoned_to_selection", false)
        Convars:SetBool("dota_player_units_auto_attack", true)
        Convars:SetBool("dota_player_units_auto_attack_after_spell", true)
    end
end

function modifier_client_convars:OnDestroy( params )
    if not IsServer() then
        Convars:SetBool("dota_player_add_summoned_to_selection", self.original_addsummon_value)
        Convars:SetBool("dota_player_units_auto_attack", self.original_autoattack_value)
        Convars:SetBool("dota_player_units_auto_attack_after_spell", self.original_autospell_value)
    end
end

function modifier_client_convars:IsHidden()
    return true
end