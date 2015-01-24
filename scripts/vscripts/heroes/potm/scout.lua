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

-- Set the units looking at the same point of the caster
function SetUnitsMoveForward( event )
	local caster = event.caster
	local target = event.target
    local fv = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
	
	target:SetForwardVector(fv)

end