-- Checks if the unit is standing on blight to apply/remove the regen
function BlightRegen( event )
	local target = event.target
	local position = target:GetAbsOrigin()
	if HasBlight(position) then
		if not target:HasModifier("modifier_blight_regen") then
			local ability = event.ability
			ability:ApplyDataDrivenModifier(target, target, "modifier_blight_regen", {})
		end
	else
		if target:HasModifier("modifier_blight_regen") then
			target:RemoveModifierByName("modifier_blight_regen")
		end
	end
end