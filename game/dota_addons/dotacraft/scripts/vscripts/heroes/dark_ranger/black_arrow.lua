function OrbCheck(event)
    local target = event.target
    local caster = event.caster

    if target:IsMechanical() or IsCustomBuilding(target) then
        caster:RemoveModifierByName("modifier_black_arrow")
    else
        if not caster:HasModifier("modifier_black_arrow") then
            local ability = event.ability
            ability:ApplyDataDrivenModifier(caster,caster,"modifier_black_arrow",{})
        end
    end
end

function SpawnMinion(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel()-1)
    local position = event.unit:GetAbsOrigin()
    local minionName = "undead_black_arrow_minion_"..ability:GetLevel()

    local minion = caster:CreateSummon(minionName, position, duration)
    minion:EmitSound("Hero_Medusa.MysticSnake.Return")
end