function DisableVision(event)
    local unit = event.target
    unit.originalDayVision = unit:GetDayTimeVisionRange()
    unit.originalNightVision = unit:GetDayTimeVisionRange()
    unit:SetDayTimeVisionRange(0)
    unit:SetNightTimeVisionRange(0)
end

function RecoverVision(event)
    local unit = event.target
    unit:SetDayTimeVisionRange(unit.originalDayVision)
    unit:SetNightTimeVisionRange(unit.originalNightVision)
end