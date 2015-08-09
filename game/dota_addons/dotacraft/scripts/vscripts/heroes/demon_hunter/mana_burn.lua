--[[
	Author: Noya
	Date: 14.1.2015.
	Burns mana and deals magic damage equal to the mana burned
]]
function ManaBurn( event )
	-- Variables
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local abilityDamageType = ability:GetAbilityDamageType()
	local mana_burn = ability:GetLevelSpecialValueFor("mana_burn", ability:GetLevel() - 1 )
	local damage_per_mana = ability:GetLevelSpecialValueFor("damage_per_mana", ability:GetLevel() - 1 )
	local targetMana = target:GetMana()

	-- Set the new target mana
	local newMana = targetMana - mana_burn
	target:SetMana( newMana )

	-- Check how much damage to do
	-- Discount mana burn over the minimum 0
	if newMana < 0 then
		mana_burn = mana_burn + newMana
	end

	-- Do the damage
	ApplyDamage({ victim = target, attacker = caster, damage = mana_burn, damage_type = abilityDamageType })

end

-- Checks if the target has a mana pool
function ManaBurnCheck( event )
	local caster = event.caster
	local target = event.target
	if target:GetMana() == 0 then
		SendErrorMessage(caster:GetPlayerOwnerID(), "#error_must_target_mana_unit")
		caster:Interrupt()
	end
end