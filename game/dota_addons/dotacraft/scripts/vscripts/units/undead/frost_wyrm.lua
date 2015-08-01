function freezing_attack (keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local RADIUS = 100
	local DURATION = ability:GetSpecialValueFor("duration")
	
	if IsCustomBuilding(target) then
		print("is building")
		if target and IsValidEntity(target) and not IsChanneling(target) and not target:HasModifier("modifier_construction") then
			print("has met all criteria")

			ability:ApplyDataDrivenModifier(caster, target, "modifier_frozen",  {duration=DURATION}) 
			
			-- find buildings
			local buildings = FindUnitsInRadius(caster:GetTeamNumber(), 
						target:GetAbsOrigin(), 
						nil, 
						RADIUS, 
						DOTA_UNIT_TARGET_TEAM_ENEMY, 
						DOTA_UNIT_TARGET_ALL, 
						DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 
						FIND_CLOSEST, 
						false)
			
			-- find buildings from list above, just to make sure that the magic immune enemy isn't a unit I check same conditions
			for k,building in pairs(buildings) do
				if IsCustomBuilding(building) then
					if IsValidEntity(building) and not IsChanneling(building) and not building:HasModifier("modifier_construction") then
						ability:ApplyDataDrivenModifier(caster, building, "modifier_frozen",  {duration=DURATION}) 
					end
				end
			end				

		end
	end
	
end

function freeze(keys)
	keys.caster.frozen = true
end

function unfreeze(keys)
	keys.caster.frozen = false
end