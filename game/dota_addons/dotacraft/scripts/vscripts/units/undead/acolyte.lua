function unsummon (keys)
local caster = keys.caster
local target = keys.target
local playerID = caster:GetPlayerOwnerID()
local player = PlayerResource:GetPlayer(0)
local hero = player:GetAssignedHero()

	-- target is already unsummoning
	if target.unsummoning or not IsCustomBuilding(target) or caster:GetPlayerOwnerID() ~= target:GetPlayerOwnerID() or not target.constructionCompleted then
		SendErrorMessage(playerID, "#error_invalid_unsummon_target")
		return
	end

	-- set flag
	target.unsummoning = true
	
	-- damage taken by building per tick	
	local UNSUMMON_DAMAGE_PER_SECOND = keys.ability:GetSpecialValueFor("accumulation_step")
	
	-- 50% refund
	local goldcost = (0.5 * GetGoldCost(target))
	local lumbercost = (0.5 * GetLumberCost(target))
	
	-- calculate refund per tick
	local StepsNeededToUnsummon = target:GetHealth() / 50
	local LumberGain = (lumbercost / StepsNeededToUnsummon)
	local GoldGain = (goldcost / StepsNeededToUnsummon)
	
	Timers:CreateTimer(function()
		if not IsValidEntity(target) then 
			return 
		end
		
		ParticleManager:CreateParticle("particles/base_destruction_fx/gbm_lvl3_glow.vpcf", 0, target)
		
		if target:GetHealth() <= 50 then -- refund resource + kill unit
			GiveResources(GoldGain, LumberGain, hero)
			RemoveTarget(target)
		else -- refund resource + apply damage
			GiveResources(GoldGain, LumberGain, hero)
			target:SetHealth(target:GetHealth() - UNSUMMON_DAMAGE_PER_SECOND)
		end

		return 1
	end)

end

function RemoveTarget(target)
	target:ForceKill(true)
	target:RemoveBuilding()
	target:SetAbsOrigin(Vector(0,0,-9000))
end

function GiveResources(gold, lumber, hero)
	hero:ModifyGold(gold, true, 0)
	ModifyLumber(hero:GetPlayerOwner(), lumber)
end