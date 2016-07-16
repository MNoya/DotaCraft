-- Changes the color of the summoned unit
function RenderInferno(event)
    local infernal = event.target
    infernal:SetRenderColor(128, 255, 0)
    infernal:AddNewModifier(event.caster, event.ability, "modifier_summoned", {})
end