--[[
    Author: Noya
    Adds the targets hit by the projectile up to max_units
    Fires lightning particle, sound and damage at all of them
]]
function ForkedLightning( event )
    local hero = event.caster
    local target = event.target
    local ability = event.ability
    local max_units = event.ability:GetLevelSpecialValueFor("max_units", (ability:GetLevel() - 1))
    
    -- add the target if we haven't hit the max unit count yet
    if ability.forked_units_hit < max_units and not ability.targets[target:GetEntityIndex()] and not IsCustomBuilding(target) and not target:IsMechanical() and not target:IsWard()  then
        ability.targets[target:GetEntityIndex()] = target

        -- add 1 to the units hit
        ability.forked_units_hit = ability.forked_units_hit + 1
    end
end

function ForkedLightningStart(event)
    local hero = event.caster
    local target = event.target
    local ability = event.ability
    
    ability.targets = {}
    ability.targets[target:GetEntityIndex()] = target
    ability.forked_units_hit = 1

    local origin = hero:GetAttachmentOrigin(hero:ScriptLookupAttachment("attach_attack2"))
    Timers:CreateTimer(0.2, function()
        for _,target in pairs(ability.targets) do
            local lightningBolt = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_WORLDORIGIN, hero)
            ParticleManager:SetParticleControl(lightningBolt,0,origin)   
            ParticleManager:SetParticleControl(lightningBolt,1,target:GetAttachmentOrigin(target:ScriptLookupAttachment("attach_hitloc")))
            
            ApplyDamage({ victim = target, attacker = hero, damage = ability:GetAbilityDamage(), ability = ability, damage_type = ability:GetAbilityDamageType() })
            EmitSoundOn("Hero_Zuus.ArcLightning.Target", target)
        end
    end)
end