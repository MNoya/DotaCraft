--[[
    Author: Noya
    Date: 16.01.2015.
    Fires lightning particle sound and damage at the target unit, if the spell hasn't hit its max_units limit.
]]
function ForkedLightning( event )
    local hero = event.caster
    local target = event.target
    local ability = event.ability
    local max_units = event.ability:GetLevelSpecialValueFor("max_units", (ability:GetLevel() - 1))
    
    if hero.forked_units_hit == nil then
        hero.forked_units_hit = 0
    end

    -- hit the target if we haven't hit the max unit count yet
    if hero.forked_units_hit < max_units and not IsCustomBuilding(target) and not target:IsMechanical() then
        local lightningBolt = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_WORLDORIGIN, hero)
        ParticleManager:SetParticleControl(lightningBolt,0,Vector(hero:GetAbsOrigin().x,hero:GetAbsOrigin().y,hero:GetAbsOrigin().z + hero:GetBoundingMaxs().z ))   
        ParticleManager:SetParticleControl(lightningBolt,1,Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z + target:GetBoundingMaxs().z ))
        
        ApplyDamage({ victim = target, attacker = hero, damage = ability:GetAbilityDamage(), ability = ability, damage_type = ability:GetAbilityDamageType() })
        EmitSoundOn("Hero_Zuus.ArcLightning.Target", target)

        -- add 1 to the units hit
        hero.forked_units_hit = hero.forked_units_hit + 1
    else
        -- Wait for the spell to end
        Timers:CreateTimer(0.5, function()
            hero.forked_units_hit = nil
        end)
    end

end