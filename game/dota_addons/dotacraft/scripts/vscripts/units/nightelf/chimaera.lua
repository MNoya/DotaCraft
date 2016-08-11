-- Adds a secondary attack to the chimaera
function UnlockCorrosiveBreath(event)
    local chimaera = event.caster
    chimaera:SetSecondaryAttackTable(event.SecondaryAttackTable)
end

-- Jakiro attack animation seems screwed for units, so another one it has to be faked on every attack
function ChimaeraAttack( event )
	local chimaera = event.caster
	local target = event.target

	chimaera:StartGesture(ACT_DOTA_CAST_ABILITY_2)
end