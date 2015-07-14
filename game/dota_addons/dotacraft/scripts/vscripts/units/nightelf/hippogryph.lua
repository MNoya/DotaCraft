function PickUpArcher( event )
	local caster = event.caster
	local ability = event.ability
	local owner = caster:GetOwner()
	local radius = ability:GetCastRange()
	local origin = caster:GetAbsOrigin()

	-- Fake toggle the ability
	if ability:GetToggleState() == false then
		ability:ToggleAbility()
	end
	ability:EndCooldown()
	ability.cancelled = false

	local units
	local archer = ability.archer -- This can be assigned through the archer's mount hippogryph skill
	if not archer then
		units = FindUnitsInRadius(caster:GetTeamNumber(), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, 0, FIND_CLOSEST, false)
		for _,unit in pairs(units) do
			print(unit:GetUnitName())
			if unit:GetUnitName() == "nightelf_archer" and unit:GetOwner() == owner and not unit:HasModifier("modifier_mounted_archer") then
				archer = unit
				break
			end
		end
	end

	if archer then
		print("Pick Up Archer")
		Timers:CreateTimer(function() 
			-- Move towards the archer until 100 range
			if archer and IsValidEntity(archer) and not ability.cancelled then
				local archer_pos = archer:GetAbsOrigin()
				local distance = (archer_pos - caster:GetAbsOrigin()):Length()
				
				if distance > 100 then
					caster:MoveToPosition(archer_pos)
					print("Moving to NPC, distance ", distance)
					return 0.1
				else
					ability:StartCooldown(ability:GetCooldown(1))
					ability:ApplyDataDrivenModifier(caster, archer, "modifier_mounted_archer", {})

					local new_hippo = CreateUnitByName("nightelf_hippogryph_rider", caster:GetAbsOrigin(), false, caster:GetOwner(), caster:GetPlayerOwner(), caster:GetTeamNumber())
					new_hippo:SetControllableByPlayer(0, true)
					new_hippo:SetOwner(caster:GetOwner())
					new_hippo.archer = archer
					new_hippo:SetHealth(caster:GetHealth() + archer:GetHealth())

					local dismount_ability = new_hippo:FindAbilityByName("nightelf_dismount")
					if dismount_ability then
						dismount_ability:StartCooldown(dismount_ability:GetCooldown(1))
					end

					Timers:CreateTimer(0.3, function() 
						local attach = new_hippo:ScriptLookupAttachment("attach_hitloc") --Hippogryph mount
						local origin = new_hippo:GetAttachmentOrigin(attach)
						local fv = new_hippo:GetForwardVector()
						local pos = origin - fv * 18

						archer:SetAbsOrigin(Vector(pos.x, pos.y, origin.z-20))
						archer:SetParent(new_hippo, "attach_hitloc")
						archer:SetAngles(90,30,0)
					end)

					AddUnitToSelection(new_hippo)
					caster:RemoveSelf()
				end
			else
				if ability.cancelled then
					print("Pick Up cancelled")
				else
					print("Archer was killed mid-flight")
				end
				ability:EndCooldown()
				return
			end
		end)
	else
		if ability:GetToggleState() == true then
			ability:ToggleAbility()
		end
		ability:EndCooldown()
		print("No archer nearby")
	end
end

function CancelPickup( event )
	local ability = event.ability
	if ability:GetToggleState() == false then
		ability:ToggleAbility()
	end
	ability:EndCooldown()
	ability.cancelled = true
end

function FakeArcherAttack( event )
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	local archer = caster.archer

	if archer then
		archer:StartGesture(ACT_DOTA_ATTACK)
	end
end

-- Disengage the archer and make a nightelf_hippogryph with the current HP
function Dismount( event )
	print("Dismount")
	local caster = event.caster
	local archer = caster.archer

	local new_hippo = CreateUnitByName("nightelf_hippogryph", caster:GetAbsOrigin(), false, caster:GetOwner(), caster:GetPlayerOwner(), caster:GetTeamNumber())
	new_hippo:SetControllableByPlayer(0, true)
	new_hippo:SetOwner(caster:GetOwner())
	new_hippo.archer = nil
	new_hippo:SetHealth(caster:GetHealth())

	Timers:CreateTimer(0.2, function()
		if archer then
			local origin = archer:GetAbsOrigin()
			local ground = GetGroundHeight(origin, archer)
			print(origin.x, origin.y, ground)
			archer:RemoveModifierByName("modifier_mounted_archer")
			archer:SetAbsOrigin(Vector(origin.x, origin.y, ground))
			archer:SetParent(nil, "")

			local mount_ability = archer:FindAbilityByName("nightelf_mount_hippogryph")
			if mount_ability then
				mount_ability:StartCooldown(mount_ability:GetCooldown(1))
			end

			local pick_up_ability = new_hippo:FindAbilityByName("nightelf_pick_up_archer")
			if pick_up_ability then
				pick_up_ability:StartCooldown(pick_up_ability:GetCooldown(1))
				pick_up_ability.archer = nil
			end
		end
		AddUnitToSelection(new_hippo)
		AddUnitToSelection(archer)

		caster:RemoveSelf()
	end)
end

function CallHippogryph( event )
	print("CallHippogryph")
	local caster = event.caster
	local ability = event.ability
	local radius = ability:GetCastRange()
	local origin = caster:GetAbsOrigin()

	local units = FindUnitsInRadius(caster:GetTeamNumber(), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, 0, FIND_CLOSEST, false)
	local hippo = nil
	for _,unit in pairs(units) do
		if unit:GetUnitName() == "nightelf_hippogryph" and unit:FindAbilityByName("nightelf_pick_up_archer"):IsFullyCastable() then
			hippo = unit
			break
		end
	end

	if hippo then
		local ability = hippo:FindAbilityByName("nightelf_pick_up_archer")
		ability.archer = caster -- Tell the hippo to get THIS archer, not anyone
		ExecuteOrderFromTable({ UnitIndex = hippo:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET, AbilityIndex = ability:GetEntityIndex(), Queue = false}) 
	else
		print("No hippogryph nearby")
		ability:EndCooldown()
	end
end