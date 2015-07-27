-- This is for the active component
function ShadowMeld( event )
	local caster = event.caster
	local ability = event.ability
	local fade_time = ability:GetSpecialValueFor("fade_duration")

	print("Shadow Meld Active")

	if not GameRules:IsDaytime() then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_shadow_meld_fade", {duration = fade_time})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_shadow_meld_active", {})

		if ability:GetToggleState() == false then
			ability:ToggleAbility()
		end

		caster:Stop()
		caster:SetIdleAcquire(false) -- Do not autoattack if activated manually
	else
		print("Ability shouldn't be usable in daytime")
	end

end

-- This is for the passive component
function ShadowMeldThink( event )
	local caster = event.caster	
	local ability = event.ability
	local fade_time = ability:GetSpecialValueFor("fade_duration")

	-- Only available at night time
	if not GameRules:IsDaytime() then
		if ability:GetLevel() == 0 then
			ability:SetLevel(1)
		end

		-- If idle on night time, passively apply the fade out
		if caster:IsIdle() and not caster:GetAttackTarget() and not caster:HasModifier("modifier_shadow_meld_fade") and not caster:HasModifier("modifier_shadow_meld") and not caster:HasModifier("modifier_mounted_archer") then
			print("Applying Shadow Meld Passive")
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_shadow_meld_fade", {duration = fade_time})
			caster:SetIdleAcquire(true) -- Autoattack nearby enemies if passively activated
		end
	else
		-- Turn off in day time
		if ability:GetLevel() == 1 then
			ShadowMeldRemove(event)
			ability:SetLevel(0)
		end
	end
end

function ShadowMeldRemove( event )
	local caster = event.caster
	local ability = event.ability
	--caster.shadow_meld_removed = GameRules:GetGameTime()

	caster:RemoveModifierByName("modifier_shadow_meld_active")
	caster:RemoveModifierByName("modifier_shadow_meld_fade")
	caster:RemoveModifierByName("modifier_shadow_meld")
	caster:RemoveModifierByName("modifier_invisible")

	ToggleOff(ability)
end