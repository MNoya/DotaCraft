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

        Timers:CreateTimer(0.1, function()
            self.hidden = false

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

    function modifier_minimap:IsPurgable()
        return false
    end
end

-- Drop out of self-include
if not Entities or not Entities.CreateByClassname then return end

-----------------------------------------------------------------

if not Minimap then
    Minimap = class({})
end

function Minimap:PrepareCamps()
    self.Camps = Entities:FindAllByClassname("npc_dota_creature")
    for _,ent in pairs(self.Camps) do
        if ent:GetUnitName():match("minimap_") then
            ent:AddAbility("dummy_passive"):SetLevel(1)
        end
    end
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
    for _,ent in pairs(self.Camps) do
        if IsValidEntity(ent) and ent:GetUnitName():match("minimap_") then
            local unitName = ent:GetUnitName()
            for _,teamID in pairs(validTeams) do
                -- Create a minimap camp entity for this team if there is no unit from that team nearby
                local origin = ent:GetAbsOrigin()
                local units = FindUnitsInRadius(teamID, origin, nil, 1000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
                if #units == 0 then
                    local dummy = CreateUnitByName(unitName, origin, false, nil, nil, teamID)
                    dummy:AddNewModifier(dummy, nil, "modifier_minimap", {})
                end
            end
            -- Finally, remove the initial entity
            ent:RemoveSelf()
        end
    end
end