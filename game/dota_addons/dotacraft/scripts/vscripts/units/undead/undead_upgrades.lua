-- Swaps wearables on Skeleton Warriors and Mages
function SkeletalLongevity( event )
	local caster = event.caster
	local unitName = caster:GetUnitName()

	if unitName == "undead_skeleton_warrior" then

		Timers:CreateTimer(0.5, function()
			local cape = Entities:CreateByClassname("prop_dynamic")
			caster.cape = cape
			cape:SetModel("models/items/wraith_king/regalia_of_the_bonelord_cape.vmdl")
			cape:SetModelScale(0.6)

			local attach = caster:ScriptLookupAttachment("attach_hitloc")
			local origin = caster:GetAttachmentOrigin(attach)
			local fv = caster:GetForwardVector()
			origin = origin + fv * 18

			cape:SetAbsOrigin(Vector(origin.x, origin.y, origin.z-70))
			cape:SetParent(caster, "attach_hitloc")

		end)

	elseif unitName == "undead_skeletal_mage" then
		SwapWearable(caster, "models/heroes/pugna/pugna_head.vmdl", "models/items/pugna/ashborn_horns/ashborn_horns.vmdl")
	end
end

function SwapWearable( unit, target_model, new_model )
	local wearable = unit:FirstMoveChild()
	while wearable ~= nil do
		if wearable:GetClassname() == "dota_item_wearable" then
			if wearable:GetModelName() == target_model then
				wearable:SetModel( new_model )
				return
			end
		end
		wearable = wearable:NextMovePeer()
	end
end