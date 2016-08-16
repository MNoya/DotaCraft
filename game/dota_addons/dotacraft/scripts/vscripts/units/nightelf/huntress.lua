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

--------------------------------------------------

nightelf_moon_glaive = class({})

LinkLuaModifier("modifier_moon_glaive", "units/nightelf/huntress.lua", LUA_MODIFIER_MOTION_NONE)

function nightelf_moon_glaive:GetIntrinsicModifierName()
    return "modifier_moon_glaive"
end

function nightelf_moon_glaive:OnUpgrade()
    self.reduction = self:GetSpecialValueFor("damage_reduction_percent") * 0.01
end

function nightelf_moon_glaive:OnProjectileHit_ExtraData(target, vLocation, extraData)
    ApplyDamage({victim = target, attacker = self:GetCaster(), damage = extraData.damage, ability = self, damage_type = DAMAGE_TYPE_PHYSICAL})
    extraData.bounces_left = extraData.bounces_left - 1

    local impact = ParticleManager:CreateParticle("particles/custom/nightelf/luna_moon_glaive_impact_point1.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControlEnt(impact, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

    -- If there are bounces remaining, find a new target
    if extraData.bounces_left > 0 then
        extraData.targets_hit = extraData.targets_hit .. "," .. target:GetEntityIndex()
        extraData.damage = extraData.damage * self.reduction
        CreateMoonGlaive(self, target, extraData)
    end
end

function CreateMoonGlaive(ability, originalTarget, extraData)
    local caster = ability:GetCaster()
    local enemies = FindUnitsInRadius(caster:GetTeamNumber(), originalTarget:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
    local targets_hit = split(extraData.targets_hit, ",")
    local target
    for _,enemy in pairs(enemies) do
        bAlreadyHit = getIndexTable(targets_hit, tostring(enemy:GetEntityIndex()))
        if not bAlreadyHit and not enemy:IsWard() and not enemy:HasFlyMovementCapability() and not enemy:IsAttackImmune() then
            target = enemy
            break
        end
    end

    if target then
        local impact = ParticleManager:CreateParticle("particles/custom/nightelf/luna_moon_glaive_impact_point1.vpcf", PATTACH_ABSORIGIN_FOLLOW, originalTarget)
        ParticleManager:SetParticleControlEnt(impact, 1, originalTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", originalTarget:GetAbsOrigin(), true)
        local projectile = {
            Target = target,
            Source = originalTarget,
            Ability = ability,
            EffectName = "particles/units/heroes/hero_luna/luna_moon_glaive_bounce.vpcf",
            bDodgable = true,
            bProvidesVision = false,
            iMoveSpeed = 900,
            iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
            ExtraData = extraData
        }
        ProjectileManager:CreateTrackingProjectile(projectile)
    end
end

--------------------------------------------------

modifier_moon_glaive = class({})

function modifier_moon_glaive:IsHidden() return true end
function modifier_moon_glaive:IsPurgable() return false end

function modifier_moon_glaive:DeclareFunctions()
    return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_moon_glaive:OnAttackLanded(event)
    if event.attacker == self:GetParent() then
        local ability = self:GetAbility()
        local target = event.target
        target:EmitSound("Hero_Luna.MoonGlaive.Impact")
        CreateMoonGlaive(ability, target, {bounces_left = ability:GetSpecialValueFor("bounces"), damage = event.damage*ability.reduction, targets_hit = tostring(target:GetEntityIndex())})
    end
end

function modifier_moon_glaive:OnCreated()
    if IsServer() then
        local target = self:GetParent()
        local particleName = "particles/units/heroes/hero_luna/luna_ambient_moon_glaive.vpcf"
        if self:GetAbility():GetAbilityName() == "nightelf_upgraded_moon_glaive" then
            particleName = "particles/econ/items/luna/luna_lucent_rider/luna_ambient_glaive_lucent_rider.vpcf"
        end
        local ambient = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, target)
        ParticleManager:SetParticleControlEnt(ambient, 0, target, PATTACH_POINT_FOLLOW, "attach_weapon", target:GetAbsOrigin(), true)
        self:AddParticle(ambient,false,false,1,false,false)
    end 
end

--------------------------------------------------

nightelf_upgraded_moon_glaive = class({})

function nightelf_upgraded_moon_glaive:GetIntrinsicModifierName()
    return "modifier_moon_glaive"
end

function nightelf_upgraded_moon_glaive:OnUpgrade()
    self.reduction = self:GetSpecialValueFor("damage_reduction_percent") * 0.01
end

function nightelf_upgraded_moon_glaive:OnProjectileHit_ExtraData(target, vLocation, extraData)
    ApplyDamage({victim = target, attacker = self:GetCaster(), damage = extraData.damage, ability = self, damage_type = DAMAGE_TYPE_PHYSICAL})
    extraData.bounces_left = extraData.bounces_left - 1

    -- If there are bounces remaining, find a new target
    if extraData.bounces_left > 0 then
        extraData.targets_hit = extraData.targets_hit .. "," .. target:GetEntityIndex()
        extraData.damage = extraData.damage * self.reduction
        CreateMoonGlaive(self, target, extraData)
    end
end