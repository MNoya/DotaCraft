function AttachOrbs( event )
	local hero = event.caster
	local origin = hero:GetAbsOrigin()
	local particleName = "particles/custom/human/blood_mage/exort_orb.vpcf"

    hero.orbs = {}
    for i=1,3 do
        hero.orbs[i] = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, hero)
        ParticleManager:SetParticleControlEnt(hero.orbs[i], 1, hero, PATTACH_POINT_FOLLOW, "attach_orb"..i, origin, false)
    end
end

function RemoveOrbs(event)
    local hero = event.caster
    local origin = hero:GetAbsOrigin()
    
    for i=1,3 do
        ParticleManager:DestroyParticle(hero.orbs[i],false)
    end
    hero.orbs = {}
end