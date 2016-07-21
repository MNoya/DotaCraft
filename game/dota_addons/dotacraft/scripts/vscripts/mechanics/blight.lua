if not Blight then
    Blight = class({})
end

function Blight:Init()
    self.Grid = {} -- Blighted gridnav positions
    self.Dummies = {} -- Blight dummies, created after buildings fall
    self.Debug = false
    BuildingHelper:NewGridType("BLIGHT")
end

-- Undead Ground
function Blight:Create(unit, size)
    -- Radius is multiple of 64
    local radius = 960
    if size == "small" then
        radius = 768
    elseif size == "tiny" then
        radius = 384
    end

    -- Creating on a position
    if unit.x then
        unit = Blight:CreateDummy(unit)
    end

    local location = unit:GetAbsOrigin()
    local points = 0
    local count = 0
    BuildingHelper:SnapToGrid(radius/64, location)

    if GetMapName() == "1_dotacraft" then 
        BuildingHelper:AddGridType(radius, location, "Blight", "radius")
        return
    end

    local size = (radius - (radius%32))/32
    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)
    local halfSize = math.floor(size/2)
    local boundX1 = originX + halfSize
    local boundX2 = originX - halfSize
    local boundY1 = originY + halfSize
    local boundY2 = originY - halfSize

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)
    
    -- Mark every grid square as blighted
    for y = lowerBoundY, upperBoundY do
        for x = lowerBoundX, upperBoundX do
            if not BuildingHelper:GridHasBlight(x,y) then
                local current_pos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0)
                local distance = (current_pos - location):Length2D()
                if distance <= radius then
                    BuildingHelper.Grid[y][x] = BuildingHelper.Grid[y][x] + BuildingHelper.GridTypes["BLIGHT"]
                    
                    -- Make particle effects every particle_spread
                    if y%2==0 and x%2==0 and not Blight:GridHasParticle(x,y) then
                        local particle = ParticleManager:CreateParticle("particles/custom/undead/blight_aura.vpcf", PATTACH_CUSTOMORIGIN, nil)
                        ParticleManager:SetParticleControl(particle, 0, current_pos)
                        self.Grid[x..","..y] = particle
                        count = count+1
                    else
                        self.Grid[x..","..y] = false --This means no particle
                    end
                    points = points + 1
                end
            end
        end
    end

    BuildingHelper:AddGridType(radius, location, "Blight", "radius")
    unit:AddNewModifier(unit, nil, "modifier_grid_blight", {})
    self:print("Blighted "..points.." grid points and made "..count.." new blight particles")
end

-- Blight is dispelled once the unit that generated it has been destroyed
function Blight:Remove(unit)
    local location = unit:GetAbsOrigin()
    local radius = 768
    if unit:GetUnitName() == "undead_blight_skull" then
        radius = 384
    elseif IsCityCenter(unit) then
        radius = 960
    end

    BuildingHelper:SnapToGrid(radius/64, location)
    self:print("Removing "..radius.." blight around "..VectorString(location))

    local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, location, nil, radius+960, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

    local size = (radius - (radius%32))/32
    local originX = GridNav:WorldToGridPosX(location.x)
    local originY = GridNav:WorldToGridPosY(location.y)
    local halfSize = math.floor(size/2)
    local boundX1 = originX + halfSize
    local boundX2 = originX - halfSize
    local boundY1 = originY + halfSize
    local boundY2 = originY - halfSize

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    local count = 0
    local points = 0
    for y = lowerBoundY, upperBoundY do
        for x = lowerBoundX, upperBoundX do
            local pos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0)
            local bInRadius = (pos - location):Length2D() <= radius+64
            if bInRadius and BuildingHelper:GridHasBlight(x,y) then
                local dispelBlight = true
                -- Check that there aren't buildings inside
                for _,unit in pairs(units) do
                    if IsCustomBuilding(unit) and IsUndead(unit) then
                        local maxDistance = IsCityCenter(unit) and 960 or 768
                        if (pos - unit:GetAbsOrigin()):Length2D() <= maxDistance then
                            dispelBlight = false
                            self:DebugDrawCircle(pos,Vector(128,0,128),50,32,true,10) -- Keep blighted
                            self:DebugDrawLine(pos,unit:GetAbsOrigin(),255,255,255,true,10) -- Show the attached entity
                            self:DebugDrawCircle(unit:GetAbsOrigin(),Vector(128,0,128),1,maxDistance,true,10) -- Keep blighted
                            break
                        end
                    end
                end

                if dispelBlight then
                    BuildingHelper.Grid[y][x] = BuildingHelper.Grid[y][x] - BuildingHelper.GridTypes["BLIGHT"]
                    local particle = self:GridHasParticle(x,y)
                    if particle then
                        ParticleManager:DestroyParticle(particle, false)
                        self:DebugDrawCircle(pos,Vector(0,0,128),100,32,true,10) --particle grid point
                    else
                        self:DebugDrawCircle(pos,Vector(0,128,128),100,32,true,10) --normal grid point
                    end
                    self.Grid[x..","..y] = nil
                end
            end
        end
    end
    if unit:IsAlive() then
        self.Dummies[unit:GetEntityIndex()] = dummy
        unit:RemoveModifierByName("undead_blight_skull")
        unit:ForceKill(false)
    end
end

-- Find dummies and remove them
function Blight:Dispel(location)
    local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, location, nil, 400, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES+DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for _,v in pairs(units) do
        if v:GetUnitName() == "undead_blight_skull" then
            self:Remove(v)
        end
    end
end

function Blight:CreateDummy(position)
    local dummy = CreateUnitByName("undead_blight_skull", position, false, nil, nil, 0)
    dummy:AddNewModifier(dummy, nil, "modifier_building", {})
    dummy:AddNewModifier(dummy, nil, "modifier_out_of_world", {clientside = true})
    dummy:AddNewModifier(dummy, nil, "modifier_grid_blight", {})
    self.Dummies[dummy:GetEntityIndex()] = dummy
    self:DebugDrawCircle(position,Vector(128,0,128),100,32,true,10)
    self:DebugDrawCircle(position,Vector(128,0,128),10,384,true,10)
    return dummy
end

function Blight:GridHasParticle(x,y)
    return self.Grid[x..","..y]
end

-- Takes x,y and checks if there is marked as blight in the grid
function BuildingHelper:GridHasBlight(x,y)
    return BuildingHelper:CellHasGridType(x,y, "BLIGHT")
end

-- Takes Vector 
function BuildingHelper:PositionHasBlight(position)
    return BuildingHelper:GridHasBlight(GridNav:WorldToGridPosX(position.x),GridNav:WorldToGridPosY(position.y))
end

-- Prints grid points with blight and blight particle sources, tests dispel-ability of each blight dummy
function Blight:Debug()
    for y,v in pairs(BuildingHelper.Grid) do
        for x,_ in pairs(v) do
            if BuildingHelper:GridHasBlight(x,y) then
                DrawGridSquare(x,y,Vector(128,0,128),10)
            end
            if Blight:GridHasParticle(x,y) then
                local pos = GetGroundPosition(Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y),0),nil)
                if not BuildingHelper:GridHasBlight(x,y) then
                    DebugDrawCircle(pos,Vector(255,0,0),100,32,true,10) --Error, shouldn't happen
                else
                    DebugDrawCircle(pos,Vector(128,0,128),100,32,true,10)
                end
            end
        end
    end
    for _,dummy in pairs(self.Dummies) do
        DebugDrawCircle(dummy:GetAbsOrigin(),Vector(128,0,128),100,32,true,10)
        DebugDrawCircle(dummy:GetAbsOrigin(),Vector(128,0,128),10,384,true,10)
    end
end

function Blight:DebugDrawCircle(v,c,a,r,b,d)
    if self.Debug then
        DebugDrawCircle(GetGroundPosition(v,nil),c,a,r,b,d)
    end
end

function Blight:DebugDrawLine(v,t,r,g,b,bo,d)
    if self.Debug then
        DebugDrawLine(GetGroundPosition(v,nil),t,r,g,b,bo,d)
    end
end

function Blight:print( ... )
    if self.Debug then
        local string = ""
        local args = table.pack(...)
        for i = 1, args.n do
            string = string .. tostring(args[i]) .. " "
        end    
        print("[Blight] " .. string)
    end
end

if not Blight.Grid then Blight:Init() end

----------------------------------------------------------------

-- Datadriven modifier think interval, checks if the unit is standing on blight to apply/remove the regen
function BlightRegen(event)
    local target = event.target
    local position = target:GetAbsOrigin()
    if BuildingHelper:PositionHasBlight(position) then
        if not target:HasModifier("modifier_blight_regen") then
            event.ability:ApplyDataDrivenModifier(target, target, "modifier_blight_regen", {})
        end
    else
        if target:HasModifier("modifier_blight_regen") then
            target:RemoveModifierByName("modifier_blight_regen")
        end
    end
end