AI_THINK_INTERVAL = 0.5
AI_STATE_IDLE = 0
AI_STATE_AGGRESSIVE = 1
AI_STATE_RETURNING = 2
AI_STATE_SLEEPING = 3

NeutralAI = {}
NeutralAI.__index = NeutralAI

function NeutralAI:Start( unit )
	--print("Starting NeutralAI for "..unit:GetUnitName().." "..unit:GetEntityIndex())

	local ai = {}
	setmetatable( ai, NeutralAI )

	ai.unit = unit --The unit this AI is controlling
	ai.stateThinks = { --Add thinking functions for each state
		[AI_STATE_IDLE] = 'IdleThink',
		[AI_STATE_AGGRESSIVE] = 'AggressiveThink',
		[AI_STATE_RETURNING] = 'ReturningThink',
		[AI_STATE_SLEEPING] = 'SleepThink'
	}

	unit.state = AI_STATE_IDLE
	unit.spawnPos = unit:GetAbsOrigin()
	unit.leashRange = unit.AcquisitionRange * 2

	--Start thinking
	Timers:CreateTimer(function()
		return ai:GlobalThink()
	end)

	return ai
end

function NeutralAI:GlobalThink()
	local unit = self.unit

	if not IsValidAlive(unit) then
		return nil
	end

	--Execute the think function that belongs to the current state
	Dynamic_Wrap(NeutralAI, self.stateThinks[ unit.state ])( self )

	return AI_THINK_INTERVAL
end

function NeutralAI:IdleThink()
	local unit = self.unit

	-- Sleep
	if not GameRules:IsDaytime() then
		--print("Applied Sleep to "..unit:GetUnitName().." "..unit:GetEntityIndex())
		ApplyModifier(unit, "modifier_neutral_sleep")

		unit.state = AI_STATE_SLEEPING
		return true
	end

	local target = FindAttackableEnemies( unit, false )

	--Start attacking as a group
	if target then
		local allies = FindAlliesInRadius( unit, unit.AcquisitionRange)
		--print(unit:GetUnitName()..	" "..unit:GetEntityIndex().." aggro triggered, found allies: ",#allies)
		for _,v in pairs(allies) do
			--print(v:GetUnitName()..	" "..v:GetEntityIndex().." "..v.state)
			if v.state == AI_STATE_IDLE then
				--print(v:GetUnitName()..	" "..v:GetEntityIndex().." now attacking -> ",target:GetUnitName(),"Team: ",target:GetTeamNumber())
		        v:MoveToTargetToAttack(target)
		        v.aggroTarget = target
				v.state = AI_STATE_AGGRESSIVE
			end
		end	
		return true
	end
end


function NeutralAI:SleepThink()
	local unit = self.unit

	-- Wake up
	if GameRules:IsDaytime() then
		unit:RemoveModifierByName("modifier_neutral_sleep")

		unit.state = AI_STATE_IDLE
		return true
	end
end

function NeutralAI:AggressiveThink()
	local unit = self.unit

	--print("AggressiveThink")

	--Check if the unit has walked outside its leash range
	if ( unit.spawnPos - unit:GetAbsOrigin() ):Length2D() >= unit.leashRange then
		unit:MoveToPosition( unit.spawnPos )
		unit.state = AI_STATE_RETURNING
		unit.aggroTarget = nil
		return true
	end
	
	local target = FindAttackableEnemies( unit, false )
	
	--Check if the unit's target is still alive
	if not IsValidAlive(unit.aggroTarget) then
		-- If there is no other valid target, return
		if not target then
			unit:MoveToPosition( unit.spawnPos )
			unit.state = AI_STATE_RETURNING
			unit.aggroTarget = nil	
		else
			--print("New target ", target:GetUnitName())
			unit:MoveToTargetToAttack(target)
        	unit.aggroTarget = target
		end
		return true
	
	-- If the current aggro target is still valid
	else
		if target then
			local range_to_current_target = unit:GetRangeToUnit(unit.aggroTarget)
			local range_to_closest_target = unit:GetRangeToUnit(target)

			-- If the range to the current target exceeds the attack range of the attacker, and there is a possible target closer to it, attack that one instead
			if range_to_current_target > unit:GetAttackRange() and range_to_current_target > range_to_closest_target then
				--print("New target ", target:GetUnitName())

	   			unit:MoveToTargetToAttack(target)
        		unit.aggroTarget = target
        	end
		else	
			-- Can't attack the current target and there aren't more targets close
			if not UnitCanAttackTarget(unit, unit.aggroTarget) or unit.aggroTarget:HasModifier("modifier_invisible") or unit:GetRangeToUnit(unit.aggroTarget) > unit.leashRange then
				unit:MoveToPosition( unit.spawnPos )
				unit.state = AI_STATE_RETURNING
				unit.aggroTarget = nil
			end
		end
	end
	return true
end

function NeutralAI:ReturningThink()
	local unit = self.unit

	--Check if the AI unit has reached its spawn location yet
	if ( unit.spawnPos - unit:GetAbsOrigin() ):Length2D() < 10 then
		--Go into the idle state
		--print("Returned")
		unit.state = AI_STATE_IDLE
		ApplyModifier(unit, "modifier_neutral_idle_aggro")
		return true
	end
end