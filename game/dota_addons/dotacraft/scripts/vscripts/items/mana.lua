function GiveMana( event )
	local caster = event.caster
	local target = event.target
	if not target then target=caster end
	local mana_amount = event.mana_amount
	target:GiveMana(mana_amount)
	PopupMana(target,mana_amount)
end