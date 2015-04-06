--[[
	Author: Noya
	Date: April 2, 2015
	Creates a dummy unit to apply the Cloud thinker modifier
]]
function CloudStart( event )
	-- Variables
	local caster = event.caster
	local point = event.target_points[1]

	caster.cloud_dummy = CreateUnitByName("dummy_unit_vulnerable", point, false, caster, caster, caster:GetTeam())
	event.ability:ApplyDataDrivenModifier(caster, caster.cloud_dummy, "modifier_cloud_thinker", nil)
end

function CloudEnd( event )
	local caster = event.caster

	caster.cloud_dummy:RemoveSelf()
end


-- Applies the cloud modifier only to ranged buildings (i.e. towers)
function ApplyCloud( event )
	local caster = event.caster
	local ability = event.ability
	local targets = event.target_entities
	local cloud_duration = ability:GetLevelSpecialValueFor("cloud_duration", ability:GetLevel() - 1 )

	for _,target in pairs(targets) do
		local isBuilding = target:FindAbilityByName("ability_building")
		if isBuilding and target:IsRangedAttacker() then
			target:ApplyDataDrivenModifier(caster, target, "modifier_cloud", { duration = cloud_duration })
		end
	end
end