function SpawnScout(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("owl_duration", ability:GetLevel()-1)
    local fv = caster:GetForwardVector()
    local position = caster:GetAbsOrigin() + fv * 150
    local playerID = caster:GetPlayerOwnerID()
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local owlName = "nightelf_owl_"..ability:GetLevel()

    local owl = CreateUnitByName(owlName, position, true, hero, hero, caster:GetTeamNumber())
    owl:SetForwardVector(fv)
    owl:SetControllableByPlayer(playerID, true)
    owl:AddNewModifier(caster, ability, "modifier_kill", {duration=duration})
    ability:ApplyDataDrivenModifier(caster, owl, "modifier_owl_scout", {})
    owl:AddNewModifier(caster, ability, "modifier_summoned", {})
end