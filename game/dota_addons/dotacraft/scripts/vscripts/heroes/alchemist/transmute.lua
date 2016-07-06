-- Kills a unit and gives extra gold based on the gold cost of the unit
function Transmute( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local gold_bounty_multiplier = ability:GetLevelSpecialValueFor( "gold_bounty_multiplier" , ability:GetLevel() - 1  )

	if target:GetLevel() < 6 then
		-- Get how much 
		local gold_cost = target:GetKeyValue("GoldCost") or target:GetGoldBounty()
		local gold_gained = gold_cost * gold_bounty_multiplier

		-- Set the gold gained for killing the unit to the new multiplied number
		target:SetMinimumGoldBounty(gold_gained)
		target:SetMaximumGoldBounty(gold_gained)
		Corpses:SetNoCorpse(target)
		target:AddNoDraw()
		local particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf",PATTACH_CUSTOMORIGIN,nil)
		ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		target:Kill(nil, caster) --Kill the creep. This increments the caster's last hit counter.
	else
		caster:Interrupt()
		SendErrorMessage(pID, "#error_cant_target_level6")
	end

end