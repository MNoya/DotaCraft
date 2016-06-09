--[[
	Author: Noya
	Date: 23.02.2015.
	Deals damage to a magic immune npc_dota_creature which is treated as a building.
]]
function DoBuildingDamage( event )
	local ability = event.ability
	local caster = event.caster
	local targets = event.target_entities
	local damage = event.Damage

	-- Magic Immune ignores ApplyDamage as PURE and MAGIC
	for _,target in pairs(targets) do

		-- Check if its indeed a building
		local isBuilding = target:FindAbilityByName("ability_building")
		if isBuilding then
			print("DoBuildingDamage on:",target:GetUnitName(),damage)
			DamageBuilding(target, damage, ability, caster)
		end
	end	
end