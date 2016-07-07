-- Spawns a beetle near a corpse, consuming it in the process.
function CarrionBeetleSpawn( event )
    local caster = event.caster
    local playerID = caster:GetPlayerOwnerID()
    local ability = event.ability
    local level = ability:GetLevel()
    local beetle_limit = ability:GetLevelSpecialValueFor( "beetle_limit", ability:GetLevel() - 1 )

    -- Initialize the table of beetles
    if caster.beetles == nil then
        caster.beetles = {}
    end

    -- Find a corpse nearby
    local corpse = Corpses:FindClosestInRadius(playerID, caster:GetAbsOrigin(), ability:GetCastRange())
    if corpse then
        -- If the caster has already hit the limit of beetles, kill the oldest, then continue
        if #caster.beetles >= beetle_limit then
            print("Attempting to kill one beetle from "..#caster.beetles)
            for k,v in pairs(caster.beetles) do
                if v and IsValidEntity(v) and v:IsAlive() then
                    v:ForceKill(false)
                    break
                end
            end
        end

        -- Create the beetle
        local beetle = CreateUnitByName("undead_carrion_beetle_"..level, corpse:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
        beetle:SetControllableByPlayer(playerID, true)
        ability:ApplyDataDrivenModifier(caster, beetle, "modifier_carrion_beetle", nil)
        beetle:SetNoCorpse()
        table.insert(caster.beetles, beetle)
        print("Spawned beetle, Current table size: ".. #caster.beetles)
        corpse:RemoveCorpse()
    end
end

-- Remove the units from the table when they die to allow for new ones to spawn
function RemoveDeadBeetle( event )
    local caster = event.caster
    local unit = event.unit
    local targets = caster.beetles

    for k,beetle in pairs(targets) do       
        if beetle and IsValidEntity(beetle) and beetle == unit then
            table.remove(caster.beetles,k)
            print("Dead beetle, Current table size: ".. #caster.beetles)
        end
    end
end

-- Burrows Up or Down
function Burrow( event )
    local caster = event.caster
    local move = event.Move
    local caster_x = event.caster:GetAbsOrigin().x
    local caster_y = event.caster:GetAbsOrigin().y
    local caster_z = event.caster:GetAbsOrigin().z
    local position = Vector(caster_x, caster_y, caster_z)

    if move == "up" then
        position.z = position.z + 128
        caster:SetAbsOrigin(position)
        print(position)
    else
        position.z = position.z - 128
        caster:SetAbsOrigin(position)
        print(position)
    end
end