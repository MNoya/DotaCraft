--[[
	Author: Noya
	Date: 18.01.2015.
	Gets the summoning location for the new unit
]]
function SummonLocation( event )
    local caster = event.caster
    local fv = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
    
    -- Gets the vector facing 200 units away from the caster origin
	local front_position = origin + fv * 200

    local result = { }
    table.insert(result, front_position)

    return result
end

--[[Author: Amused/D3luxe
	Used by: Noya
	Date: 18.12.2014.
	Blinks the target to the target point, if the point is beyond max blink range then blink the maximum range]]
function Blink(keys)
	--PrintTable(keys)
	local point = keys.target_points[1]
	local caster = keys.caster
	local casterPos = caster:GetAbsOrigin()
	local difference = point - casterPos
	local ability = keys.ability
	local range = ability:GetLevelSpecialValueFor("blink_range", (ability:GetLevel() - 1))

	if difference:Length2D() > range then
		point = casterPos + (point - casterPos):Normalized() * range
	end

	FindClearSpaceForUnit(caster, point, false)	
end