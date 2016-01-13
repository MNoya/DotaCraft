LinkLuaModifier("modifier_minimap", "mechanics/minimap", LUA_MODIFIER_MOTION_NONE)
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
            [MODIFIER_STATE_NOT_ON_MINIMAP] = self.hidden,
        }

        return state
    end

    function modifier_minimap:OnCreated( params )    
        local minimap_entity = self:GetParent()
        local teamNumber = minimap_entity:GetTeamNumber()
        local origin = minimap_entity:GetAbsOrigin()
        self.neutrals = FindUnitsInRadius(teamNumber, origin, nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
        self.hidden = true
        
        Timers:CreateTimer(0.5, function()
            self.hidden = false
            self.allDead = true
            

            -- Does the team have vision of any neutral on the camp?
            for _,creep in pairs(self.neutrals) do                
                if IsValidAlive(creep) and minimap_entity:CanEntityBeSeenByMyTeam(creep) then
                    self.hidden = true
                    break
                end
            end

            -- Also check for allied proximity, in case all creeps died and the visibility check is impossible
            if not self.hidden then
                local allies = FindAlliesInRadius(minimap_entity, 900)
                if #allies > 0 then
                    self.hidden = true
                end
            end

            -- If its hidden, allow the entity to be removed
            if self.hidden then
                local allDead = true
                for _,creep in pairs(self.neutrals) do
                    if IsValidAlive(creep) then
                        allDead = false
                        break
                    end
                end

                if allDead then
                    print(minimap_entity:GetUnitName().." killed for team "..minimap_entity:GetTeamNumber())
                    minimap_entity:RemoveSelf()
                    return
                end
            end

            self:CheckState()
            return 0.5
        end)
    end
end

-- Drop out of self-include
if not Entities or not Entities.CreateByClassname then return end

-----------------------------------------------------------------

if not Minimap then
    Minimap = class({})
end

-- Called when game starts
function Minimap:InitializeCampIcons()

    -- Build a list of teams with players on them
    local validTeams = {}
    for teamID=DOTA_TEAM_FIRST,DOTA_TEAM_CUSTOM_MAX do
        local playerCount = PlayerResource:GetPlayerCountForTeam(teamID)
        if playerCount > 0 then
            table.insert(validTeams, teamID)
        end
    end

    -- For each minimap_ entity, replicate one for each team
    local entities = Entities:FindAllByClassname("npc_dota_building")
    for _,ent in pairs(entities) do
        if string.match(ent:GetUnitName(), "minimap_") then
            local unitName = ent:GetUnitName()
            for _,teamID in pairs(validTeams) do
                -- Create a minimap camp entity for this team
                local dummy = CreateUnitByName(unitName, ent:GetAbsOrigin(), false, nil, nil, teamID)
                dummy:AddNewModifier(dummy, nil, "modifier_minimap", {})
            end
            -- Finally, remove the initial entity
            ent:RemoveSelf()
        end
    end
end