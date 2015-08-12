AI_THINK_INTERVAL = 0.5
AI_STATE_IDLE = 0
AI_STATE_AGGRESSIVE = 1
AI_STATE_RETURNING = 2
AI_STATE_SLEEPING = 3

NeutralAI = {}
NeutralAI.__index = NeutralAI

function NeutralAI:Start( unit )
	print("Starting NeutralAI for "..unit:GetUnitName().." "..unit:GetEntityIndex())

	local ai = {}
	setmetatable( ai, NeutralAI )

	ai.unit = unit --The unit this AI is controlling
	ai.stateThinks = { --Add thinking functions for each state
		[AI_STATE_IDLE] = Dynamic_Wrap(NeutralAI, 'IdleThink'),
		[AI_STATE_AGGRESSIVE] = Dynamic_Wrap(NeutralAI, 'AggressiveThink'),
		[AI_STATE_RETURNING] = Dynamic_Wrap(NeutralAI, 'ReturningThink'),
		[AI_STATE_SLEEPING] = Dynamic_Wrap(NeutralAI, 'SleepThink')
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

	if not unit:IsAlive() then
		return nil
	end

	--Execute the think function that belongs to the current state
	self.stateThinks[ unit.state ]( self )

	return AI_THINK_INTERVAL
end

function NeutralAI:IdleThink()
	local unit = self.unit

	-- Sleep
	if not GameRules:IsDaytime() then
		print("Applied Sleep to "..unit:GetUnitName().." "..unit:GetEntityIndex())
		ApplyModifier(unit, "modifier_neutral_sleep")

		unit.state = AI_STATE_SLEEPING
		return true
	end

	local target = FindAttackableEnemies( unit, false )

	--Start attacking as a group
	if target then
		local allies = FindAlliesInRadius( unit, unit.AcquisitionRange)
		for _,v in pairs(allies) do
			if v.state == AI_STATE_IDLE then
				--print(unit:GetUnitName()," now attacking -> ",target:GetUnitName(),"Team: ",target:GetTeamNumber())
		        unit:MoveToTargetToAttack(target)
		        unit.aggroTarget = target
				unit.state = AI_STATE_AGGRESSIVE
			end
		end   
    else	
		return true
	end
end


function NeutralAI:SleepThink()
	local unit = self.unit

	-- Wake up
	if GameRules:IsDaytime() then
		--print("Removed Sleep from "..unit:GetUnitName().." "..unit:GetEntityIndex())
		unit:RemoveModifierByName("modifier_neutral_sleep")

		unit.state = AI_STATE_IDLE
		return true
	end
end

function NeutralAI:AggressiveThink()
	local unit = self.unit

	--print("AggressiveThink")

	--Check if the unit has walked outside its leash range
	if ( unit.spawnPos - unit:GetAbsOrigin() ):Length() > unit.leashRange then
		unit:MoveToPosition( unit.spawnPos )
		unit.state = AI_STATE_RETURNING
		--print("Returning")
		return true
	end
	
	local target = FindAttackableEnemies( unit, false )
	
	--Check if the unit's target is still alive, find new targets and return otherwise
	if not unit.aggroTarget or not unit.aggroTarget:IsAlive() then
		if target then
			--print("New target ", target:GetUnitName())
	        unit:MoveToTargetToAttack(target)
	        unit.aggroTarget = target
			unit.state = AI_STATE_AGGRESSIVE
		else
			unit:MoveToPosition( unit.spawnPos )
			unit.state = AI_STATE_RETURNING
			--print("Returning")
			return true
		end	
	end
	
	
end

function NeutralAI:ReturningThink()
	local unit = self.unit

	print("ReturningThink")

	--Check if the AI unit has reached its spawn location yet
	if ( unit.spawnPos - unit:GetAbsOrigin() ):Length() < 10 then
		--Go into the idle state
		unit.state = AI_STATE_IDLE
		return true
	end
end