function SentinelCheck(event)
    local caster = event.caster
    local tree = event.target

    if tree.owl then
        SendErrorMessage(caster:GetPlayerOwnerID(), "error_tree_owl_occupied")
        caster:Interrupt()
    end
end

function Sentinel( event )
    local caster = event.caster
    local player = caster:GetPlayerOwner()
    local hero = player:GetAssignedHero()
    local tree = event.target
    local ability = event.ability
    local fv = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
    local front_position = origin + fv * 100
    local vision = ability:GetSpecialValueFor("vision_aoe")
    local charges = ability:GetSpecialValueFor("charges")

    -- Expend a charge
    if not ability.used_charges then ability.used_charges = 0 end
    ability.used_charges = ability.used_charges + 1

    ---- Hide the ability once the charges are used
    --if ability.used_charges >= charges then
    --    ability:SetHidden(true)
    --end
        
    -- Create the unit
    local sentinel = CreateUnitByName("nightelf_sentinel_owl", front_position, true, hero, hero, caster:GetTeamNumber())
    sentinel:SetForwardVector(fv)
    sentinel:AddNewModifier(caster,nil,"modifier_summoned",{})
    ability:ApplyDataDrivenModifier(sentinel, sentinel, "modifier_sentinel", {})
    tree.owl = sentinel
    sentinel.tree = tree
    caster.sentinel = sentinel
    
    -- Move towards the selected tree
    local tree_pos = tree:GetAbsOrigin()
    Timers:CreateTimer(function()
        sentinel:MoveToPosition(tree_pos)
        local distance_to_tree = (sentinel:GetAbsOrigin() - tree_pos):Length()

        -- Kill the sentinel if the tree is cut down on its travel
        if not tree:IsStanding() then
            sentinel:ForceKill(false)

        -- Place it on top of the tree looking in the direction of the caster
        elseif distance_to_tree < 50 then
            sentinel:SetDayTimeVisionRange(vision)
            sentinel:SetNightTimeVisionRange(vision)
            sentinel:SetAbsOrigin(Vector(tree_pos.x, tree_pos.y, tree_pos.z))
            sentinel:Stop()
            Timers:CreateTimer(0.03, function() sentinel:Stop() sentinel:SetForwardVector(-fv) end)
        else
            return 0.1
        end
        return
    end)
end

function SentinelTreeCheck(event)
    if not event.caster.tree:IsStanding() then
        event.caster:ForceKill(false)
    end
end