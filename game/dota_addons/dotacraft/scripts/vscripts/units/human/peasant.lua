-- NOTE: There should be a separate Call To Arms ability on each peasant but it's
-- 		 currently not possible because there's not enough ability slots visible
CALL_THINK_INTERVAL = 0.1
function CallToArms( event )
	local caster = event.caster
	local hero = caster:GetOwner()
	local ability = event.ability
	local player = caster:GetPlayerOwner()

	local units = FindAlliesInRadius(caster, 3000) --Radius of the bell ring
	for _,unit in pairs(units) do
		if IsValidEntity(unit) and unit:GetUnitName() == "human_peasant" then

			local building_pos = caster:GetAbsOrigin()
			local collision_size = caster:GetHullRadius()*2 + 64
			unit.target_building = caster

			if unit.moving_timer then
				Timers:RemoveTimer(unit.moving_timer)
			end

			ability:ApplyDataDrivenModifier(unit, unit, "modifier_on_order_cancel_call_to_arms", {})

			-- Start moving towards the city center
			unit.moving_timer = Timers:CreateTimer(function()

				if not IsValidAlive(unit) then
					return
				elseif not IsValidAlive(unit.target_building) then
					unit.target_building = FindClosestResourceDeposit( unit, "gold" )
					return 1/30
				elseif unit:HasModifier("modifier_on_order_cancel_call_to_arms") then
					local distance = (building_pos - unit:GetAbsOrigin()):Length()
					local collision = distance <= collision_size
					
					if not collision then
						unit:MoveToPosition(building_pos)
						return CALL_THINK_INTERVAL
					else
						local militia = ReplaceUnit(unit, "human_militia")
						ability:ApplyDataDrivenModifier(militia, militia, "modifier_militia", {})

						-- Add the units to a table so they are easier to find later
						if not player.militia then
							player.militia = {}
						end
						table.insert(player.militia, militia)

						table.insert(player.units, militia)
					end
				end
			end)
		end
	end
end

function CancelCallToArms( event )
	local caster = event.caster --Peasant or militia
	local ability = event.ability

	if caster.moving_timer then
		Timers:RemoveTimer(caster.moving_timer)
	end
	caster.state = "idle"
end

function BackToWork( event )
	local unit = event.caster -- The militia unit
	local ability = event.ability
	local player = unit:GetPlayerOwner()

	local building = FindClosestResourceDeposit( unit, "gold" )
	local building_pos = building :GetAbsOrigin()
	local collision_size = building :GetHullRadius()*2 + 64
	unit.target_building = building

	if unit.moving_timer then
		Timers:RemoveTimer(unit.moving_timer)
	end

	-- Start moving towards the city center
	unit.moving_timer = Timers:CreateTimer(function()

		ability:ApplyDataDrivenModifier(unit, unit, "modifier_on_order_back_to_work", {})

		if not IsValidAlive(unit) then
			return
		elseif not IsValidAlive(unit.target_building) then
			unit.target_building = FindClosestResourceDeposit( unit, "gold" )
			return 1/30
		elseif unit:HasModifier("modifier_on_order_back_to_work") then
			local distance = (building_pos - unit:GetAbsOrigin()):Length()
			local collision = distance <= collision_size
			
			if not collision then
				unit:MoveToPosition(building_pos)
				return CALL_THINK_INTERVAL
			else
				local peasant = ReplaceUnit(unit, "human_peasant")
				CheckAbilityRequirements(peasant, player)
				table.insert(player.units, peasant)
			end
		end
	end)
end

function CallToArmsEnd( event )
	local target = event.target
	local player = target:GetPlayerOwner()
	local peasant = ReplaceUnit( event.target, "human_peasant" )
	CheckAbilityRequirements(peasant, player)
	table.insert(player.units, peasant)
end