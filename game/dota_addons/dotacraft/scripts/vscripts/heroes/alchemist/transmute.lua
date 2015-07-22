--[[
	Author: Noya
	Date: 25.01.2015.
	Kills a unit and gives gold based on the 
	This should be the gold cost of the unit, it will just be the death gold bounty * a multiplier until the units are properly implemented.
]]
function Transmute( event )
	-- Variables
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local gold_bounty_multiplier = ability:GetLevelSpecialValueFor( "gold_bounty_multiplier" , ability:GetLevel() - 1  )

	if target:GetLevel() < 6 then
	-- Get how much 
		local gold_gained = target:GetGoldBounty() * gold_bounty_multiplier

		-- Set the gold gained for killing the unit to the new multiplied number
		target:SetMinimumGoldBounty(gold_gained)
		target:SetMaximumGoldBounty(gold_gained)
		target:Kill(ability, caster) --Kill the creep. This increments the caster's last hit counter.
	else
		caster:Interrupt()
		SendErrorMessage(pID, "#error_cant_target_level6")
	end

end