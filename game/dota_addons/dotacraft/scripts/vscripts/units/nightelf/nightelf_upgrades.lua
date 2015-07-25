-- Swaps the Huntress' moon glaive ability to the upgraded version
function ApplyMoonGlaiveUpgrade( event )
	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades
	
	if player.upgrades["nightelf_research_upgraded_moon_glaive"] then
		target:RemoveModifierByName("modifier_luna_moon_glaive")
		target:AddAbility("nightelf_upgraded_moon_glaive")
		target:SwapAbilities("nightelf_upgraded_moon_glaive", "nightelf_moon_glaive", true, false)
		target:RemoveAbility("nightelf_moon_glaive")
		target:FindAbilityByName("nightelf_upgraded_moon_glaive"):SetLevel(1)
	end
end

-- Upgrade all Huntresses
function UpgradeMoonGlaives( event )
	local caster = event.caster
	local player = caster:GetPlayerOwner()
	local units = player.units

	for _,unit in pairs(units) do
		if IsValidEntity(unit) and unit:HasAbility("nightelf_moon_glaive") then
			unit:RemoveModifierByName("modifier_luna_moon_glaive")
			unit:AddAbility("nightelf_upgraded_moon_glaive")
			unit:SwapAbilities("nightelf_upgraded_moon_glaive", "nightelf_moon_glaive", true, false)
			unit:RemoveAbility("nightelf_moon_glaive")
			unit:FindAbilityByName("nightelf_upgraded_moon_glaive"):SetLevel(1)
		end
	end
end