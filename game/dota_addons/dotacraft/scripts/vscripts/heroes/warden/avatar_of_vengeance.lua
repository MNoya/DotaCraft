-- Kills all the nightelf_spirit_of_vengeance spawned
function KillVengeanceSpirits(event)
    local caster = event.caster

    for _,v in pairs(caster.spirits) do
        if v and IsValidEntity(v) and v:IsAlive() then
            v:ForceKill(false)
        end
    end

    caster.spirit_count = 0
    caster.spirits = {}
end

-- Checks in radius to create new spirits if possible
function SpiritOfVengeanceAutocast( event )
    local ability = event.ability
    local caster = event.caster
    if ability:GetAutoCastState() then
        local playerID = caster:GetPlayerOwnerID()
        local corpse = Corpses:FindClosestInRadius(playerID, caster:GetAbsOrigin(), ability:GetCastRange())
        local spirit_limit = ability:GetSpecialValueFor( "spirit_limit" )
        if corpse and caster.spirit_count and caster.spirit_count < spirit_limit then
            caster:CastAbilityNoTarget(ability, playerID)
        end
    end
end

function InitializeSpiritCount( event )
    local caster = event.caster

    -- Initialize the table of spirits
    caster.spirits = {}
    caster.spirit_count = 0
end

-- When a spirit times out or gets killed
function UpdateSpirits( event )
    local caster = event.caster
    local avatar = caster.avatar

    if avatar.spirit_count then
        avatar.spirit_count = avatar.spirit_count - 1
    end
end

-- Spawns a spirit near a corpse, consuming it in the process.
function SpiritOfVengeanceSpawn( event )
    local caster = event.caster
    local playerID = caster:GetPlayerOwnerID()
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local ability = event.ability
    local level = ability:GetLevel()
    local spirit_limit = ability:GetSpecialValueFor( "spirit_limit" )
    local duration = ability:GetSpecialValueFor( "spirit_limit" )

    -- Find a corpse nearby
    local corpse = Corpses:FindClosestInRadius(playerID, caster:GetAbsOrigin(), ability:GetCastRange())
    if corpse then
        -- If the caster has already hit the limit of spirits, kill the oldest, then continue
        if caster.spirit_count >= spirit_limit then
            for k,v in pairs(caster.spirits) do
                if IsValidEntity(v) and v:IsAlive() then 
                    v:ForceKill(false)
                    return
                end
            end
        end

        -- Create the spirit
        local spirit = CreateUnitByName("nightelf_spirit_of_vengeance", corpse:GetAbsOrigin(), true, hero, hero, hero:GetTeamNumber())
        spirit:AddNewModifier(caster, {}, "modifier_kill", {duration = 50})
        spirit.avatar = caster
        
        spirit:SetControllableByPlayer(playerID, true)
        spirit:SetNoCorpse()
        table.insert(caster.spirits, spirit)
        caster.spirit_count = caster.spirit_count + 1

        corpse:EmitSound("Hero_Spectre.DaggerCast")
        corpse:RemoveCorpse()
    end
end