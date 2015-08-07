function GrowModel( event )
	local caster = event.caster
	local ability = event.ability

	Timers:CreateTimer(function() 
	    local model = caster:FirstMoveChild()
	    while model ~= nil do
	        if model:GetClassname() == "dota_item_wearable" then
	        	if not string.match(model:GetModelName(), "tree") then
	            	local new_model_name = string.gsub(model:GetModelName(),"1","4")
	            	model:SetModel(new_model_name)
	            else
	            	model:SetParent(caster, "attach_attack1")
	            	model:AddEffects(EF_NODRAW)
	            end
	        end
	        model = model:NextMovePeer()
	    end
	end)
end

function WarClub( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	caster:StartGesture(ACT_DOTA_ATTACK)
	Timers:CreateTimer(0.5, function()
		target:CutDown(caster:GetTeamNumber())
	end)

	Timers:CreateTimer(1, function()
		if IsValidEntity(caster.tree) then
			caster.tree:RemoveSelf()
		end
		local tree = Entities:CreateByClassname("prop_dynamic")
		caster.tree = tree
		tree:SetModel("models/heroes/tiny_01/tiny_01_tree.vmdl")
		tree:SetModelScale(caster:GetModelScale())

		local attach = caster:ScriptLookupAttachment("attach_attack2")
		local angles = caster:GetAttachmentAngles(caster:ScriptLookupAttachment("attach_attack1"))
		local origin = caster:GetAttachmentOrigin(attach)

		local fv = caster:GetForwardVector()
	    origin = origin - caster:GetForwardVector() * 75

		tree:SetAngles(angles.x, angles.y, angles.z)
		tree:SetAbsOrigin(Vector(origin.x, origin.y, origin.z-25))
		tree:SetParent(caster, "attach_attack2")

		caster:AddNewModifier(caster, nil, "modifier_animation_translate", {translate="tree"})
		caster:SetModifierStackCount("modifier_animation_translate", caster, 310)

		ability:ApplyDataDrivenModifier(caster, caster, "modifier_war_club", {})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_war_club_strikes", {})
		local strikes = ability:GetSpecialValueFor("strikes")
		caster:SetModifierStackCount("modifier_war_club_strikes", caster, strikes)

		SetAttackType(caster, "siege")
	end)
end

function WarClubStrike( event )
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	local damage = event.Damage
	local strikes = ability:GetSpecialValueFor("strikes")
	local stack_count = caster:GetModifierStackCount("modifier_war_club_strikes", caster)

	if IsCustomBuilding(target) then
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_grow_cleave.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
	end

	if stack_count > 1 then
		caster:SetModifierStackCount("modifier_war_club_strikes", caster, stack_count - 1)
	else
		caster:RemoveModifierByName("modifier_war_club")
		caster:RemoveModifierByName("modifier_war_club_strikes")
		caster:RemoveModifierByName("modifier_animation_translate")
		caster.tree:RemoveSelf()

		SetAttackType(caster, "normal")
	end	
end

function Taunt( event )
	local caster = event.caster
	local targets = event.target_entities
	caster:StartGesture(ACT_TINY_GROWL)

	for _,unit in pairs(targets) do
		unit:MoveToTargetToAttack(caster)
	end
end