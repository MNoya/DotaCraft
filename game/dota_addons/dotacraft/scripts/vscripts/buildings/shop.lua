function CheckHeroInRadius( event )
	local shop = event.caster
	local ability = event.ability
	local current_unit = shop.current_unit

	if IsValidAlive(current_unit) then
		-- Break out of range
		if shop:GetRangeToUnit(current_unit) > 900 then
			if shop.active_particle then
		        ParticleManager:DestroyParticle(shop.active_particle, true)
		    end
		    shop.current_unit = nil
		    Timers:RemoveTimer(shop.ghost_items)
		    ClearItems(shop)
		    return
		end

		-- If the current_unit is a creature and was autoassigned (not through rightclick), find heroes
		if current_unit:IsCreature() and not shop.targeted then
			local foundHero = FindShopAbleUnit(shop, DOTA_UNIT_TARGET_HERO)
			if foundHero then
				event.shop = shop:GetEntityIndex()
				event.unit = foundHero:GetEntityIndex()
				dotacraft:ShopActiveOrder(event)
			end
		end		
	else
		-- Find a nearby units in radius
		local foundUnit = FindShopAbleUnit(shop, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC)

		-- If a valid shop unit is found, update the current hero and set the replicated items
		if foundUnit then
			event.shop = shop:GetEntityIndex()
			event.unit = foundUnit:GetEntityIndex()
			dotacraft:ShopActiveOrder(event)
		end
	end
end

function FindShopAbleUnit( shop, unit_types )
	local units = FindUnitsInRadius(shop:GetTeamNumber(), shop:GetAbsOrigin(), nil, 900, DOTA_UNIT_TARGET_TEAM_FRIENDLY, unit_types, 0, FIND_CLOSEST, false)
	if units then
		-- Check for heroes
		for k,unit in pairs(units) do		
			if string.match(unit:GetClassname(),"npc_dota_hero") then
				return unit
			end
		end

		-- Check for creature units with inventory
		for k,unit in pairs(units) do
			if not IsCustomBuilding(unit) and unit:HasInventory() then
				return unit
			end
		end
	end
	return nil
end