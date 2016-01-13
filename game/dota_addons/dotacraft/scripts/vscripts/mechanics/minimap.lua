LinkLuaModifier("modifier_minimap", "libraries/modifiers/modifier_minimap", LUA_MODIFIER_MOTION_NONE)
modifier_minimap = class({})

if IsServer() then
    function modifier_minimap:CheckState()
        local state = {
            [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
            [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
            [MODIFIER_STATE_INVULNERABLE] = true,
            [MODIFIER_STATE_UNSELECTABLE] = true,
            [MODIFIER_STATE_NO_HEALTH_BAR] = true,
            [MODIFIER_STATE_OUT_OF_GAME] = true,
            [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
            [MODIFIER_STATE_NOT_ON_MINIMAP] = modifier_minimap.hidden,
        }

        return state
    end

    function modifier_minimap:OnCreated( params )    
        modifier_minimap.hidden = true
    end

    function modifier_minimap:OnDestroy( params )

    end
end

-- Drop out of self-include
if not Entities or not Entities.CreateByClassname then return end

if not Minimap then
    Minimap = class({})
end

-- Called when game starts
function Minimap:InitializeCampIcons()
    local entities = Entities:FindAllByClassname("npc_dota_building")

    for _,ent in pairs(entities) do
        if string.match(ent:GetUnitName(), "minimap_") then
            Minimap:SetupNeutralCamp(ent)
        end
    end
end

function Minimap:SetupNeutralCamp(entity)
    local unitName = entity:GetUnitName()

    for teamID=DOTA_TEAM_FIRST,DOTA_TEAM_CUSTOM_MAX do
        local playerCount = PlayerResource:GetPlayerCountForTeam(teamID)
        if playerCount > 0 then
            -- Create a minimap camp entity for this team
            local dummy = CreateUnitByName(unitName, entity:GetAbsOrigin(), false, nil, nil, teamID)
            dummy:AddNewModifier(dummy, nil, "modifier_minimap", {})
        end
    end

    -- Finally, remove the initial entity
    entity:RemoveSelf()
end

function Minimap:HideIcon(entity, teamID)

end

function Minimap:ShowIcon(entity, teamID)

end

function Minimap:CampKilled(entity, teamID)

end