function ExhumeCorpse(event)
    local graveyard = event.target
    if not graveyard.IsUnderConstruction then graveyard:RemoveModifierByName("modifier_graveyard_create_corpses") return end --exit out of dummy buildings
    if graveyard:IsUnderConstruction() then return end --dont create corpses while constructing

    local maxCorpses = 5
    if not graveyard.corpses then
        graveyard.corpses = {}
        graveyard.corpse_positions = GenerateNumPointsAround(maxCorpses, graveyard:GetAbsOrigin(), 200)
        for i=1,maxCorpses do
            graveyard.corpses[i] = false
        end
    end

    -- Validate corpses
    local count = 0
    for k,corpse in pairs(graveyard.corpses) do
        if corpse and IsValidEntity(corpse) and corpse:IsAlive() then --huehue
            count = count + 1
        else
            graveyard.corpses[k] = false
        end
    end

    if count < maxCorpses then
        for k,corpse in pairs(graveyard.corpses) do
            if not corpse then
                graveyard.corpses[k] = Corpses:CreateByNameOnPosition("undead_ghoul", graveyard.corpse_positions[k], graveyard:GetTeamNumber())
                break
            end
        end
    end
end