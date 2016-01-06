-- Gives Health Percentage Increase to this building
function Masonry( event )
	local caster = event.caster
	local ability = event.ability
	local level = event.Level
	local healthBonusPercentage = event.ability:GetLevelSpecialValueFor("bonus_health_pct", level - 1) * 0.01
	local healthPercent = caster:GetHealth()/caster:GetMaxHealth()
	
	-- Adjust the relative HP for buildings that were already constructed
	if not caster:HasModifier("modifier_construction") then	
		-- Max Health
		local maxHP = GameRules.UnitKV[caster:GetUnitName()]['StatusHealth']
		local newMaxHP = maxHP * (1+healthBonusPercentage)
		caster:SetMaxHealth(newMaxHP)
	
		local newHP = math.ceil(newMaxHP * healthPercent)
		caster:SetHealth(newHP)
		print("Masonry HP of "..caster:GetUnitName()..": "..newHP.."/"..newMaxHP)	
	end

	-- Special case for the scout tower which gains 1 extra armor each level
	if caster:GetUnitName() == "human_scout_tower" then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_human_masonry_light_armor", {})
	end

	-- Set ability hidden
	ability:SetHidden(true)
end

-- Update all current peasants
function HarvestResearchFinished( event )
	local level = event.Level
	local caster = event.caster
	local playerID = caster:GetPlayerOwnerID()
	local playerUnits = Players:GetUnits(playerID)

	for k,v in pairs(playerUnits) do
		if IsValidAlive(v) and v:GetUnitName() == "human_peasant" then
			local ability = FindGatherAbility(v)
			ability:SetLevel(1+level)
		end
	end
end