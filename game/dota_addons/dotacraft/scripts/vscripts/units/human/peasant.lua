-- NOTE: There should be a separate Call To Arms ability on each peasant but it's
-- 		 currently not possible because there's not enough ability slots visible
CALL_THINK_INTERVAL = 0.1
function CallToArms( event )
	local caster = event.caster
	local hero = caster:GetOwner()
	local ability = event.ability
	local player = caster:GetPlayerOwner()
	local playerID = caster:GetPlayerOwnerID()

	local units = FindAlliesInRadius(caster, 3000) --Radius of the bell ring
	for _,unit in pairs(units) do
		if IsValidEntity(unit) and unit:GetUnitName() == "human_peasant" then

			ExecuteOrderFromTable({UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_STOP, Queue = false}) 

			local building_pos = caster:GetAbsOrigin()
			local collision_size = caster:GetHullRadius()*2 + 64
			unit.target_building = caster

			if unit.move_to_build_timer then Timers:RemoveTimer(unit.move_to_build_timer) end

			caster:SetNoCollision(true)

			-- Start moving towards the city center
			unit.move_to_build_timer = Timers:CreateTimer(function()

				if not IsValidAlive(unit) then return end
				if not IsValidAlive(unit.target_building) then
					unit.target_building = unit:FindClosestResourceDeposit(unit, "gold")
					return 1/30
				end

				local distance = (building_pos - unit:GetAbsOrigin()):Length()
				local collision = distance <= collision_size
				
				if not collision then
					unit:MoveToPosition(building_pos)
					return CALL_THINK_INTERVAL
				else
					local militia = ReplaceUnit(unit, "human_militia")
					ability:ApplyDataDrivenModifier(militia, militia, "modifier_militia", {})

					-- Add the units to a table so they are easier to find later
					if not hero.militia then
						hero.militia = {}
					end
					table.insert(hero.militia, militia)
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
	local playerID = unit:GetPlayerOwnerID()

	local building = unit:FindClosestResourceDeposit("gold")
	local building_pos = building:GetAbsOrigin()
	local collision_size = building:GetHullRadius()*2 + 64
	unit.target_building = building

	if unit.move_to_build_timer then Timers:RemoveTimer(unit.move_to_build_timer) end

	-- Start moving towards the city center
	unit.move_to_build_timer = Timers:CreateTimer(function()
		if not IsValidAlive(unit) then return end
		if not IsValidAlive(unit.target_building) then
			unit.target_building = unit:FindClosestResourceDeposit("gold")
			return 1/30
		end

		local distance = (building_pos - unit:GetAbsOrigin()):Length()
		local collision = distance <= collision_size
		
		if not collision then
			unit:MoveToPosition(building_pos)
			return CALL_THINK_INTERVAL
		else
			local peasant = ReplaceUnit(unit, "human_peasant")
			
			CheckAbilityRequirements(peasant, playerID)
		end
	end)
end

function CallToArmsEnd( event )
	local target = event.target
	local playerID = target:GetPlayerOwnerID()
	local peasant = ReplaceUnit( event.target, "human_peasant" )

	CheckAbilityRequirements(peasant, playerID)

	-- Gather ability level adjust
	local level = Players:GetCurrentResearchRank(playerID, "human_research_lumber_harvesting1")
	local ability = FindGatherAbility(peasant)
	ability:SetLevel(1+level)
end

function HideBackpack( event )
	Timers:CreateTimer(function()
		local peasant = event.caster
		local wearableName = "models/items/kunkka/claddish_back/claddish_back.vmdl"
		if not peasant.backpack then
			peasant.backpack = GetWearable(peasant, wearableName)
		end
		peasant.backpack:AddEffects(EF_NODRAW)
	end)
end

function ShowBackpack( event )
	local peasant = event.caster
	peasant.backpack:RemoveEffects(EF_NODRAW)
end