-- Handles AutoCast Logic
function SlowAutocast( event )
	local caster = event.caster
	local ability = event.ability
	local autocast_radius = ability:GetSpecialValueFor("autocast_radius")
	local modifier_name = "modifier_human_slow"

	-- Get if the ability is on autocast mode and cast the ability on a valid target
	if ability:GetAutoCastState() and ability:IsFullyCastable() then
		-- Find enemy targets in radius
		local target
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, autocast_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
		for k,unit in pairs(enemies) do
			if not IsCustomBuilding(unit) and not caster:HasModifier(modifier_name) then
				target = unit
				break
			end
		end

		if not target then
			return
		else
			caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())
		end
	end	
end

-- Automatically toggled on
function ToggleOnAutocast( event )
	local caster = event.caster
	local ability = event.ability

	ability:ToggleAutoCast()
end