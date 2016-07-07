function RaiseDead( keys )
	local target = keys.target
	local caster = keys.caster
	local ability = keys.ability
	local playerID = caster:GetPlayerOwnerID()
	local radius = keys.ability:GetSpecialValueFor("radius")
	local duration = keys.ability:GetSpecialValueFor("duration")
	
	local corpse = Corpses:FindClosestInRadius(playerID, caster:GetAbsOrigin(), radius)	
	if corpse then					
		if not ability:IsItem() and Players:HasResearch( playerID, "undead_research_skeletal_longevity" ) then
			duration = duration + 15
		end
		caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
		CreateUnit(caster, corpse:GetAbsOrigin(), ability, duration)
		corpse:RemoveCorpse()
	end
end

function CreateUnit(caster, location, ability, duration)
	local playerID = caster:GetPlayerOwnerID()
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local forward = caster:GetForwardVector()
    local gridPoints = GetGridAroundPoint(2, location, forward)

	for i=1, 2 do
		local unitname = "undead_skeleton_warrior"
		if not ability:IsItem() and i == 1 and Players:HasResearch( playerID, "undead_research_skeletal_mastery" ) then
			unitname = "undead_skeletal_mage"
		end
	
		local unit = CreateUnitByName(unitname, gridPoints[i], true, hero,  hero, caster:GetTeamNumber())
		unit:SetControllableByPlayer(playerID, true)
		unit:AddNewModifier(unit, nil, "modifier_kill", {duration = duration})
		ParticleManager:CreateParticle("particles/neutral_fx/skeleton_spawn.vpcf", 0, unit)
		
		unit:SetIdleAcquire(false)
		Timers:CreateTimer(0.5, function() unit:SetIdleAcquire(true) end)

		Players:AddUnit(playerID, unit)

		-- Apply upgrades
		CheckAbilityRequirements(unit, playerID)
		ApplyMultiRankUpgrade(unit, "undead_research_unholy_strength", "weapon")
		ApplyMultiRankUpgrade(unit, "undead_research_unholy_armor", "armor")
	end
end

function RaiseDead_AutoCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local playerID = caster:GetPlayerOwnerID()
	
	Timers:CreateTimer(function()	
		if not IsValidEntity(caster) or not caster:IsAlive() then return end

		if ability:GetAutoCastState() and ability:IsCooldownReady() and Corpses:AreAnyInRadius(playerID, caster:GetAbsOrigin(), ability:GetCastRange()) then
			caster:CastAbilityNoTarget(ability,playerID)
		end
		return 1
	end)
	
end