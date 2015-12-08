modifier_client_convars = class({})

function modifier_client_convars:OnCreated( params )
    if not IsServer() then
        self.original_value = Convars:GetBool("dota_player_add_summoned_to_selection")
        Convars:SetBool("dota_player_add_summoned_to_selection", false)
    end
end

function modifier_client_convars:OnDestroy( params )
    if not IsServer() then
        Convars:SetBool("dota_player_add_summoned_to_selection", self.original_value)
    end
end

function modifier_client_convars:IsHidden()
    return true
end