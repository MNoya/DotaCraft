function HealAutocast(event)
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetCastRange()

    if not caster:IsMoving() and ability:GetAutoCastState() and ability:IsFullyCastable() then
        -- Check that there are valid units with HP missing
        local units = FindAlliesInRadius(caster, radius)
        for _,target in pairs(units) do
            if not IsCustomBuilding(target) and not target:IsMechanical() and not target:IsWard() and target:GetHealthDeficit() > 0 then
                caster:CastAbilityNoTarget(ability,caster:GetPlayerOwnerID())
                return
            end
        end
    end
end

function Heal(event)
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetCastRange()
    local max = ability:GetSpecialValueFor("max_unit")
    local units = FindAlliesInRadius(caster, radius)

    local targets = {}
    local count = 0
    for _,target in pairs(units) do
        if not IsCustomBuilding(target) and not target:IsMechanical() and not target:IsWard() and not target:HasModifier("modifier_essence_of_blight") and target:GetHealthDeficit() > 0 then
            table.insert(targets, target)
            count = count + 1
        end
        if count == max_unit then break end
    end

    if count > 0 then
        for _,target in pairs(targets) do
            ability:ApplyDataDrivenModifier(caster,target,"modifier_essence_of_blight",{duration=0.9})
        end
    end

    -- Refund mana cost if it healed less than 5 units
    if count < 5 then
        local manaCost = ability:GetManaCost(1)
        local refund = manaCost - math.max(2, count*2)
        caster:GiveMana(refund)
    end

    ParticleManager:CreateParticle("particles/custom/undead/essence_of_blight_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end

function EssenceOfBlight(event)
    local target = event.target
    local ability = event.ability
    local health_restore = ability:GetSpecialValueFor("health_restore")
    target:Heal(health_restore,ability)
    ParticleManager:CreateParticle("particles/custom/undead/essence_of_blight.vpcf",PATTACH_ABSORIGIN_FOLLOW,target)
end

----------------------------------------------------------------

function ManaAutocast(event)
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetCastRange()

    if not caster:IsMoving() and ability:GetAutoCastState() and ability:IsFullyCastable() then
        -- Check that there are valid units with Mana missing
        local units = FindAlliesInRadius(caster, radius)
        for _,target in pairs(units) do
            if not IsCustomBuilding(target) and not target:IsMechanical() and not target:IsWard() and target:GetMaxMana()-target:GetMana() > 0 then
                caster:CastAbilityNoTarget(ability,caster:GetPlayerOwnerID())
                return
            end
        end
    end
end

function Mana(event)
    local caster = event.caster
    local ability = event.ability
    local radius = ability:GetCastRange()
    local max = ability:GetSpecialValueFor("max_unit")
    local units = FindAlliesInRadius(caster, radius)

    local targets = {}
    local count = 0
    for _,target in pairs(units) do
        if not IsCustomBuilding(target) and not target:IsMechanical() and not target:IsWard() and not target:HasModifier("modifier_spirit_touch") and target:GetMaxMana() ~= target:GetMana() then
            table.insert(targets, target)
            count = count + 1
        end
        if count == max_unit then break end
    end

    if count > 0 then
        for _,target in pairs(targets) do
            ability:ApplyDataDrivenModifier(caster,target,"modifier_spirit_touch",{duration=0.9})
        end
    end

    -- Refund mana cost if it healed less than 5 units
    if count < 5 then
        local manaCost = ability:GetManaCost(1)
        local refund = manaCost - math.max(2, count*2)
        caster:GiveMana(refund)
    end

    ParticleManager:CreateParticle("particles/custom/undead/spirit_touch_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end

function SpiritTouch(event)
    local target = event.target
    local ability = event.ability
    local mana_restore = ability:GetSpecialValueFor("mana_restore")
    target:GiveMana(mana_restore)
    ParticleManager:CreateParticle("particles/custom/undead/spirit_touch.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
end

----------------------------------------------------------------

function DestroyerMorph(event)
    local caster = event.caster
    local playerID = caster:GetPlayerOwnerID()
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)

    Timers:CreateTimer(1.1, function() -- wait  
        local destroyer = CreateUnitByName("undead_destroyer", caster:GetAbsOrigin(), true, hero,  hero, caster:GetTeamNumber())
        destroyer:SetControllableByPlayer(playerID, true)
        destroyer:SetForwardVector(caster:GetForwardVector())
        
        caster:SetNoCorpse()
        Players:AddUnit(playerID, destroyer)
        Players:RemoveUnit(playerID, caster)
        
        ParticleManager:CreateParticle("particles/siege_fx/siege_bad_death_01.vpcf", PATTACH_ABSORIGIN, destroyer)

        if PlayerResource:IsUnitSelected(playerID, caster) then
            PlayerResource:AddToSelection(playerID, destroyer)
        end

        caster:RemoveSelf()
    end)
end

----------------------------------------------------------------

-- Attaches a catapult
function Model(event)
    local caster = event.caster
    local ability = event.ability

    local statue = CreateUnitByName("undead_obsidian_statue_dummy", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())
    ability:ApplyDataDrivenModifier(caster, statue, "modifier_disable_statue", {})

    local attach = caster:ScriptLookupAttachment("attach_hitloc")
    local origin = caster:GetAttachmentOrigin(attach)
    local fv = caster:GetForwardVector()

    statue:SetAbsOrigin(Vector(origin.x, origin.y, origin.z-130))
    statue:SetParent(caster, "attach_hitloc")
    statue:SetAngles(0,0,0)
end