-- Gives vision over an area and shows dust particle to the team
function Flare(event)
    local caster = event.caster
    local ability = event.ability
    local level = ability:GetLevel()
    local reveal_radius = ability:GetLevelSpecialValueFor( "radius", level - 1 )
    local duration = ability:GetLevelSpecialValueFor( "duration", level - 1 )
    local target = event.target_points[1]

    local fxIndex = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_rattletrap/rattletrap_rocket_flare_illumination.vpcf",PATTACH_WORLDORIGIN,nil,caster:GetTeamNumber())
    ParticleManager:SetParticleControl(fxIndex, 0, target)
    ParticleManager:SetParticleControl(fxIndex, 1, Vector(5,0,0))

    AddFOWViewer(caster:GetTeamNumber(), target, reveal_radius, duration, false)

    local visiondummy = CreateUnitByName("dummy_unit", target, false, caster, caster, caster:GetTeamNumber())
    visiondummy:AddNewModifier(caster, ability, "modifier_true_sight_aura", {}) 
    Timers:CreateTimer(duration, function() UTIL_Remove(visiondummy) return end)
end

function UnlockFragmentationShards(event)
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetSpecialValueFor("radius")
    SetRangedProjectileName(caster, "particles/econ/items/techies/techies_arcana/techies_base_attack_arcana.vpcf")
    
    function caster:FragmentationShard(target, position)
        local particle = ParticleManager:CreateParticle("particles/custom/human/mortar_team_fragmentation_shard.vpcf", PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(particle, 0, position)
        ParticleManager:SetParticleControl(particle, 1, target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc")))
    end
end