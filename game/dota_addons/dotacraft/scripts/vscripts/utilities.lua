function tableContains(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return true
        end
    end
    return false
end

function getIndex(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return i
        end
    end
    return -1
end

function getUnitIndex(list, unitName)
    -- print("Given Table")
    --DeepPrintTable(list)
    if list == nil then return false end
    for k,v in pairs(list) do
        for key,value in pairs(list[k]) do
            -- print(key,value)
            if value == unitName then 
                return key
            end
        end        
    end
    return -1
end

function getIndexTable(list, element)
    if list == nil then return false end
    for k,v in pairs(list) do
        if v == element then
            return k
        end
    end
    return nil
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function ShuffledList( orig_list )
    local list = shallowcopy( orig_list )
    local result = {}
    local count = #list
    for i = 1, count do
        local pick = RandomInt( 1, #list )
        result[ #result + 1 ] = list[ pick ]
        table.remove( list, pick )
    end
    return result
end


function TableCount( t )
    local n = 0
    for _ in pairs( t ) do
        n = n + 1
    end
    return n
end

function TableFindKey( table, val )
    if table == nil then
        print( "nil" )
        return nil
    end

    for k, v in pairs( table ) do
        if v == val then
            return k
        end
    end
    return nil
end

function MergeTables( t1, t2 )
    for name,info in pairs(t2) do
        t1[name] = info
    end
end

function split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end

function StringStartsWith( fullstring, substring )
    local strlen = string.len(substring)
    local first_characters = string.sub(fullstring, 1 , strlen)
    return (first_characters == substring)
end

function DebugPrint(...)
    local spew = 1--Convars:GetInt('debug_spew') or -1
    if spew == -1 and DEBUG_SPEW then
        spew = 1
    end

    if spew == 1 then
        print(...)
    end
end

function VectorString(v)
    return '[' .. math.floor(v.x) .. ', ' .. math.floor(v.y) .. ', ' .. math.floor(v.z) .. ']'
end

function tobool(s)
    if s=="true" or s=="1" or s==1 then
        return true
    else --nil "false" "0"
        return false
    end
end

-- v should be a Normalized vector. theta is in radians.
function RotateVector2D(v, theta)
    local xPrime = v.x*math.cos(theta)-v.y*math.sin(theta)
    local yPrime = v.x*math.sin(theta)+v.y*math.cos(theta)
    return Vector(xPrime, yPrime, v.z)
end

function GenerateNumPointsAround(num, center, distance)
    local points = {}
    local angle = 360/num
    for i=0,num-1 do
        local rotate_pos = center + Vector(1,0,0) * distance
        table.insert(points, RotatePosition(center, QAngle(0, angle*i, 0), rotate_pos) )
    end
    return points
end

function GetGridAroundPoint( numUnits, point, forward )
    local navPoints = {}
    if numUnits == 1 then return {point} end
    local unitsPerRow = math.floor(math.sqrt(numUnits/SQUARE_FACTOR))
    local unitsPerColumn = math.floor((numUnits / unitsPerRow))
    local remainder = numUnits - (unitsPerRow*unitsPerColumn) 

    local forward = forward or point:Normalized()
    local right = RotatePosition(Vector(0,0,0), QAngle(0,90,0), forward)

    local start = (unitsPerColumn-1)* -.5

    local curX = start
    local curY = 0

    local offsetX = UNIT_FORMATION_DISTANCE
    local offsetY = UNIT_FORMATION_DISTANCE

    for i=1,unitsPerRow do
      for j=1,unitsPerColumn do
        local newPoint = point + (curX * offsetX * right) + (curY * offsetY * forward)
        navPoints[#navPoints+1] = newPoint
        curX = curX + 1
      end
      curX = start
      curY = curY - 1
    end

    local curX = ((remainder-1) * -.5)

    for i=1,remainder do 
        local newPoint = point + (curX * offsetX * right) + (curY * offsetY * forward)
        navPoints[#navPoints+1] = newPoint
        curX = curX + 1
    end

    return navPoints
end