-- Undead Ground
function CreateBlight(location, size)

    -- Radius should be an odd number for precision
    local radius = 960
    if size == "small" then
        radius = 704
    elseif size == "item" then
        radius = 384
    end
    local particle_spread = 256
    local count = 0
    
    -- Mark every grid square as blighted
    for x = location.x - radius, location.x + radius, 64 do
        for y = location.y - radius, location.y + radius, 64 do
            local position = Vector(x, y, location.z)
            if not HasBlight(position) then

                -- Make particle effects every particle_spread
                if (x-location.x) % particle_spread == 0 and (y-location.y) % particle_spread == 0 then
                    local particle = ParticleManager:CreateParticle("particles/custom/undead/blight_aura.vpcf", PATTACH_CUSTOMORIGIN, nil)
                    ParticleManager:SetParticleControl(particle, 0, position)
                    GameRules.Blight[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosY(position.y)] = particle
                    count = count+1
                else
                    GameRules.Blight[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosY(position.y)] = false
                end
            end
        end
    end

    BuildingHelper:AddGridType(radius/32, location, "Blight")

    print("Made "..count.." new blight particles")
   
end

-- Blight can be dispelled once the building that generated it has been destroyed or unsummoned.
function RemoveBlight( location, radius )
    location.x = BuildingHelper:SnapToGrid64(location.x)
    location.y = BuildingHelper:SnapToGrid64(location.y)
    radius = radius - (radius%64) + 256

    local count = 0
    for x = location.x - radius, location.x + radius, 64 do
        for y = location.y - radius, location.y + radius, 64 do
            local dispelBlight = true
            local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, location, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
            for _,unit in pairs(units) do
                if IsCustomBuilding(unit) and IsUndead(unit) then
                    dispelBlight = false
                    break
                end
            end

            -- No undead building was found nearby this gridnav position, remove blight around the position
            local position = Vector(x, y, location.z)

            if dispelBlight and HasBlightParticle( position ) then
                -- Clear this blight zone
                local blight_index = GameRules.Blight[GridNav:WorldToGridPosX(position.x)..","..GridNav:WorldToGridPosY(position.y)]
                ParticleManager:DestroyParticle(blight_index, false)
                ParticleManager:ReleaseParticleIndex(blight_index)
                count = count+1

                for blight_x = x - 128, x + 128, 64 do
                    for blight_y = y - 128, y + 128, 64 do
                        GameRules.Blight[GridNav:WorldToGridPosX(blight_x)..","..GridNav:WorldToGridPosY(blight_y)] = nil
                    end
                end
            end
        end
    end
    BuildingHelper:RemoveGridType(radius/32, location, "Blight")

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