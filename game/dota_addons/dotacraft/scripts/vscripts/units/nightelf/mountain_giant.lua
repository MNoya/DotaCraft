function GrowModel( event )
    local caster = event.caster
    local ability = event.ability

    Timers:CreateTimer(function()
        local wearables = caster:GetChildren()
        for _,wearable in pairs(wearables) do
            if wearable:GetClassname() == "dota_item_wearable" then
                if not wearable:GetModelName():match("tree") then
                    local new_model_name = string.gsub(wearable:GetModelName(),"1","4")
                    wearable:SetModel(new_model_name)
                else
                    caster.tree = wearable
                    wearable:AddEffects(EF_NODRAW)
                end
            end
        end
        return false
    end)
end

function WarClub( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability

    caster:StartGesture(ACT_DOTA_ATTACK)
    Timers:CreateTimer(0.5, function()
        target:CutDown(caster:GetTeamNumber())
    end)

    Timers:CreateTimer(1, function()
        caster:AddNewModifier(caster, nil, "modifier_animation_translate", {translate="tree"})
        caster:SetModifierStackCount("modifier_animation_translate", caster, 310)
        caster.tree:RemoveEffects(EF_NODRAW)

        ability:ApplyDataDrivenModifier(caster, caster, "modifier_war_club", {})
        ability:ApplyDataDrivenModifier(caster, caster, "modifier_war_club_strikes", {})
        local strikes = ability:GetSpecialValueFor("strikes")
        caster:SetModifierStackCount("modifier_war_club_strikes", caster, strikes)

        caster:SetAttackType("siege")
    end)
end

function WarClubStrike( event )
    local caster = event.caster
    local ability = event.ability
    local target = event.target
    local damage = event.Damage
    local strikes = ability:GetSpecialValueFor("strikes")
    local stack_count = caster:GetModifierStackCount("modifier_war_club_strikes", caster)

    if IsCustomBuilding(target) then
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_grow_cleave.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
    end

    if stack_count > 1 then
        caster:SetModifierStackCount("modifier_war_club_strikes", caster, stack_count - 1)
    else
        caster:RemoveModifierByName("modifier_war_club")
        caster:RemoveModifierByName("modifier_war_club_strikes")
        caster:RemoveModifierByName("modifier_animation_translate")
        caster.tree:AddEffects(EF_NODRAW)

        caster:SetAttackType("normal")
    end 
end

function Taunt( event )
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetSpecialValueFor("radius")
    local max_units = ability:GetSpecialValueFor("max_units")

    caster:StartGesture(ACT_TINY_GROWL)
    
    local count = 0
    local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
    for _,unit in pairs(targets) do
        if not IsCustomBuilding(unit) and unit:HasAttackCapability() and not IsChanneling(unit) and not unit:HasModifier("modifier_repairing") then
            count = count + 1
            unit:MoveToTargetToAttack(caster)
        end
        if count == max_units then return end
    end
end