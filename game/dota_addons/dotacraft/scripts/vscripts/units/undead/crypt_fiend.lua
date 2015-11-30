function BurrowVisual ( keys )
	local caster = keys.caster
	local duration = keys.ability:GetSpecialValueFor("duration") - 0.1

	-- end any animation
	EndAnimation(caster)
	
	if not caster:FindModifierByName("modifier_crypt_fiend_burrow") then -- if not burrowed, burrow
		StartAnimation(caster, {duration=duration, activity=ACT_DOTA_CAST_ABILITY_4, rate=0.6, translate="stalker_exo"})
		ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow.vpcf", 1, caster)
	end
end

function Burrow ( keys )
	local caster = keys.caster
	local ability = keys.ability

	-- toggle state(purely visual)
	ability:ToggleAbility()
	
	if not caster:FindModifierByName("modifier_crypt_fiend_burrow") then -- if not burrowed, burrow		
		caster:AddNewModifier(caster, nil, "modifier_crypt_fiend_burrow_model", {})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_crypt_fiend_burrow", nil)
		caster:NotifyWearablesOfModelChange(false)

	else -- if burrowed, revert
		caster:RemoveModifierByName("modifier_crypt_fiend_burrow_model")
		caster:RemoveModifierByName("modifier_crypt_fiend_burrow")
		caster:NotifyWearablesOfModelChange(true)
		
		ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_exit.vpcf", 1, caster)
		StartAnimation(caster, {duration=1, activity=ACT_DOTA_TELEPORT_END, rate=1})
	end

	caster:Stop()
end

-- on spell start call / autocast call
function Web(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local DURATION = ability:GetSpecialValueFor("duration")
	
	-- lose flying capabilities + start cooldown
	LoseFlying(keys)
	ability:StartCooldown(ability:GetCooldown(-1))
	-- apply modifier
	ability:ApplyDataDrivenModifier(caster, target, "modifier_web", {duration=DURATION})

	Timers:CreateTimer(function()
		-- stop timer if the unit doesn't exist
		if not IsValidEntity(target) then 
			--print("deleting banshee(timer)") 
			return 
		end	

		if not target:FindModifierByName("modifier_web") then
			ReGainFlying(keys)
			return
		end
		
		LoseHeight(keys)
		
		return 0.1
	end)
end

-- timer that's initialised on crypt fiend spawn
function Web_AutoCast(keys)
local caster = keys.caster
local ability = keys.ability

	Timers:CreateTimer(function()
		-- stop timer if the unit doesn't exist
		if not IsValidEntity(caster) then 
			return 
		end	
		
		if ability:GetCooldownTimeRemaining() == 0 and ability:GetAutoCastState() then
			-- find all units within 300 range that are enemey
			local units = FindUnitsInRadius(caster:GetTeamNumber(), 
										caster:GetAbsOrigin(), 
										nil, 
										400, 
										DOTA_UNIT_TARGET_TEAM_ENEMY, 
										DOTA_UNIT_TARGET_ALL, 
										DOTA_UNIT_TARGET_FLAG_NONE, 
										FIND_CLOSEST, 
										false)
					
			for k,unit in pairs(units) do
				if unit:HasFlyMovementCapability() then -- found unit to web
					keys.target = unit
					caster:CastAbilityOnTarget(keys.target, ability, caster:GetPlayerOwnerID())
					break
				end
			end
			
		end
		
		return 0.2
	end)
end

-- autocast ability call
function Web_Auto_Cast(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
	-- find all units within 300 range that are enemey
	local units = FindUnitsInRadius(caster:GetTeamNumber(), 
								caster:GetAbsOrigin(), 
								nil, 
								400, 
								DOTA_UNIT_TARGET_TEAM_ENEMY, 
								DOTA_UNIT_TARGET_ALL, 
								DOTA_UNIT_TARGET_FLAG_NONE, 
								FIND_CLOSEST, 
								false)
			
	for k,unit in pairs(units) do
		if unit:HasFlyMovementCapability() then -- found unit to web
			keys.target = unit
			Web(keys)
			return
		end
	end	
	
end

-- Prevents casting shackles on anything that doesnt fly
function WebCheck( event )
	local caster = event.caster
	local pID = caster:GetOwner():GetPlayerID()
	local target = event.target

	if not target:HasFlyMovementCapability() then
		caster:Interrupt()
		SendErrorMessage(pID, "#error_must_target_air")
	end
end

-- Loses flying capability
function LoseFlying( event )
	local target = event.target
	target:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
end

-- Moves down a bit
function LoseHeight( event )
	local target = event.target
	local origin = target:GetAbsOrigin()
	local groundPos = GetGroundPosition(origin, target)

	--print(origin.z, groundPos.z)
	if origin.z+128 > groundPos.z then
		target:SetAbsOrigin(Vector(origin.x, origin.y, origin.z - 2))
	end
end

-- Gains flying capability
function ReGainFlying( event )
	local target = event.target
	local origin = target:GetAbsOrigin()
	
	target:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
end

-- Automatically toggled on
function ToggleOnAutocast( event )
	local caster = event.caster
	local ability = event.ability

	ability:ToggleAutoCast()
end