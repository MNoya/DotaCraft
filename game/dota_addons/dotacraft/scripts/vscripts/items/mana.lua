function GiveMana( event )
    local caster = event.caster
    local target = event.target
    if not target then target=caster end
    local mana_amount = event.mana_amount
    local mana = math.min(mana_amount, target:GetMaxMana() - target:GetMana())
    target:GiveMana(mana)
    if mana > 0 then
        PopupMana(target, mana)
    end
end