function undead_possession( keys )
	local target = keys.target
	local caster = keys.caster

	Timers:CreateTimer(function()
	
	-- incase the unit has finished channelling but dies mid-possession(highly unlikely but possible)
		if not IsValidEntity(caster) then 
			return
		end
		
		local casterposition = caster:GetAbsOrigin()
		local targetposition = target:GetAbsOrigin()
		
		if (casterposition-targetposition):Length2D() < 10 then
			-- particle management
			ParticleManager:CreateParticle("particles/units/heroes/hero_death_prophet/death_prophet_excorcism_attack_impact_death.vpcf", 1, target)
			
			-- kill and set body underground
			caster:ForceKill(true)
			caster:SetAbsOrigin(Vector(0,0,-900))
			
			-- convert target unit information to match caster
			target:SetOwner(caster:GetOwner())
			target:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
			target:SetControllableByPlayer(target:GetPlayerOwnerID(), false)
			target:SetTeam(PlayerResource:GetTeam(caster:GetPlayerOwnerID()))
			
			--kill timer
			return nil
		else
			
			-- update position, Caster moves towards Target
			caster:SetAbsOrigin(caster:GetAbsOrigin() + (target:GetAbsOrigin() - caster:GetAbsOrigin()))	
		end

		return 0.2
	end)
	
end

function undead_curse ( keys )
	-- Caster & Target
	local target = keys.target
	local caster = keys.caster
	
	-- durations have be inverted due to some weird parsing bug
	local UNIT_DURATION = keys.ability:GetSpecialValueFor("unit_duration")
	local HERO_DURATION = keys.ability:GetSpecialValueFor("hero_duration")
	
	if target:IsHero() then
	--	print(HERO_DURATION)
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_undead_curse", {duration=HERO_DURATION})
	else
	--	print(UNIT_DURATION)
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_undead_curse", {duration=UNIT_DURATION})
	end
end

function BansheeCurseAutoCast (keys)
	local caster = keys.caster
	
	Timers:CreateTimer(function()
	
		-- stop timer if the unit doesn't exist
		if not IsValidEntity(caster) then 
			--print("deleting banshee(timer)") 
			return 
		end
			
		BansheeCurseAuto_Cast(keys)
		
		return 1
	end)
end

function BansheeCurseAuto_Cast(keys)
	local ability = keys.ability
	local caster = keys.caster
	local AUTOCAST_RANGE = keys.ability:GetSpecialValueFor("cast_range")
	local MODIFIER_NAME = "modifier_undead_curse"
	
	local target = nil
		
	-- if the ability is not toggled, don't proceed any further
	if not ability:GetAutoCastState() then
		--print("returning to timer, toggle is not enabled")
		return
	end
	
	-- find all units within 300 range that are enemey
	local units = FindUnitsInRadius(caster:GetTeamNumber(), 
								caster:GetAbsOrigin(), 
								nil, 
								AUTOCAST_RANGE, 
								DOTA_UNIT_TARGET_TEAM_ENEMY, 
								DOTA_UNIT_TARGET_ALL, 
								DOTA_UNIT_TARGET_FLAG_NONE, 
								FIND_CLOSEST, 
								false)
			
	for k,unit in pairs(units) do
		if not unit:HasModifier(MODIFIER_NAME) and not IsCustomBuilding(unit) then
			target = unit
			break
		end
	end

	if target ~= nil then
		--print("target found")
		caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())
	end
end

-- Automatically toggled on
function ToggleOnAutocast( event )
	local caster = event.caster
	local ability = event.ability

	ability:ToggleAutoCast()
end