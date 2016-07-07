-- Kills a target, gives Health to the caster according to the sacrificed target current Health
function DeathPact( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local target_health = event.target:GetHealth()
	local rate = ability:GetLevelSpecialValueFor( "conversion_rate" , ability:GetLevel() - 1 ) * 0.01

	caster:Heal( target_health * rate, caster)
	target:SetNoCorpse()
	target:Kill(nil, caster)
end

-- Denies casting on full health, with a message
function DeathPactPrecast( event )
	local playerID = event.caster:GetPlayerOwnerID()
	if event.caster:GetHealthPercent() == 100 then
		event.caster:Interrupt()
		SendErrorMessage(playerID, "#error_full_health")
	end
end