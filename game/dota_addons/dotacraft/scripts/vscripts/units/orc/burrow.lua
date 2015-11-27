-- Right click with peon: Move towards the burrow to get inside

-- Call up to 4 peons, prioritize idle builders
function BattleStations( event )
	local caster = event.caster -- The Burrow
	local hero = caster:GetOwner()
	local ability = event.ability
	local player = caster:GetPlayerOwner()

	local units = FindAlliesInRadius(caster, 2000) --Radius of the call

	-- Choose peons
	if not caster.peons_inside then
        caster.peons_inside = {}
    end
	local maxPeons = 4 - #caster.peons_inside
	local peons = {}
	for _,unit in pairs(units) do
		if #peons < maxPeons then
			if IsValidEntity(unit) and unit:GetUnitName() == "orc_peon" and not unit:HasModifier("modifier_builder_burrowed") then
				if unit.state == "idle" then
					table.insert(peons, unit)
				end
			end
		end
	end

	-- If we couldn't find 4 idle peons in radius, get any
	if #peons < maxPeons then
		for _,unit in pairs(units) do
			if IsValidEntity(unit) and unit:GetUnitName() == "orc_peon" and not unit:HasModifier("modifier_builder_burrowed") and not tableContains(peons, unit) then
				table.insert(peons, unit)
			end
		end
	end

	-- For each of the peons selected, order them to move towards the burrow
	for _,unit in pairs(peons) do
		event.target = unit
		BurrowPeon(event)		
	end
end

function BurrowPeon( event )
	local caster = event.caster
	local unit = event.target
	caster:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)

	if unit:GetUnitName() ~= "orc_peon" then
		print("Not an Orc Peon")
		return
	end

	local ability = caster:FindAbilityByName("orc_battle_stations")
	local building_pos = caster:GetAbsOrigin()
	local collision_size = caster:GetHullRadius()*2 + 64

	-- Should keep track of what they were doing, to send them back to work
	-------

	unit.target_building = caster

	if unit.moving_timer then
		Timers:RemoveTimer(unit.moving_timer)
	end

	ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_STOP, Queue = false}) 
	unit:Interrupt()
	ability:ApplyDataDrivenModifier(unit, unit, "modifier_on_order_cancel_battle_stations", {})

	-- Start moving towards the building
	unit.moving_timer = Timers:CreateTimer(function()

		if not IsValidAlive(unit) or not IsValidAlive(unit.target_building) then
			return
		elseif unit:HasModifier("modifier_on_order_cancel_battle_stations") then
			local distance = (building_pos - unit:GetAbsOrigin()):Length()
			local collision = distance <= collision_size
			
			if not collision then
				unit:MoveToPosition(building_pos)
				return 0.1
			else
				-- Reached the burrow

				-- Add the units to the burrow's table
				if not caster.peons_inside then
					caster.peons_inside = {}
				end

				-- Check counter
				local counter = #caster.peons_inside
				print(counter, "Peons inside")
				if counter >= 4 then
					print(" Burrow full")
					return
				end

				-- Put builder inside
				unit:SetAbsOrigin(building_pos)
				unit:AddNoDraw()
				unit.state = "burrowed"
				unit:RemoveModifierByName("modifier_on_order_cancel_battle_stations")
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_builder_burrowed", {})
				table.insert(caster.peons_inside, unit)
				counter=counter+1

				-- Apply modifier on building for faster attack
				for i=1,4 do
					caster:RemoveModifierByName("modifier_battle_stations"..i)
				end
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_battle_stations"..counter, {})
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_battle_stations", {})
				caster:SetModifierStackCount("modifier_battle_stations", caster, counter)

				SetBurrowCounter( caster, counter )					
			end
		end
	end)
end

function SetBurrowCounter( burrow, count )

	if not burrow.counter_particle and count > 0 then
		local origin = burrow:GetAbsOrigin()
		burrow.counter_particle = ParticleManager:CreateParticleForPlayer("particles/custom/orc/burrow_counter.vpcf", PATTACH_CUSTOMORIGIN, burrow, burrow:GetPlayerOwner())
		ParticleManager:SetParticleControl(burrow.counter_particle, 0, Vector(origin.x,origin.y,origin.z+200))
	elseif burrow.counter_particle and count == 0 then
		ParticleManager:DestroyParticle(burrow.counter_particle, true)
		burrow.counter_particle = nil
		return
	end

	if not burrow.counter_particle then return end

	for i=1,count do
		--print("Set ",i," turned on")
		ParticleManager:SetParticleControl(burrow.counter_particle, i, Vector(1,0,0))
	end
	for i=count+1,5 do
		--print("Set ",i," turned off")
		ParticleManager:SetParticleControl(burrow.counter_particle, i, Vector(0,0,0))
	end
end

-- Another order was recieved
function CancelBattleStations( event )
	local peon = event.caster
	local ability = event.ability

	if peon.moving_timer then
		Timers:RemoveTimer(peon.moving_timer)
	end
	peon.state = "idle"
end

function StandDown( event )
	local caster = event.caster
	caster:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
	for i=1,4 do
		caster:RemoveModifierByName("modifier_battle_stations"..i)
		Timers:CreateTimer(0.5*i, function() 
			BackToWork(event)
		end)
	end
end

function BackToWork( event )
	local caster = event.caster
	local peons_inside = caster.peons_inside
	if not peons_inside then
		return
	elseif #peons_inside > 0 then

		print("Back to Work - "..#peons_inside.." builders inside")

		local first_peon = peons_inside[1]
		local ability = event.ability
		local player = first_peon:GetPlayerOwner()

		table.remove(caster.peons_inside, 1)
		local counter = #caster.peons_inside
		SetBurrowCounter(caster, counter)

		if counter > 0 then
			local ability = caster:FindAbilityByName("orc_battle_stations")
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_battle_stations"..counter, {})
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_battle_stations", {})
			caster:SetModifierStackCount("modifier_battle_stations", caster, counter)
		else
			for i=1,4 do
				caster:RemoveModifierByName("modifier_battle_stations"..i)
			end
			caster:RemoveModifierByName("modifier_battle_stations")
			caster:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
		end

		FindClearSpaceForUnit(first_peon, caster:GetAbsOrigin(), true)
		first_peon:RemoveNoDraw()
		first_peon:RemoveModifierByName("modifier_builder_burrowed")
		first_peon.state = "idle"

	end

end

function Eject( event )
	local caster = event.caster
	SetBurrowCounter(caster, 0)
	if not caster.peons_inside then return end
	for k,peon in pairs(caster.peons_inside) do
		FindClearSpaceForUnit(peon, caster:GetAbsOrigin(), true)
		peon:RemoveNoDraw()
		peon:RemoveModifierByName("modifier_builder_burrowed")
		peon.state = "idle"
	end
end