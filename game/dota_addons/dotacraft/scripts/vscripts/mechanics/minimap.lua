if not Minimap then
    Minimap = class({})
end

-- Entry point after the creation of dummy_minimap
function OnCampCreated(event)
    local entity = event.caster
    if entity:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
        Minimap:SetupNeutralCamp(entity)
    end
end

function Minimap:SetupNeutralCamp(entity)
    local typeName = entity:GetUnitName()

    for teamID=DOTA_TEAM_FIRST,DOTA_TEAM_CUSTOM_MAX do
        local playerCount = PlayerResource:GetPlayerCountForTeam(teamID)
        if playerCount > 0 then
            -- Create a minimap camp entity for this team

        end
    end

    -- Finally, remove it
end

function Minimap:HideIcon(entity, teamID)

end

function Minimap:ShowIcon(entity, teamID)

end

function Minimap:CampKilled(entity, teamID)

end