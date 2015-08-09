function TranquilityStart( event )
	local caster = event.caster
	
	StartAnimation(caster, {duration=2, activity=ACT_DOTA_CAST_ABILITY_2, rate=0.8, translate="torment"})

end

function TranquilityThink( event )
	local caster = event.caster
	
	StartAnimation(caster, {duration=2, activity=ACT_DOTA_CAST_ABILITY_2, rate=0.8, translate="torment"})
end