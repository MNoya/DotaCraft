function GiveMana( event )
	local target = event.target
	local mana_amount = event.mana_amount
	target:GiveMana(mana_amount)
	PopupMana(target,mana_amount)
end