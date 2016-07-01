function VerifyUnitPossession ( keys )
	local MAX_LEVEL = keys.ability:GetSpecialValueFor("max_level")
	local PlayerID = keys.caster:GetPlayerOwnerID()
	local duration = keys.ability:GetSpecialValueFor("duration")
	
	if keys.target:GetLevel() > MAX_LEVEL then
		-- store mana	
		local mana = keys.caster:GetMana()
		
		-- interupt & send error
		keys.caster:Interrupt()			
		SendErrorMessage(PlayerID, "#error_cant_target_level6")
		
		-- set mana after a frame delay
		Timers:CreateTimer(function() keys.caster:SetMana(mana) return end)
	else
		keys.ability:ApplyDataDrivenModifier(keys.caster, keys.target, "modifier_possession_target", {duration=duration})
		keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_possession_caster", {duration=duration})
	end
end

function undead_possession( keys )
	local target = keys.target
	local caster = keys.caster
	local ability = keys.ability
	
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
			
			-- kill and set selection
			PlayerResource:AddToSelection(target:GetPlayerOwnerID(), target)
			caster:RemoveSelf()
			
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
	
	caster:Stop()
	caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
	
	if target:IsHero() or target:IsConsideredHero() then
	--	print(HERO_DURATION)
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_undead_curse", {duration=HERO_DURATION})
	else
	--	print(UNIT_DURATION)
		keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_undead_curse", {duration=UNIT_DURATION})
	end
end

function BansheeCurseAutoCast (keys)
	local caster = keys.caster
	local ability = keys.ability
	
	Timers:CreateTimer(function()	
		-- stop timer if the unit doesn't exist
		if not IsValidEntity(caster) then 
			--print("deleting banshee(timer)") 
			return 
		end
			
		if ability:GetAutoCastState() then
			BansheeCurseAuto_Cast(keys)
		end
		
		return 1
	end)
end

function BansheeCurseAuto_Cast(keys)
	local ability = keys.ability
	local caster = keys.caster
	local AUTOCAST_RANGE = ability:GetSpecialValueFor("cast_range")
	local MODIFIER_NAME = "modifier_undead_curse"
	
	local COOLDOWN = ability:GetCooldown(1)
	local MANA_COST = ability:GetManaCost(-1)
	
	local target = nil
	
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
		if not unit:HasModifier(MODIFIER_NAME) and not IsCustomBuilding(unit) and not unit:IsMechanical() then
			target = unit
			break
		end
	end
	
	if target ~= nil then
		caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())	
	end
end

-- Automatically toggled on
function ToggleOnAutocast( event )
	local caster = event.caster
	local ability = event.ability

	ability:ToggleAutoCast()
end

-- Puts a variable at 0 for the damage filter to take it
function ResetAntiMagicShell( event )
	local target = event.target
	target.anti_magic_shell_absorbed = 0
end
