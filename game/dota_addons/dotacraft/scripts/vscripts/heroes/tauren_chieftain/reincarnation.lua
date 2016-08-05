--[[
    Author: Noya
    Reincarnates the target if the ability is not on cooldown
]]
function Reincarnation( event )
    local caster = event.caster
    local attacker = event.attacker
    local ability = event.ability
    local cooldown = ability:GetCooldown(ability:GetLevel() - 1)
    local casterHP = caster:GetHealth()
    
    if casterHP == 0 and ability:IsCooldownReady() then
        local respawnPosition = caster:GetAbsOrigin()
        local reincarnate_time = ability:GetLevelSpecialValueFor("reincarnate_time", ability:GetLevel() - 1)
        
        -- Start cooldown on the passive
        ability:StartCooldown(cooldown)

        -- Kill, counts as death for the player but doesn't count the kill for the killer unit
        caster.reincarnating = true -- Filter OnEntityKilled
        caster:SetHealth(1)
        caster:Kill(nil, nil)

        -- Particle
        local particleName = "particles/units/heroes/hero_skeletonking/wraith_king_reincarnate.vpcf"
        caster.ReincarnateParticle = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
        ParticleManager:SetParticleControl(caster.ReincarnateParticle, 0, respawnPosition)
        ParticleManager:SetParticleControl(caster.ReincarnateParticle, 1, Vector(500,0,0))
        ParticleManager:SetParticleControl(caster.ReincarnateParticle, 1, Vector(500,500,0))

        -- Grave and rock particles
        -- The parent "particles/units/heroes/hero_skeletonking/skeleton_king_death.vpcf" misses the grave model
        local model = "models/props_gameplay/tombstoneb01.vmdl"
        local grave = Entities:CreateByClassname("prop_dynamic")
        grave:SetModel(model)
        grave:SetAbsOrigin(respawnPosition)

        local particleName = "particles/units/heroes/hero_skeletonking/skeleton_king_death_bits.vpcf"
        local particle1 = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, caster )
        ParticleManager:SetParticleControl(particle1, 0, respawnPosition)

        local particleName = "particles/units/heroes/hero_skeletonking/skeleton_king_death_dust.vpcf"
        local particle2 = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
        ParticleManager:SetParticleControl(particle2, 0, respawnPosition)

        local particleName = "particles/units/heroes/hero_skeletonking/skeleton_king_death_dust_reincarnate.vpcf"
        local particle3 = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
        ParticleManager:SetParticleControl(particle3 , 0, respawnPosition)

        -- Respawn
        Timers:CreateTimer(reincarnate_time, function()
            ParticleManager:DestroyParticle(caster.ReincarnateParticle, false)
            caster.reincarnating =  nil
            grave:RemoveSelf()
            caster:RespawnUnit()
            caster:AddNewModifier(caster,ability,"modifier_phased",{duration=0.03})
            Timers:CreateTimer(0.03, function()
                caster:FindClearSpace(respawnPosition)
            end)
            caster:EmitSound("Hero_SkeletonKing.Reincarnate.Stinger")
        end)     

        -- Sounds
        caster:EmitSound("Hero_SkeletonKing.Reincarnate")
        caster:EmitSound("Hero_SkeletonKing.Death")
    end
end

    