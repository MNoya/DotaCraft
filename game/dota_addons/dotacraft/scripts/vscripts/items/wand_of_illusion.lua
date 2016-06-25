function Illusion(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local playerID = caster:GetPlayerID()
    local unit_name = target:GetUnitName()
    local duration = ability:GetLevelSpecialValueFor( "illusion_duration", ability:GetLevel() - 1 )
    local outgoingDamage = ability:GetLevelSpecialValueFor( "illusion_outgoing_damage", ability:GetLevel() - 1 ) - 100
    local incomingDamage = ability:GetLevelSpecialValueFor( "illusion_incoming_damage", ability:GetLevel() - 1 )

    -- Get a random position to create the illusion in
    local origin = target:GetAbsOrigin() + target:GetForwardVector() * RandomInt(100,150)

    -- handle_UnitOwner needs to be nil, else it will crash the game.
    local illusion = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
    illusion:SetControllableByPlayer(playerID,true)
    illusion:SetForwardVector(target:GetForwardVector())
    FindClearSpaceForUnit(illusion,origin,true)
    if target:IsHero() then
        illusion:SetPlayerID(playerID)

        -- Level Up the unit to the casters level
        local lvl = target:GetLevel()
        for i=1,lvl-1 do
            illusion:HeroLevelUp(false)
        end

        -- Set the skill points to 0 and learn the skills of the caster
        illusion:SetAbilityPoints(0)
        for abilitySlot=0,15 do
            local ability = caster:GetAbilityByIndex(abilitySlot)
            if ability then 
                local abilityLevel = ability:GetLevel()
                if abilityLevel > 0 then
                    local abilityName = ability:GetAbilityName()
                    local illusionAbility = illusion:FindAbilityByName(abilityName)
                    illusionAbility:SetLevel(abilityLevel)
                end
            end
        end

        -- Recreate the items of the caster
        for itemSlot=0,5 do
            local item = caster:GetItemInSlot(itemSlot)
            if item ~= nil then
                local itemName = item:GetName()
                local newItem = CreateItem(itemName, illusion, illusion)
                illusion:AddItem(newItem)
            end
        end
    end

    -- Set the unit as an illusion
    -- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
    print(outgoingDamage, incomingDamage)
    illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage })
        
    -- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
    illusion:MakeIllusion()

    ParticleManager:CreateParticle("particles/generic_gameplay/illusion_created.vpcf",PATTACH_ABSORIGIN_FOLLOW,illusion)
end