function stone_form(keys)
local caster = keys.caster
local location = caster:GetAbsOrigin()
local ability = keys.ability
	
	-- toggle ability
	if not ability:GetToggleState() then
		ToggleOn(ability)
	else
		ToggleOff(ability)
	end
	
		--caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
		--caster:RemoveGesture(ACT_DOTA_CAST_ABILITY_1)
			
	-- apply/remove modifier and animation
	if not caster:FindModifierByName("modifier_stone_form") then
		LoseFlying(caster)
		LoseHeight(caster)
		
		StartAnimation(caster, {duration=30, activity=ACT_DOTA_CAST_ABILITY_1, rate=1})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_stone_form",  nil)
		
		-- set cooldown var to 30
		caster.cooldown = 30
		
		-- start timer
		Timers:CreateTimer(caster:GetEntityIndex().."_stone_form_cooldown",{
		callback = function()
		endtime = 1
		
			-- if he's flying this timer should not be active
			if caster:HasFlyMovementCapability() or caster.cooldown == 0 then
				return
			end
			
			caster.cooldown = caster.cooldown - 1
			
			return 1
		end})
	else -- give flying capabilities and remove modifier & animation
		ReGainFlying(caster)
		
		-- set cooldown
		ability:StartCooldown(caster.cooldown)
		
		EndAnimation(caster)
		caster:RemoveModifierByName("modifier_stone_form")
	end
end

-- Loses flying capability
function LoseFlying( caster )
	caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
end

-- Moves down a bit
function LoseHeight( caster )
	Timers:CreateTimer(function()
		
		local origin = caster:GetAbsOrigin()
		local groundPos = GetGroundPosition(origin, caster)
		--print(origin.z, groundPos.z)
		if origin.z+128 > groundPos.z then
			caster:SetAbsOrigin(Vector(origin.x, origin.y, origin.z - 12))
		end
		
		if origin.z+128 <= groundPos.z then
			return
		end
		
		return 0.05
	end)
end

-- Gains flying capability
function ReGainFlying( caster )
	caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
end