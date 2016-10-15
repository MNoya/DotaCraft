--[[
    Author: Noya
    Reincarnates the holder, consumes the item
]]
function Reincarnation( event )
    local caster = event.caster
    local attacker = event.attacker
    local ability = event.ability
    local casterHP = caster:GetHealth()

    if casterHP == 0 and not caster.reincarnating then
        -- Reincarnation ability takes priority
        local reincarnation_ability = caster:FindAbilityByName("tauren_chieftain_reincarnation")
        if reincarnation_ability and reincarnation_ability:IsCooldownReady() then
            return
        end

        local respawnPosition = caster:GetAbsOrigin()
        local reincarnate_time = ability:GetSpecialValueFor("reincarnate_time")

        -- Kill, counts as death for the player but doesn't count the kill for the killer unit
        caster.reincarnating = true
        caster:SetHealth(1)
        caster:Kill(nil, nil)

        -- Particle
        local particleName = "particles/items_fx/aegis_timer.vpcf"
        caster.ReincarnateParticle = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
        ParticleManager:SetParticleControl(caster.ReincarnateParticle, 0, respawnPosition)
        ParticleManager:SetParticleControl(caster.ReincarnateParticle, 1, Vector(reincarnate_time,0,0))

        -- Grave
        local model = "models/props_gameplay/tombstoneb01.vmdl"
        local grave = Entities:CreateByClassname("prop_dynamic")
        grave:SetModel(model)
        grave:SetAbsOrigin(respawnPosition)

        -- Remove item
        UTIL_Remove(ability)

        Timers:CreateTimer(reincarnate_time, function()
            ParticleManager:DestroyParticle(caster.ReincarnateParticle, true)
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
