-- When the unit tries to attack a flying unit, disable it
function CheckFlyingAttack( event )
	local target = event.target -- The target of the attack
	local attacker = event.attacker

	if target and target:GetName() ~= "" and target:HasFlyMovementCapability() then
		if not attacker:HasAbility("ability_attack_flying") then
			target:Stop() -- Interrupt the attack

			-- Send a move-to-target order.
			-- Could also be a move-aggresive/swap target so it still attacks other valid targets
			ExecuteOrderFromTable({ UnitIndex = attacker:GetEntityIndex(), 
									OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, 
									TargetIndex = target:GetEntityIndex(), 
									Position = target:GetAbsOrigin(), 
									Queue = false
								}) 
		end
	end
end

-- When the unit tries to attack a ground unit, disable it
function CheckGroundAttack( event )
	local target = event.target -- The target of the attack
	local attacker = event.attacker

	if target and target:IsCreature() and target:HasGroundMovementCapability() then
		target:Stop() -- Interrupt the attack

		-- Send a move-to-target order.
		ExecuteOrderFromTable({ UnitIndex = attacker:GetEntityIndex(), 
								OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET, 
								TargetIndex = target:GetEntityIndex(), 
								Position = target:GetAbsOrigin(), 
								Queue = false
							}) 
	end
end