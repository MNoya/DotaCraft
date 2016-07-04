--[[
	Author: Noya
	Deals damage to a magic immune npc_dota_creature which is treated as a building.
]]
function DoBuildingDamage( event )
	local ability = event.ability
	local caster = event.caster
	local targets = event.target_entities
	local damage = event.Damage

	-- Magic Immune ignores ApplyDamage as PURE and MAGIC
	for _,target in pairs(targets) do
		if IsCustomBuilding(target) then
			DamageBuilding(target, damage, ability, caster)
		end
	end	
end