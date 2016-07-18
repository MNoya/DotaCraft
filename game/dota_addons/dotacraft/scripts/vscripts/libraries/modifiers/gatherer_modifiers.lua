modifier_carrying_lumber = class({})

function modifier_carrying_lumber:GetTexture()
    return "furion_sprout"
end

function modifier_carrying_lumber:IsPurgable()
    return false
end

----------------------------------------------

modifier_carrying_gold = class({})

function modifier_carrying_gold:GetTexture()
    return "alchemist_goblins_greed"
end

function modifier_carrying_gold:IsPurgable()
    return false
end

----------------------------------------------

modifier_gatherer_hidden = class({})

function modifier_gatherer_hidden:CheckState()
    return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = self.restricted,
        [MODIFIER_STATE_UNSELECTABLE] = self.restricted,
    }
end

function modifier_gatherer_hidden:OnCreated(kv)
    self.restricted = kv.restricted == 1
end

function modifier_gatherer_hidden:IsHidden()
    return true
end

function modifier_gatherer_hidden:IsPurgable()
    return false
end

----------------------------------------------