--[[
	Author: Noya
	Date: 16.01.2015.
	Shows tornado particles on a target and destroys later
]]
function TornadoParticle(event)
	local target = event.target
	target.tornado = ParticleManager:CreateParticle("particles/neutral_fx/tornado_ambient.vpcf", PATTACH_WORLDORIGIN, event.caster)
	ParticleManager:SetParticleControl(target.tornado, 0, Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z - 50 ))
end

function EndTornadoParticle(event)
	local target = event.target
	ParticleManager:DestroyParticle(target.tornado,false)
end

-- Finds and kills the tornado
function TornadoEnd( event )
	local tornado = Entities:FindByModel(nil, "models/heroes/attachto_ghost/attachto_ghost.vmdl")
	tornado:RemoveSelf()
end

--[[
	Author: Noya
	Date: 16.01.2015.
	Rotates by an angle degree
]]
function Spin(keys)
    local target = keys.target
    local total_degrees = keys.Angle
    target:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,total_degrees,0), target:GetForwardVector()))
end