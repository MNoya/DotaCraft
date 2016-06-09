--[[
    Author: Noya
    Can only be cast on living allied units (Heal) or enemy Undead units (Damage)
    Disallows self targeting and casting on allied units with full health
]]
paladin_holy_light = class({})

function paladin_holy_light:OnSpellStart( event )
    local ability = self
    local caster = ability:GetCaster()
    local target = ability:GetCursorTarget()

    local damage = ability:GetLevelSpecialValueFor( "target_damage" , ability:GetLevel() - 1  )
    local heal = ability:GetLevelSpecialValueFor( "heal_amount" , ability:GetLevel() - 1 )

    -- Play the ability sound
    target:EmitSound("Hero_Omniknight.Purification")

    -- If the target and caster are on a different team, do Damage. Heal otherwise
    if target:GetTeamNumber() ~= caster:GetTeamNumber() then
        ApplyDamage({ victim = target, attacker = caster, damage = damage, ability = ability, damage_type = DAMAGE_TYPE_MAGICAL })
    else
        local healDone = math.min(heal,target:GetHealthDeficit())
        if healDone > 0 then
            PopupHealing(target, healDone)
            target:Heal( heal, caster)
        end
    end

    -- Particle 
    local particle = ParticleManager:CreateParticle("particles/custom/human/paladin/holy_light.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(200,0,0))
end

--------------------------------------------------------------------------------
 
function paladin_holy_light:CastFilterResultTarget( target )
    local ability = self
    local caster = ability:GetCaster()

    -- Check Undead for allies or Living for enemies
    local casterTeam = caster:GetTeamNumber()
    local targetTeam = target:GetTeamNumber()
    local allied = casterTeam == targetTeam
    local bUndead = string.match(target:GetUnitName(),"undead")

    -- Check self-target
    if caster == target then 
        return UF_FAIL_CUSTOM
    end

    -- Check full health ally
    if allied and target:GetHealthPercent() == 100 then
        return UF_FAIL_CUSTOM
    end

    -- Prevent healing undead allies or damaging non undead enemies
    if (allied and bUndead) or (not allied and not bUndead) then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end
  
function paladin_holy_light:GetCustomCastErrorTarget( target )
    local ability = self
    local caster = self:GetCaster()

    local casterTeam = caster:GetTeamNumber()
    local targetTeam = target:GetTeamNumber()
    local allied = casterTeam == targetTeam
    local bUndead = string.match(target:GetUnitName(),"undead")

    if caster == target then
        return "#error_cant_target_self"
    end

    if allied and target:GetHealthPercent() == 100 then
        return "#error_full_health"
    end

    if (allied and bUndead) or (not allied and not bUndead) then
        return "#error_cant_target_undead_allies"
    end
 
    return ""
end