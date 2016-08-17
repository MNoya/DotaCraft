modifier_out_of_world = class({})

if IsServer() then
    function modifier_out_of_world:CheckState() 
        local state = {
            [MODIFIER_STATE_OUT_OF_GAME] = self.serverside,
            [MODIFIER_STATE_PASSIVES_DISABLED] = true,
            [MODIFIER_STATE_PROVIDES_VISION] = false,
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
            [MODIFIER_STATE_NO_HEALTH_BAR] = true,
            [MODIFIER_STATE_UNSELECTABLE] = true,
            [MODIFIER_STATE_INVULNERABLE] = true,
            [MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
            [MODIFIER_STATE_NO_TEAM_SELECT] = true,
            [MODIFIER_STATE_STUNNED] = true,
            [MODIFIER_STATE_BLIND] = true,
            [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        }

        return state
    end

    function modifier_out_of_world:OnCreated( params )
        local unit = self:GetParent()
        self.serverside = params.clientside ~= 1
    end

    function modifier_out_of_world:IsPurgable()
        return false
    end
end