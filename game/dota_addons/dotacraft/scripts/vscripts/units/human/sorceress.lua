-- Handles AutoCast Logic
function SlowAutocast( event )
	local caster = event.caster
	local ability = event.ability
	local autocast_radius = ability:GetCastRange()
	local modifier_name = "modifier_human_slow"

	if caster.state == AI_STATE_IDLE or caster.state == AI_STATE_SLEEPING then return end

	-- Get if the ability is on autocast mode and cast the ability on a valid target
	if ability:GetAutoCastState() and ability:IsFullyCastable() and not caster:IsMoving() then
		-- Find enemy targets in radius
		local target
		local enemies = FindEnemiesInRadius(caster, autocast_radius)
		for k,unit in pairs(enemies) do
			if not IsCustomBuilding(unit) and not caster:HasModifier(modifier_name) then
				target = unit
				break
			end
		end

		if target then
			caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())
		end
	end	
end