-- Mana drain, damage and effects, ignoring magic immunity
function ManaBreak( keys )
    local target = keys.target
    local caster = keys.caster
    local ability = keys.ability
    local manaBurn = ability:GetLevelSpecialValueFor("mana_per_hit", (ability:GetLevel() - 1))
    local manaDamage = ability:GetLevelSpecialValueFor("damage_per_burn", (ability:GetLevel() - 1))

    if target:IsMagicImmune() or target:IsMechanical() then return end

    local damage = math.min(target:GetMana(), manaDamage)
    target:ReduceMana(damage)
    ApplyDamage({attacker = caster, victim = target, damage_type = ability:GetAbilityDamageType(), ability = ability, damage = damage})

    target:EmitSound("Hero_Antimage.ManaBreak")
    ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
end

----------------------------------------------------------

function SpellSteal_AutoCast(event)
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetCastRange()
    local flags = DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
    ability:ToggleAutoCast()

    Timers:CreateTimer(0.5, function()
        if not IsValidEntity(caster) or not caster:IsAlive() then return end
        if not ability:GetAutoCastState() then return 0.5 end

        -- Find enemies to remove buffs or allies to remove debuffs
        local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, FIND_ANY_ORDER, false)  
        for _,target in pairs(units) do
            local bRemovePositiveBuffs = target:GetTeamNumber() ~= caster:GetTeamNumber()
            if target:HasPurgableModifiers(bRemovePositiveBuffs) then
                caster:CastAbilityOnTarget(target,ability,caster:GetPlayerOwnerID())
                return ability:GetCooldown(1)
            end
        end
        return 0.5
    end)
end

-- Transfer buff/debuffs to ally/enemy
function SpellSteal(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local radius = ability:GetCastRange()
    local bRemovePositiveBuffs = target:GetTeamNumber() ~= caster:GetTeamNumber()
    local modifier = target:HasPurgableModifiers(bRemovePositiveBuffs)

    if not modifier then
        SendErrorMessage(caster:GetPlayerOwnerID(), "#error_no_stealable_buffs")
        ability:RefundManaCost()
        ability:EndCooldown()
        return
    end

    local modifierName = modifier:GetName()
    local team_type = bRemovePositiveBuffs and DOTA_UNIT_TARGET_TEAM_FRIENDLY or DOTA_UNIT_TARGET_TEAM_ENEMY

    -- Find units and apply
    local units
    if bRemovePositiveBuffs then
        units = FindAlliesInRadius(caster, radius)
    else
        units = FindEnemiesInRadius(caster, radius)
    end
    local newTarget
    for _,unit in pairs(units) do
        if not unit:HasModifier(modifierName) then
            newTarget = unit
            break
        end
    end
    -- If everyone has the modifier, pick one at random
    if not newTarget then
        newTarget = units[RandomInt(1,#units)]
    end

    modifier:Transfer(newTarget, caster)
    caster:EmitSound("Hero_Rubick.SpellSteal.Target")
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_rubick/rubick_spell_steal_haze.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, newTarget:GetAbsOrigin())
end

----------------------------------------------------------

-- Denies cast on units that arent summons and check if the unit has enough mana cost to dominate it
function ControlMagicCheck( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local pID = caster:GetPlayerOwnerID()
    
    if not target:IsSummoned() then
        caster:Interrupt()
        SendErrorMessage(pID, "#error_must_target_summon")
    else
        local targetHP = target:GetHealth()
        local casterMana = caster:GetMana()
        local mana_control_rate = ability:GetLevelSpecialValueFor("mana_control_rate", ability:GetLevel() - 1 )
        local mana_cost = math.floor(targetHP*mana_control_rate + ability:GetManaCost(ability:GetLevel() - 1))
        print("Need "..mana_cost.." Have "..casterMana)
        if mana_cost > casterMana then
            caster:Interrupt()
            SendErrorMessage(pID, "Need at least "..mana_cost.." Mana")
        end
    end
end

-- Takes control of the target
function ControlMagic( event )
    local caster = event.caster
    local target = event.target

    -- Change ownership
    print("Control Magic")
    target:Stop()
    target:SetTeam( caster:GetTeamNumber() )
    target:SetOwner(caster)
    target:SetControllableByPlayer( caster:GetPlayerOwnerID(), true )
    target:RespawnUnit()
    target:SetHealth(target:GetHealth())
end