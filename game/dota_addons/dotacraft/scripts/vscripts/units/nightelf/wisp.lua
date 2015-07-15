function Gather( event )
	local wisp = event.caster
	local target = event.target
	local ability = event.ability
	local target_class = target:GetClassname()

	-- Fake toggle the ability, cancel if any other order is given
	if ability:GetToggleState() == false then
		ability:ToggleAbility()
	end
	ability:ApplyDataDrivenModifier(wisp, wisp, "modifier_on_order_cancel", {})

	-- Gather Lumber
	if target_class == "ent_dota_tree" then
		print(" Gather Lumber")
		local tree = target
		local position = tree:GetAbsOrigin()

		-- Only go to this tree if its empty or its been asigned through the orders
		if not tree.wisp or tree.wisp == wisp then
			local tree_pos = tree:GetAbsOrigin()
			wisp.target_tree = tree
			
			tree.wisp = wisp
			ability.cancelled = false

			Timers:CreateTimer(function() 
				-- Move towards the tree until 100 range
				if not ability.cancelled then
					local distance = (tree_pos - wisp:GetAbsOrigin()):Length()
					
					if distance > 120 then
						wisp:MoveToPosition(tree_pos)
						--print("Moving to Tree, distance ", distance)
						return 0.1
					else
						print("Tree Reached")
						tree_pos = wisp.target_tree:GetAbsOrigin()
						tree_pos.z = tree_pos.z - 28
						wisp:SetAbsOrigin(tree_pos)
						ability:ApplyDataDrivenModifier(wisp, wisp, "modifier_gathering_lumber", {})

						tree.wisp_gathering = true

						--[[wisp.tether = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_ABSORIGIN, wisp)
						ParticleManager:SetParticleControlEnt(wisp.tether, 0, wisp, PATTACH_POINT_FOLLOW, "attach_hitloc", wisp:GetAbsOrigin(), true)
						ParticleManager:SetParticleControl(wisp.tether, 1, wisp.target_tree:GetAbsOrigin())]]
						return
					end
				else
					return
				end
			end)
		else
			print(" The Tree already has a wisp in it, find another one!")
		end
	end
end

function CancelGather( event )
	local wisp = event.caster
	local ability = event.ability
	ability.cancelled = true
	
	if ability:GetToggleState() == true then
		ability:ToggleAbility()
	end

	if wisp.target_tree then
		wisp.target_tree.wisp = nil
		wisp.target_tree = nil
	end

	--[[if wisp.tether then
		ParticleManager:DestroyParticle(wisp.tether, false)
	end]]

	-- Give 1 extra second of fly movement
	wisp:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
	Timers:CreateTimer(2,function() 
		wisp:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
		wisp:AddNewModifier(caster, nil, "modifier_phased", {duration=0.03})
	end)
end

function LumberGain( event )
	local ability = event.ability
	local wisp = event.caster
	local lumber_gain = ability:GetSpecialValueFor("lumber_per_interval")
	ModifyLumber( wisp:GetPlayerOwner(), tonumber(lumber_gain) )
	PopupLumber( wisp, lumber_gain)
end