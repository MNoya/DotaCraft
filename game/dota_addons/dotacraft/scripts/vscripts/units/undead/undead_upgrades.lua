-- ManaGain and HPGain values are defined in the npc_units_custom file
function ApplyUndeadTraining( event )
	local caster = event.caster
	local hero = caster:GetOwner()
	local player = hero:GetPlayerOwner()
	local levels = event.LevelUp - caster:GetLevel()

	local bonus_health = event.ability:GetSpecialValueFor("bonus_health")
	local bonus_mana = event.ability:GetSpecialValueFor("bonus_mana")

	caster:SetHealth(caster:GetHealth() + bonus_health)
	caster:CreatureLevelUp(levels)
	caster:SetMana(caster:GetMana() + bonus_mana)
end

-- This directly applies the current lvl 1/2/3, from the player upgrades table
function ApplyMultiRankUpgrade( event )
	local caster = event.caster
	local target = event.target
	local player = caster:GetPlayerOwner()
	local upgrades = player.upgrades
	local research_name = event.ResearchName
	local ability_name = string.gsub(research_name, "research_" , "")
	local cosmetic_type = event.WearableType
	local level = 0

	if player.upgrades[research_name.."3"] then
		level = 3		
	elseif player.upgrades[research_name.."2"] then
		level = 2		
	elseif player.upgrades[research_name.."1"] then
		level = 1
	end

	if level ~= 0 then
		target:AddAbility(ability_name..level)
		local ability = target:FindAbilityByName(ability_name..level)
		ability:SetLevel(level)

		if cosmetic_type == "weapon" then
			UpgradeWeaponWearables(target, level)
		elseif cosmetic_type == "armor" then
			UpgradeArmorWearables(target, level)
		end
	end
end

-- Swaps wearables on Skeleton Warriors and Mages
function SkeletalLongevity( event )
	local caster = event.caster
	local unitName = caster:GetUnitName()

	if unitName == "undead_skeleton_warrior" then

		Timers:CreateTimer(0.5, function()
			local cape = Entities:CreateByClassname("prop_dynamic")
			caster.cape = cape
			cape:SetModel("models/items/wraith_king/regalia_of_the_bonelord_cape.vmdl")
			cape:SetModelScale(0.6)

			local attach = caster:ScriptLookupAttachment("attach_hitloc")
			local origin = caster:GetAttachmentOrigin(attach)
			local fv = caster:GetForwardVector()
			origin = origin + fv * 18

			cape:SetAbsOrigin(Vector(origin.x, origin.y, origin.z-70))
			cape:SetParent(caster, "attach_hitloc")

		end)

	elseif unitName == "undead_skeletal_mage" then
		SwapWearable(caster, "models/heroes/pugna/pugna_head.vmdl", "models/items/pugna/ashborn_horns/ashborn_horns.vmdl")
	end
end

function SwapWearable( unit, target_model, new_model )
	local wearable = unit:FirstMoveChild()
	while wearable ~= nil do
		if wearable:GetClassname() == "dota_item_wearable" then
			if wearable:GetModelName() == target_model then
				wearable:SetModel( new_model )
				return
			end
		end
		wearable = wearable:NextMovePeer()
	end
end