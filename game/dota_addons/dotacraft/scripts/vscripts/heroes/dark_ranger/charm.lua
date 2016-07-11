-- Takes control over a unit
function Charm( event )
    local caster = event.caster
    local target = event.target

    target:Stop()
    target:SetTeam(caster:GetTeamNumber())
    target:SetOwner(caster)
    target:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
    target:RespawnUnit()
    target:SetHealth(target:GetHealth())
end