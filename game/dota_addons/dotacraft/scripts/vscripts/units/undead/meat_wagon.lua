-- Picks up a corpse in range
function GetCorpse(keys)
    local caster = keys.caster
    local ability = keys.ability
    local playerID = caster:GetPlayerOwnerID()
    local search_radius = keys.ability:GetSpecialValueFor("search_radius")
    local stackCount = caster:GetModifierStackCount("modifier_corpses", caster)
    local max_corpses = keys.ability:GetSpecialValueFor("max_corpses")
    
    -- if equal to max allowed corpses, return
    if stackCount >= max_corpses then return end
    
    local corpses = Corpses:FindInRadiusOutside(playerID, caster:GetAbsOrigin(), search_radius)
    
    -- todo: move towards the corpse, instead of tele-grabbing them
    for _,corpse in pairs(corpses) do
        if not corpse.meat_wagon then
            AddCorpse(caster, corpse)
            break
        end
    end
end

-- Generates corpses every 15 seconds
function ExhumeCorpse(keys)
    local caster = keys.caster
    local ability = keys.ability
    local stackCount = caster:GetModifierStackCount("modifier_corpses", caster)
    local corpse_ability = caster:FindAbilityByName("undead_get_corpse")
    local max_corpses = corpse_ability:GetSpecialValueFor("max_corpses")

    -- if the unit doesn't have max corpses yet
    if stackCount < max_corpses then
        AddCorpse(caster, Corpses:CreateByNameOnPosition("undead_ghoul", caster:GetAbsOrigin(), caster:GetTeamNumber()))
        ability:StartCooldown(15)
    end 
end

-- Adds one corpse handle to the meat wagon
function AddCorpse(meat_wagon, corpse)
    corpse.meat_wagon = meat_wagon
    corpse.playerID = meat_wagon:GetPlayerOwnerID()
    corpse:AddNoDraw()
    corpse:StopExpiration()
    corpse:SetParent(meat_wagon,"attach_hitloc")
    table.insert(meat_wagon.corpses, corpse)

    -- Update indicators
    local stackCount = meat_wagon:GetModifierStackCount("modifier_corpses", meat_wagon)+1
    meat_wagon:SetModifierStackCount("modifier_corpses", meat_wagon, stackCount)        
    
    for i=1,stackCount do
        ParticleManager:SetParticleControl(meat_wagon.counter_particle, i, Vector(1,0,0))
    end
    if stackCount < 8 then
        for i=stackCount+1,8 do
            ParticleManager:SetParticleControl(meat_wagon.counter_particle, i, Vector(0,0,0))
        end
    end
end

-- Timer for picking up corpses
function GetCorpse_Autocast(keys)
    local caster = keys.caster
    local meat_wagon = caster
    local ability = keys.ability
    local search_radius = keys.ability:GetSpecialValueFor("search_radius")
    local max_corpses = keys.ability:GetSpecialValueFor("max_corpses")
    
    caster.corpses = {}
    caster.counter_particle = ParticleManager:CreateParticle("particles/custom/undead/corpse_counter.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)

    -- Removes one specific corpse from the meat wagon
    function meat_wagon:RemoveCorpse(corpse)
        corpse.meat_wagon = nil
        corpse:RemoveNoDraw()
        corpse:StartExpiration()
        corpse:SetParent(nil,"")
        local index = getIndexTable(meat_wagon.corpses, corpse)
        if index then
            table.remove(meat_wagon.corpses, index)
        end
        
        -- Update indicators
        local stackCount = meat_wagon:GetModifierStackCount("modifier_corpses", meat_wagon) - 1
        meat_wagon:SetModifierStackCount("modifier_corpses", meat_wagon, stackCount)

        if stackCount > 0 then
            for i=1,stackCount do
                ParticleManager:SetParticleControl(meat_wagon.counter_particle, i, Vector(1,0,0))
            end
        end
        for i=stackCount+1,8 do
            ParticleManager:SetParticleControl(meat_wagon.counter_particle, i, Vector(0,0,0))
        end
    end

    -- Removes and throws a corpse around the meat wagon
    function meat_wagon:ThrowCorpse(corpse)
        corpse = corpse or meat_wagon.corpses[#meat_wagon.corpses] -- Last one if no corpse is passed
        meat_wagon:RemoveCorpse(corpse)
        corpse:SetAbsOrigin(meat_wagon:GetAbsOrigin() + RandomVector(150))
        return corpse
    end

    Timers:CreateTimer(function()
        if not IsValidAlive(caster) or not caster:IsAlive() then return end 
        local stack_count = caster:GetModifierStackCount("modifier_corpses", caster) or 0
        
        -- Find corpses outside the meat wagon
        if stack_count < max_corpses then
            if caster:IsIdle() and ability:GetAutoCastState() and ability:IsCooldownReady() then
                local playerID = caster:GetPlayerOwnerID()
                local corpses = Corpses:FindInRadius(playerID, caster:GetAbsOrigin(), search_radius)
                for k,corpse in pairs(corpses) do
                    if not corpse.meat_wagon then
                        caster:CastAbilityNoTarget(ability, playerID)           
                    end 
                end                     
            end
        end
        return 1
    end)
end

-- Starts dropping corpses every 0.5 seconds or until ordered to do something else
function DropCorpse(keys)
    local caster = keys.caster
    local ability = keys.ability
    local get_corpse_ability = caster:FindAbilityByName("undead_get_corpse")
    local stackCount = caster:GetModifierStackCount("modifier_corpses", caster) 

    -- turn off autocast so that the meat wagon doesn't automatically pick up the corpse again
    if get_corpse_ability:GetAutoCastState() then
        get_corpse_ability:ToggleAutoCast()
    end
    -- cancel on order
    ability:ApplyDataDrivenModifier(caster,caster,"modifier_dropping_corpses",{})

    local stackCount = caster:GetModifierStackCount("modifier_corpses", caster)
    if stackCount == 0 then return end
    
    -- Pop the last corpse outside
    local corpse = caster:ThrowCorpse()

    if ability.drop_corpse_timer then Timers:RemoveTimer(ability.drop_corpse_timer) end
    ability.drop_corpse_timer = Timers:CreateTimer(0.5, function()
        if not IsValidEntity(caster) or not caster:IsAlive() then return end
        local stackCount = caster:GetModifierStackCount("modifier_corpses", caster)
        if caster:HasModifier("modifier_dropping_corpses") and stackCount > 0 then
            caster:ThrowCorpse()
            return 0.5
        end
    end)
end

-- Called OnOwnerDied, throwing all corpses immediately
function DropAllCorpses(keys)
    local caster = keys.caster
    local ability = keys.ability
    local origin = caster:GetAbsOrigin()
    
    for _,corpse in pairs(caster.corpses) do
        corpse.meat_wagon = nil
        corpse:RemoveNoDraw()
        corpse:SetParent(nil,"")
        caster:SetAbsOrigin(origin + RandomVector(150))
    end
    caster.corpses = {}
end

-------------------------------------------------------------------------------

function UnlockDiseaseCloud(event)
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetSpecialValueFor("duration")
    SetRangedProjectileName(caster, "particles/custom/undead/meat_wagon_disease_attack.vpcf")
    
    caster.OnAttackGround = function (position)
        local disease_cloud_dummy = CreateUnitByName("dummy_unit_disease_cloud", position, false, nil, nil, caster:GetTeamNumber())
        local explosion = ParticleManager:CreateParticle("particles/custom/undead/rot_recipient.vpcf",PATTACH_ABSORIGIN_FOLLOW,disease_cloud_dummy)
        Timers:CreateTimer(1, function() ParticleManager:DestroyParticle(explosion,true) end)
        Timers:CreateTimer(duration, function()
            UTIL_Remove(disease_cloud_dummy)
        end)
    end
end