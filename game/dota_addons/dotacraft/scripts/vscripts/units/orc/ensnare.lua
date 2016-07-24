function Ensnare( event )
    local target = event.target

    if target:HasFlyMovementCapability() then
        target:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
        target.WasFlying = true
    end
end

function EnsnareDestroy( event )
    local target = event.target

    if target.WasFlying then
        target.WasFlying = nil
        target:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
    end
end