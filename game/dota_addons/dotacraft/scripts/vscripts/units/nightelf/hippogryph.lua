-- Move towards an archer to pick it up
function PickUpArcher(event)
    local caster = event.caster
    local ability = event.ability
    local owner = caster:GetOwner()
    local player = caster:GetPlayerOwner()
    local radius = ability:GetCastRange()
    local origin = caster:GetAbsOrigin()
    local playerID = caster:GetPlayerOwnerID()

    ability:EndCooldown()
    ability.cancelled = false

    local units
    local archer = ability.archer -- This can be assigned through the archer's mount hippogryph skill
    if not archer then
        units = FindUnitsInRadius(caster:GetTeamNumber(), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, 0, FIND_CLOSEST, false)
        for _,unit in pairs(units) do
            if unit:GetUnitName() == "nightelf_archer" and unit:GetOwner() == owner and not unit:HasModifier("modifier_mounted_archer") and not unit.hippogryph_assigned then
                archer = unit
                break
            end
        end
    end

    if archer then
        -- Fake toggle the ability
        ToggleOn(ability)
        archer.hippogryph_assigned = caster
        caster.archer = archer -- To let other archers know that this hippo has already acquired 1 archer
        Timers:CreateTimer(function() 
            if not IsValidEntity(caster) or not caster:IsAlive() then 
                archer.hippogryph_assigned = nil
                return 
            end

            if not IsValidEntity(archer) or not archer:IsAlive() then
                caster.archer = nil
                return
            end

            -- Move towards the archer until 100 range
            if archer and IsValidEntity(archer) and not ability.cancelled then
                local archer_pos = archer:GetAbsOrigin()
                local distance = (archer_pos - caster:GetAbsOrigin()):Length2D()
                
                if distance > 100 then
                    caster:MoveToPosition(archer_pos)
                    return 0.1
                else
                    ability:StartCooldown(ability:GetCooldown(1))
                    ability:ApplyDataDrivenModifier(caster, archer, "modifier_mounted_archer", {})

                    local new_hippo = CreateUnitByName("nightelf_hippogryph_rider", caster:GetAbsOrigin(), false, caster:GetOwner(), caster:GetPlayerOwner(), caster:GetTeamNumber())
                    new_hippo:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
                    new_hippo:SetOwner(owner)
                    new_hippo.archer = archer
                    new_hippo:SetHealth(caster:GetHealth() + archer:GetHealth())

                    local dismount_ability = new_hippo:FindAbilityByName("nightelf_dismount")
                    if dismount_ability then
                        dismount_ability:StartCooldown(dismount_ability:GetCooldown(1))
                    end

                    -- Remove any shadow meld components
                    archer:RemoveModifierByName("modifier_shadow_meld_active")
                    archer:RemoveModifierByName("modifier_shadow_meld")
                    archer:RemoveModifierByName("modifier_invisibility")
                    ExecuteOrderFromTable({ UnitIndex = archer:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_STOP, Queue = false})

                    Timers:CreateTimer(0.2, function()
                        local attach = new_hippo:ScriptLookupAttachment("attach_hitloc") --Hippogryph mount
                        local origin = new_hippo:GetAttachmentOrigin(attach)
                        local fv = new_hippo:GetForwardVector()
                        local pos = origin - fv

                        archer:SetAbsOrigin(Vector(pos.x, pos.y, origin.z-25))
                        archer:SetParent(new_hippo, "attach_hitloc")
                        archer:SetAngles(90,30,0)
                    end)

                    if PlayerResource:IsUnitSelected(playerID, archer) then
                        PlayerResource:AddToSelection(playerID, new_hippo)
                        PlayerResource:RemoveFromSelection(playerID, archer)
                    end

                    -- Add hippogryph rider to table (archer remains, so that upgrades are also added in the back)
                    Players:AddUnit(playerID, new_hippo)

                    -- Marksmanship, Improved Bows
                    CheckAbilityRequirements( new_hippo, playerID )

                    -- Remove hippo
                    Players:RemoveUnit(playerID, caster)
                    caster:RemoveSelf()
                end
            else
                ability:EndCooldown()
                return
            end
        end)
    else
        ToggleOff(ability)
        ability:EndCooldown()
    end
end

-- OnOrder
function CancelPickup(event)
    local caster = event.caster
    local ability = event.ability
    ToggleOff(ability)
    ability:EndCooldown()
    ability.cancelled = true
    caster.archer = nil
    if ability.archer then
        ability.archer.hippogryph_assigned = nil
        ability.archer = nil
    end
end

-- OnOrbFire
function FakeArcherAttack(event)
    local caster = event.caster
    local ability = event.ability
    local target = event.target
    local archer = caster.archer

    if archer then
        archer:StartGesture(ACT_DOTA_ATTACK)
    end
end

-- Disengage the archer and make a nightelf_hippogryph with the current HP
function Dismount(event)
    local caster = event.caster
    local archer = caster.archer
    local playerID = archer:GetPlayerOwnerID()
    local fv = caster:GetForwardVector()
    local healthPercent = caster:GetHealthPercent() * 0.01
    archer.hippogryph_assigned = nil

    local new_hippo = CreateUnitByName("nightelf_hippogryph", caster:GetAbsOrigin(), false, caster:GetOwner(), caster:GetPlayerOwner(), caster:GetTeamNumber())
    new_hippo:SetControllableByPlayer(0, true)
    new_hippo:SetOwner(caster:GetOwner())
    new_hippo:SetForwardVector(fv)
    new_hippo.archer = nil
    new_hippo:SetHealth(math.max(healthPercent * new_hippo:GetMaxHealth(),1))

    Timers:CreateTimer(0.2, function()
        local origin = archer:GetAbsOrigin()
        local ground = GetGroundHeight(origin, archer)
        archer:RemoveModifierByName("modifier_mounted_archer")
        archer:SetAbsOrigin(Vector(origin.x, origin.y, ground))
        archer:SetForwardVector(fv)
        archer:SetParent(nil, "")
        archer:SetHealth(math.max(healthPercent * archer:GetMaxHealth(),1))

        local mount_ability = archer:FindAbilityByName("nightelf_mount_hippogryph")
        if mount_ability then
            mount_ability:StartCooldown(mount_ability:GetCooldown(1))
        end

        local pick_up_ability = new_hippo:FindAbilityByName("nightelf_pick_up_archer")
        if pick_up_ability then
            pick_up_ability:StartCooldown(pick_up_ability:GetCooldown(1))
            pick_up_ability.archer = nil
        end
        PlayerResource:AddToSelection(playerID, new_hippo)
        PlayerResource:AddToSelection(playerID, archer)
    
        -- Add weapon/armor upgrade benefits
        Players:AddUnit(playerID, new_hippo)
        
        -- Remove the old hippo
        Players:RemoveUnit(playerID, caster)
        caster:RemoveSelf()
    end)
end

-- Archer stays put while an hippogryph comes to pick it up
function CallHippogryph(event)
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetCastRange()+caster:GetHullRadius()
    local origin = caster:GetAbsOrigin()

    local units = FindUnitsInRadius(caster:GetTeamNumber(), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, 0, FIND_CLOSEST, false)
    local hippo = nil
    for _,unit in pairs(units) do
        if unit:GetUnitName() == "nightelf_hippogryph" then
            local pickup_ability = unit:FindAbilityByName("nightelf_pick_up_archer")
            if pickup_ability:IsFullyCastable() and pickup_ability:GetToggleState() == false and not unit.archer then
                hippo = unit
                break
            end
        end
    end

    if hippo then
        local ability = hippo:FindAbilityByName("nightelf_pick_up_archer")
        ability.archer = caster -- Tell the hippo to get THIS archer, not anyone
        hippo.archer = caster -- Other archers will skip this hippo on their search
        ExecuteOrderFromTable({ UnitIndex = hippo:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = ability:GetEntityIndex(), Queue = false})

        -- Look towards the hippo, disable autoattack
        local pos = caster:GetAbsOrigin() + (hippo:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
        DisableAggro(caster)
        caster:MoveToPosition(pos)
        Timers:CreateTimer(0.1, function()
            ExecuteOrderFromTable({ UnitIndex = caster:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_HOLD_POSITION, Queue = false})
        end)
    else
        ability:EndCooldown()
    end
end

-- Remove the archer when the hippogryph rider has a natural death
function KillArcher(event)
    local archer = event.caster.archer
    if IsValidEntity(archer) then
        local playerID = archer:GetPlayerOwnerID()
        Players:RemoveUnit(playerID, archer)
        archer:RemoveSelf()
    end
end