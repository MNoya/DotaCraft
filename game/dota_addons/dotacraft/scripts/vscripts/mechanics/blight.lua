-- Undead Ground
function CreateBlight(unit, size)
    local location = unit:GetAbsOrigin()

    -- Radius should be an odd number for precision
    local radius = 960
    if size == "small" then
        radius = 768
    elseif size == "item" then
        radius = 384
    end
    BuildingHelper:SnapToGrid(radius, location)
    local particle_spread = 128
    local count = 0

    if GetMapName() == "1_dotacraft" then 
        BuildingHelper:AddGridType(radius, location, "Blight", "radius")
        return
    end
    
    -- Mark every grid square as blighted
    for x = location.x - radius, location.x + radius - particle_spread, 64 do
        for y = location.y - radius, location.y + radius - particle_spread, 64 do
            local position = Vector(x, y, location.z)

            if (Vector(x,y,0) - location):Length2D() < radius and not HasBlight(position) then
                -- Make particle effects every particle_spread
                if (x-location.x) % particle_spread == 0 and (y-location.y) % particle_spread == 0 then
                    local particle = ParticleManager:CreateParticle("particles/custom/undead/blight_aura.vpcf", PATTACH_CUSTOMORIGIN, nil)
                    ParticleManager:SetParticleControl(particle, 0, position)
                    GameRules.Blight[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosY(position.y)] = particle or true
                    count = count+1
                else
                    GameRules.Blight[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosY(position.y)] = false
                end
            end
        end
    end

    BuildingHelper:AddGridType(radius, location, "Blight", "radius")
    unit:AddNewModifier(unit, nil, "modifier_grid_blight", {})

    print("Made "..count.." new blight particles")
end

-- Blight can be dispelled once the building that generated it has been destroyed or unsummoned.
function RemoveBlight( location, radius )
    BuildingHelper:SnapToGrid(radius, location)
    radius = radius - (radius%64) + 256

    -- For each point, check all buildings distance to it, if they are further than their grid radius, the blight point can be dispelled
    local count = 0
    for x = location.x - radius, location.x + radius, 64 do
        for y = location.y - radius, location.y + radius, 64 do
            local dispelBlight = true
            local dummies = {}
            local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(x,y,0), nil, 900, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES+DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
            for _,unit in pairs(units) do
                local bDummy = unit:GetUnitName() == "undead_blight_skull"
                if bDummy then 
                    dummies[unit:GetEntityIndex()] = unit
                end
                if IsCustomBuilding(unit) and IsUndead(unit) and not bDummy then
                    dispelBlight = false
                    break
                end
            end

            -- No undead building was found nearby this gridnav position, remove blight around the position
            local position = Vector(x, y, location.z)

            if dispelBlight then
                if HasBlightParticle( position ) then
                    -- Clear this blight zone
                    for blight_x = x - 128, x + 128, 64 do
                        for blight_y = y - 128, y + 128, 64 do
                            local blight_index = GameRules.Blight[GridNav:WorldToGridPosX(blight_x)..","..GridNav:WorldToGridPosY(blight_y)]
                            if blight_index then
                                ParticleManager:DestroyParticle(blight_index, false)
                                ParticleManager:ReleaseParticleIndex(blight_index)
                                GameRules.Blight[GridNav:WorldToGridPosX(blight_x)..","..GridNav:WorldToGridPosY(blight_y)] = nil
                                count = count+1
                            end
                        end
                    end
                end

                for _,v in pairs(dummies) do
                    UTIL_Remove(v)
                end
            end
        end
    end
    BuildingHelper:RemoveGridType(radius, location, "Blight", "radius")

    print("Removed "..count.." blight particles")
end

-- Takes a Vector and checks if there is marked as blight in the grid
function HasBlight( position )
    local x = GridNav:WorldToGridPosX(position.x)
    local y = GridNav:WorldToGridPosY(position.y)
    return BuildingHelper:CellHasGridType(x,y, "BLIGHT")
end

-- Not every gridnav square needs a blight particle
function HasBlightParticle( position )
    return GameRules.Blight[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosY(position.y)]
end