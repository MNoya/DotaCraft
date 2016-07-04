function BladestormDamage(event)
    local caster = event.caster
    local ability = event.ability
    local damage = ability:GetAbilityDamage() * ability:GetSpecialValueFor("bladestorm_damage_tick")
    local radius = ability:GetSpecialValueFor("bladestorm_radius")
    local targets = FindEnemiesInRadius( caster, radius, caster:GetAbsOrigin() )
        
    for _,target in pairs(targets) do
        target:EmitSound("Hero_Juggernaut.BladeFury.Impact")
        if IsCustomBuilding(target) then
            DamageBuilding(target, damage, ability, caster)
        else
            ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
        end
    end
end

--Stops the looping sound event
function BladeFuryStop( event )
	local caster = event.caster	
	caster:StopSound("Hero_Juggernaut.BladeFuryStart")
end