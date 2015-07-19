-- Handles AutoCast Logic
function HealAutocast( event )
	local caster = event.caster
	local ability = event.ability
	local autocast_radius = ability:GetSpecialValueFor("autocast_radius")

	-- Get if the ability is on autocast mode and cast the ability on a valid target
	if ability:GetAutoCastState() and ability:IsFullyCastable() then
		-- Find damaged targets in radius
		local target
		local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, autocast_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
		for k,unit in pairs(allies) do
			if not IsCustomBuilding(unit) and unit:GetHealthDeficit() > 0 then
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

function InnerFireAutocast( event )
	local caster = event.caster
	local ability = event.ability
	local autocast_radius = ability:GetSpecialValueFor("autocast_radius")
	local modifier_name = "modifier_inner_fire"
	
	-- Get if the ability is on autocast mode and cast the ability on a target that doesn't have the modifier
	if ability:GetAutoCastState() and ability:IsFullyCastable() then
		-- Find non buffed targets in radius *2
		local target
		local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, autocast_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
		for k,unit in pairs(allies) do
			if not IsCustomBuilding(unit) and not unit:HasModifier(modifier_name) then
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