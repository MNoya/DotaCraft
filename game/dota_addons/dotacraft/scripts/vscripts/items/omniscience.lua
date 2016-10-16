-- Reveals the entire map
function RevealMap( event )
    local caster = event.caster
    local ability = event.ability
    local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)
    local teamNumber = caster:GetTeamNumber()
    local dummy_table = {}
    
    for i=-4,4 do
        for j = -4,4 do
            AddFOWViewer(teamNumber,Vector(i*2000,j*2000,128),1800,duration,false)
        end
    end
end