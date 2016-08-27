function StoneForm(event)
    local caster = event.caster
    local origin = caster:GetAbsOrigin()
    local ability = event.ability

    -- Prevent landing on deep water (Error: "Unable to land there")
    -- Find a clear space for landing, don't land or trees or buildings
    local treeBlocked = GridNav:IsNearbyTree(origin, 30, true)
    local terrainBlocked = not GridNav:IsTraversable(origin) or GridNav:IsBlocked(origin)
    local location = origin
    if treeBlocked or terrainBlocked then
        location = BuildingHelper:FindClosestEmptyPositionNearby(origin, 1, 500, true)
        if not location then
            SendErrorMessage(caster:GetPlayerOwnerID(), "error_unable_to_land_there")
            return
        end
    end
    
    if not caster:HasModifier("modifier_stone_form") then
        ToggleOn(ability)
        caster:Stop()
        if location ~= origin then
            ability:ApplyDataDrivenModifier(caster,caster,"modifier_stone_form_order",{})
            Timers:CreateTimer(0.03, function()
                caster:MoveToPosition(location)
                if (caster:GetAbsOrigin()-location):Length2D() > 10 then
                    return 0.03
                else
                    caster:RemoveModifierByName("modifier_stone_form_order")
                    ability:ApplyDataDrivenModifier(caster, caster, "modifier_stone_form_transform", {})
                end
            end)
        else
            ability:ApplyDataDrivenModifier(caster, caster, "modifier_stone_form_transform", {})
        end

    else -- give flying capabilities and remove modifier & animation
        ToggleOff(ability)      
        caster:RemoveModifierByName("modifier_animation_freeze")
        caster:RemoveModifierByName("modifier_stone_form")
        ability:StartCooldown(30)
        caster:RemoveGesture(ACT_DOTA_CAST_ABILITY_1)
        caster:StartGesture(ACT_DOTA_SPAWN)
        ability:ApplyDataDrivenModifier(caster, caster, "modifier_stone_form_transform_end", {})
    end
end

function StoneFormStart(event)
    local caster = event.caster
    local ability = event.ability
    caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_stone_form_transform", {})
    caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)

    Timers:CreateTimer(1.2, function()
        if caster:HasModifier("modifier_stone_form") then
            FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
            caster:AddNewModifier(caster,nil,"modifier_animation_freeze",{})
        end
    end)
end

function StoneFormEnd(event)
    local caster = event.caster
    caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
end