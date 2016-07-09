-- This will put a set of predefined undroppable items on the casters inventory
function GiveHumanBuildingItems( event )
	local caster = event.caster
	local owner = caster:GetOwner()

	-- Ordered by most used
	local itemNames = { "item_build_farm",
						"item_build_altar_of_kings",
						"item_build_town_hall",	
						"item_build_scout_tower",					
						"item_build_arcane_vault",						
						"item_build_lumber_mill"
					  }

	-- Add each item in order
	for i=1,#itemNames do
		local item = CreateItem(itemNames[i], owner, caster)
		caster:AddItem(item)
	end
end

function GiveOrcBuildingItems( event )
	local caster = event.caster
	local owner = caster:GetOwner()

	-- Ordered by most used
	local itemNames = { "item_build_burrow",
						"item_build_altar_of_storms",	
						"item_build_great_hall",
						"item_build_war_mill",					
						"item_build_voodoo_lounge"
					  }

	-- Add each item in order
	for i=1,#itemNames do
		local item = CreateItem(itemNames[i], owner, caster)
		caster:AddItem(item)
	end
end

function GiveNightElfBuildingItems( event )
	local caster = event.caster
	local owner = caster:GetOwner()

	local itemNames = { "item_build_moon_well",
						"item_build_altar_of_elders",
						"item_build_tree_of_life",	
						"item_build_ancient_of_war",
						"item_build_ancient_of_wonders",					
						"item_build_hunters_hall"
					  }

	-- Add each item in order
	for i=1,#itemNames do
		local item = CreateItem(itemNames[i], owner, caster)
		caster:AddItem(item)
	end
end

function GiveUndeadBuildingItems( event )
	local caster = event.caster
	local owner = caster:GetOwner()

	local itemNames = { "item_build_ziggurat",
						"item_build_altar_of_darkness",
						"item_build_necropolis",	
						"item_build_haunted_gold_mine",					
						"item_build_graveyard",						
						"item_build_tomb_of_relics"
					  }

	-- Add each item in order
	for i=1,#itemNames do
		local item = CreateItem(itemNames[i], owner, caster)
		caster:AddItem(item)
	end
end

function ApplyConstructionEffect( event )
	local ability = event.ability
	local target = event.target

	local race = GetUnitRace(target)

	if race == "orc" then
		target.construction_particle = ParticleManager:CreateParticle("particles/custom/construction_dust.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	elseif race ~= "human" then
		ability:ApplyDataDrivenModifier(target, target, "modifier_construction_"..race, {})
	end
end

function RemoveConstructionEffect( event )
	local target = event.target

	local race = GetUnitRace(target)
	target:RemoveModifierByName("modifier_construction_"..race)

	if target.construction_particle then 
		ParticleManager:DestroyParticle(target.construction_particle, true)
		target.construction_particle = nil
	end	
end

function NightElfConstructionParticle( event )
	local target = event.target
	target.construction_particle = ParticleManager:CreateParticle("particles/custom/nightelf/lucent_beam_impact_shared_ti_5.vpcf", PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControl(target.construction_particle, 0, target:GetAbsOrigin())
end

function NightElfConstructionParticleEnd( event )
	local target = event.target
	if target and target.construction_particle then
		ParticleManager:DestroyParticle(target.construction_particle, true)
	end
end