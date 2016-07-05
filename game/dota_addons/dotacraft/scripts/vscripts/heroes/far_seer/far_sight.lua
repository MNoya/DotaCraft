-- Gives vision over an area and shows dust particle to the team
function FarSight( event )
	local caster = event.caster
	local ability = event.ability
	local level = ability:GetLevel()
	local reveal_radius = ability:GetLevelSpecialValueFor( "radius", level - 1 )
	local duration = ability:GetLevelSpecialValueFor( "duration", level - 1 )
	local target = event.target_points[1]

    local fxIndex = ParticleManager:CreateParticleForTeam("particles/items_fx/dust_of_appearance.vpcf",PATTACH_WORLDORIGIN,nil,caster:GetTeamNumber())
    ParticleManager:SetParticleControl(fxIndex, 0, target)
    ParticleManager:SetParticleControl(fxIndex, 1, Vector(reveal_radius,0,reveal_radius))

    AddFOWViewer(caster:GetTeamNumber(), target, reveal_radius, duration, false)

    local visiondummy = CreateUnitByName("dummy_unit", target, false, caster, caster, caster:GetTeamNumber())
    visiondummy:AddNewModifier(caster, ability, "modifier_true_sight_aura", {}) 
    Timers:CreateTimer(duration, function() UTIL_Remove(visiondummy) return end)
end