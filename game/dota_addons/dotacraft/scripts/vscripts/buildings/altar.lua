	-- The first Hero is free, only costs 5 supply and comes with a free Town Portal Scroll and a free skill point.
-- Additional Heroes require resources, and come with one skill point but do not have additional Town Portal Scrolls. 
-- To build a second Hero, you must upgrade your Town Hall to a Keep instead of a Town Hall. 
-- To build a third Hero you must have a third level Town Hall building such as a Castle.
-- You cannot train more than 3 Heroes, nor buy the same hero more than once
-- When a hero dies, the altar will gain the ability to respawn it for a cost

function BuildHero( event )
	local caster = event.caster
	local playerID = caster:GetPlayerOwnerID()
	local player = PlayerResource:GetPlayer(playerID)
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local unit_name = event.Hero
	local origin = caster.initial_spawn_position

	-- handle_UnitOwner needs to be nil, else it will crash the game.
	PrecacheUnitByNameAsync(unit_name, function()
		local new_hero = CreateUnitByName(unit_name, origin, true, hero, nil, hero:GetTeamNumber())
		new_hero:SetPlayerID(playerID)
		new_hero:SetControllableByPlayer(playerID, true)
		new_hero:SetOwner(player)
		new_hero:RespawnUnit()
		Timers:CreateTimer(0.05, function()
			new_hero:FindClearSpace(origin)
		end)

		CreateAttachmentsForPlayerHero(playerID, new_hero)
		
		-- Move to rally point
		dotacraft:ResolveRallyPointOrder(new_hero, caster)

		-- Add a teleport scroll
		local tpScroll = CreateItem("item_scroll_of_town_portal", new_hero, new_hero)
		new_hero:AddItem(tpScroll)
		tpScroll:SetPurchaseTime(0) --Dont refund fully

		-- Add the hero to the table of heroes acquired by the player
		Players:AddHero(playerID, new_hero)

		-- Swap the (hidden) finished hero ability for a passive version, to indicate it has been trained
		local ability = event.ability
		local ability_name = ability:GetAbilityName()
		
		-- Cut the rank, add the _acquired suffix
		local train_ability_name = string.sub(ability_name, 1, string.len(ability_name) - 1)
		new_hero.RespawnAbility = train_ability_name

		-- Swap and Disable on each altar
		local playerAltars = Players:GetAltars(playerID)
		for _,altar in pairs(playerAltars) do
			AddAcquiredAbilityToAltar(altar, ability_name)
		end

		FireGameEvent( 'ability_values_force_check', { player_ID = playerID })
		
		CreateHeroPanel(new_hero)
	end, playerID)
	
	-- register panaroma listener
	CustomGameEventManager:RegisterListener( "center_hero_camera", CenterCamera)
	CustomGameEventManager:RegisterListener( "revive_hero", Revive_Hero)
end

function AddAcquiredAbilityToAltar(altar, ability_name)
	local train_ability_name = string.sub(ability_name, 1, string.len(ability_name) - 1)
	local new_ability_name = train_ability_name.."_acquired"
	local new_ability = altar:AddAbility(new_ability_name)
	if new_ability then
		new_ability:SetLevel(new_ability:GetMaxLevel())
	end

	if altar:HasAbility(ability_name) then
		altar:SwapAbilities(ability_name, new_ability_name, false, true)
		altar:RemoveAbility(ability_name)
	end
	
	AdjustAbilityLayout(altar)
end

function CreateAttachmentsForPlayerHero(playerID, hero)
	local heroName = GetInternalHeroName(hero:GetUnitName())
	local sets = LoadKeyValues("scripts/kv/cosmetic_sets.kv")
	local steamID = tostring(PlayerResource:GetSteamAccountID(playerID))

	local hasSetForHero = sets[steamID] and sets[steamID][heroName]
	if hasSetForHero then
		local attachments = hasSetForHero.Attachments
		for attach_point,model_name in pairs(attachments) do
			Attachments:AttachProp(hero, attach_point, model_name)
		end
	end
end

-- Panorama action: Click on the Revive button
function Revive_Hero(unusedPlayerID, data)
	local heroname = data.heroname
	local playerID = data.PlayerID
	local hero_internal_name = GetInternalHeroName(heroname)
	local player = PlayerResource:GetPlayer(playerID)

	-- Find a valid ability to revive this hero on the altar
	local revive_ability
	local altar = Players:HasAltar(playerID)
	if altar then
		for i=0,15 do
			local ability = altar:GetAbilityByIndex(i)
			if ability then
				local ability_name = ability:GetAbilityName()
				ability_name = string.gsub(ability_name, "_revive" , "")
				ability_name = string.gsub(ability_name, "_train" , "")
				print(ability_name, hero_internal_name, "revive")
				if string.match(ability_name, hero_internal_name) and not ability:IsHidden() and ability:IsFullyCastable() then
					revive_ability = ability
					break
				end
			end
		end
		if revive_ability then
			altar:CastAbilityImmediately(revive_ability, player:GetPlayerID())
		else
			print("No valid ability to revive")
		end
	else	
		print("Not valid altar")
	end
end

-- Notify Panorama that the player acquired a new hero
function CreateHeroPanel(unit)
	local unitEntIndex = unit:GetEntityIndex()
	local unitName = unit:GetUnitName()
	local playerID = unit:GetPlayerOwnerID()
	local player = PlayerResource:GetPlayer(playerID)
	
	CustomGameEventManager:Send_ServerToPlayer(player, "create_hero", {entityIndex=unitEntIndex})
end

function UpgradeAltarAbilities( event )
	local altar = event.caster
	local abilityOnProgress = event.ability
	local playerID = altar:GetPlayerOwnerID()

	dotacraft:IncreaseAltarTier(playerID, abilityOnProgress)
end

function dotacraft:IncreaseAltarTier( playerID, abilityOnProgress )
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)

	-- Simple track of the current global rank
	local altar_level = hero.altar_level + 1
	hero.altar_level = altar_level

	if abilityOnProgress then
		table.insert(hero.altar_queue, abilityOnProgress:GetAbilityName())
	end

	if altar_level > 4 then
		print("ERROR: Altar should never go over level 4")
		hero.altar_level = 4
		return
	end

	print("ALTAR LEVEL "..altar_level.." QUEUE:")
	DeepPrintTable(hero.altar_queue)

	local playerAltars = Players:GetAltars(playerID)
	for _,altar in pairs(playerAltars) do
		UpdateAltar(altar, altar_level, abilityOnProgress)
	end
end

function UpdateAltar(altar, altar_level, abilityOnProgress)
	local playerID = altar:GetPlayerOwnerID()
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	for i=0,15 do
		local ability = altar:GetAbilityByIndex(i)
		if ability then
			local ability_name = ability:GetAbilityName()
			local level = ability:GetLevel() -- Disabled abilities are level 0
			if string.find(ability_name, "_train") and not string.find(ability_name,"_acquired") then
				if not abilityOnProgress or ability_name ~= abilityOnProgress:GetAbilityName() then	
					if altar_level == 4 or not Players:CanTrainMoreHeroes( playerID ) then -- Disable completely
						ability:SetHidden(true)
						--altar:RemoveAbility(ability_name)
					else	
						if string.find(ability_name, "_disabled") then
							ability_name = string.gsub(ability_name, "_disabled" , "")
						end

						local ability_len = string.len(ability_name)
						local rank = string.sub(ability_name, ability_len , ability_len)
						if rank ~= "0" then
							local new_ability_name = string.gsub(ability_name, rank , altar_level)
							if level == 0 then ability_name = ability_name.."_disabled" end
							print(ability_name, rank, "->", altar_level, "=",new_ability_name)

							-- If the ability has to be channeled (i.e. is queued), it cant be removed!
							if not tableContains(hero.altar_queue, ability_name) then
								altar:AddAbility(new_ability_name)
								altar:SwapAbilities(ability_name, new_ability_name, false, true)
								altar:RemoveAbility(ability_name)

								local new_ability = altar:FindAbilityByName(new_ability_name) 
								new_ability:SetLevel(new_ability:GetMaxLevel())
								print("Swapped "..ability_name.." with "..new_ability:GetAbilityName())
							else
								ability:SetHidden(true)
								print("Table Contains "..ability_name.." set Hidden because the altar will be casting it later")
							end
						end
					end
				else
					-- Things go wrong if the ability being channeled is removed so just set it hidden
					ability:SetHidden(true)
				end
			end
		end			
	end

	-- Look to disable the upgraded abilities if the requirements arent met
	CheckAbilityRequirements(altar, playerID)

	AdjustAbilityLayout(altar)

	local hero = altar:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	FireGameEvent( 'ability_values_force_check', { player_ID = playerID })

	PrintAbilities(altar)
end

function ReEnableAltarAbilities( event )
	local caster = event.caster
	local ability = event.ability
	local playerID = caster:GetPlayerOwnerID()
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)

	 -- Remove the "item_" to compare
	local item_name = ability:GetAbilityName()
    local train_ability_name = string.gsub(item_name, "item_", "")
	print("ABILITY NAME : "..train_ability_name)

	-- Remove it from the altar queue
	local queue_element = getIndex(hero.altar_queue, train_ability_name)
    table.remove(hero.altar_queue, queue_element)

	-- This is the level at which all train abilities should end up
	local altar_level = hero.altar_level - 1
	hero.altar_level = altar_level

	print("ALTAR LEVEL "..altar_level.." QUEUE:")
	DeepPrintTable(hero.altar_queue)

	print("--")

	-- On Each altar
	local playerAltars = Players:GetAltars(playerID)
	for _,altar in pairs(playerAltars) do
		for i=0,15 do
			local ability = altar:GetAbilityByIndex(i)
			if ability then
				local ability_name = ability:GetAbilityName()

				if string.find(ability_name, "_acquired") then
					--print(ability_name)

				-- Gotta adjust back the abilities
				-- The hidden train ability was one in the queue
				elseif string.find(ability_name, "_train") then
				 	if ability:IsHidden() then

				 		-- The level which abilities have to be downgraded and set visible depends on the current altar_level
				 		-- There's some critical issues with different cancelling of the queue that have to be considered

						if not tableContains(hero.altar_queue, ability_name) then

							-- Adjust the correct rank of this ability
							local ability_len = string.len(ability_name)
							local rank = tonumber(string.sub(ability_name, ability_len, ability_len))
							local adjusted_ability_name = string.gsub(ability_name, rank , tostring(altar_level))
							print(rank,ability_name,altar_level,adjusted_ability_name)

							local correct_ability = altar:FindAbilityByName(adjusted_ability_name)
							if correct_ability then
								correct_ability:SetHidden(false)
								print(adjusted_ability_name.." is now visible")
							else
								-- The ability has to be set to a new level that didn't exist originally
								print("Adding new adjusted ability "..adjusted_ability_name)
								altar:AddAbility(adjusted_ability_name)
								altar:SwapAbilities(ability_name, adjusted_ability_name, false, true)
								altar:RemoveAbility(ability_name)

								local new_adjusted_ability = altar:FindAbilityByName(adjusted_ability_name)
								new_adjusted_ability:SetLevel(new_adjusted_ability:GetMaxLevel())

							end
						else
							ability:SetHidden(true)
							print("Table Contains "..ability_name.." - Keep it hidden, its queued")
						end
					else
						-- If the ability is disabled, need to adjust
						if string.find(ability_name, "_disabled")  then
							ability_name = string.gsub(ability_name, "_disabled" , "")
							print("Adjusted ability name")
						end

						local ability_len = string.len(ability_name)
						local rank = string.sub(ability_name, ability_len , ability_len)
						print(ability_name,rank)
						if rank ~= "1" then

							local downgraded_ability_name = string.gsub(ability_name, rank , tostring( tonumber(rank) - 1))
							print("downgraded_ability_name: ", downgraded_ability_name)

							altar:AddAbility(downgraded_ability_name)
							altar:SwapAbilities(ability_name, downgraded_ability_name, false, true)
							altar:RemoveAbility(ability_name)
							altar:RemoveAbility(ability_name.."_disabled")

							local new_ability = altar:FindAbilityByName(downgraded_ability_name) 
							new_ability:SetLevel(new_ability:GetMaxLevel())
							print("Swapped "..ability_name.." with "..new_ability:GetAbilityName())
							print("--")
						else
							print("RANK 0 WAOW")
							print('--')
						end
					end
				end
			end
		end

		-- Look to disable the downgraded abilities if the requirements arent met
		CheckAbilityRequirements( structure, playerID )

		-- Keep order
		ReorderAbilities(altar)

		PrintAbilities(altar)
		AdjustAbilityLayout(altar)
	end

end

-- Check the unit definition and try to keep the predefined index order of abilities
function ReorderAbilities( unit )
	local unit_table = GameRules.UnitKV[unit:GetUnitName()]
	for i=1,4 do
		local ability_string = unit_table["Ability"..i]
		local ability_in_slot = GetAbilityOnVisibleSlot(unit, i)
		local ability_name = Upgrades:GetBaseAbilityName(ability_string)
		local ability = FindAbilityWithName(unit, ability_name) -- Get an ability with a similar name
		if ability then
			unit:SwapAbilities(ability:GetAbilityName(), ability_in_slot:GetAbilityName(), true, true)
		end
	end
end

-- Keep a direct reference after the player builds its first Altar
-- Clone the abilities of this building if possible, if its killed try to find another in the structures list
-- If no altar can be found, check the player heroes table and decide which rank to apply
-- This can also include setting re-train abilities (because the heroes are dead) or passive version if the hero is still alive
function LinkAltar( event )
	local altar = event.caster
	local playerID = altar:GetPlayerOwnerID()
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local altarName = altar:GetUnitName()

	-- If no altar is active, this will be the reference
	local hasAltar = Players:HasAltar(playerID)
	if not hasAltar then
		hero.altar = altar
		print("Initialized altar for player "..playerID)
	end

	-- Keep all altars in a separate structure list
	table.insert(hero.altar_structures, altar)

	local cloneAltar
	if altar ~= hero.altar and IsValidAlive(hero.altar) then
		if altarName == hero.altar:GetUnitName() then
			cloneAltar = hero.altar
		else
			-- Handles the rare case where the player owns more than one altar type
			for _,a in pairs(hero.altar_structures) do
				if IsValidAlive(a) and a ~= altar and a:GetUnitName() == altarName then
					cloneAltar = a
					break
				end
			end
		end
		
		if cloneAltar then
			print("Linking "..altarName.." "..altar:GetEntityIndex().." to "..cloneAltar:GetUnitName().." "..cloneAltar:GetEntityIndex())
			CloneAltarAbilities(altar, cloneAltar)
		else
			-- Adjust the altar to a new race, it needs to have the acquired hero abilities and upgrade its tiers
			local acquired_list = {}
			for _,ability_name in pairs(hero.altar_queue) do
				local name = string.sub(ability_name, 1, string.len(ability_name) - 1)
				if not altar:HasAbility(name.."_acquired") then
					AddAcquiredAbilityToAltar(altar, ability_name)
				end
			end	

			UpdateAltar(altar, hero.altar_level, abilityOnProgress)	
		end
	end

	AdjustAbilityLayout(altar)
end

-- Copies the abilities on the main altar to the newly built altar
function CloneAltarAbilities( unit, source )

	-- First remove the train abilities on the unit
	for i=0,15 do
		local unit_ability = unit:GetAbilityByIndex(i)

		if unit_ability then
			local ability_name = unit_ability:GetAbilityName()
			if string.find(ability_name, "_train") then
				unit:RemoveAbility(ability_name)
			end
		end
	end

	-- Then copy over the abilities of the source
	for i=0,15 do
		local source_ability = source:GetAbilityByIndex(i)

		if source_ability then
			local ability_name = source_ability:GetAbilityName()
			if string.find(ability_name, "_train") or string.find(ability_name, "_acquired") or string.find(ability_name, "_revive") then
				unit:AddAbility(ability_name)
				print('added '..ability_name)
				local ability = unit:FindAbilityByName(ability_name)
				if ability then 
					if source_ability:IsHidden() then
						ability:SetHidden(true)
					end
					ability:SetLevel(ability:GetMaxLevel())
				else
					print("Failed to add "..ability_name)
				end
			end
		end
	end
end

-- Hero Revival
-- The cost to revive a Hero will be ~half the cost for building the Hero plus 10% more per level of Hero to be revived.
-- Hero revive time is capped at 100 seconds.
function ReviveHero( event )
	local caster = event.caster -- An Altar
	local playerID = caster:GetPlayerOwnerID()
	local hero_name = event.Hero
	local playerHeroes = Players:GetHeroes(playerID)

	for k,hero in pairs(playerHeroes) do
		if hero:GetUnitName() == hero_name then
			hero:RespawnUnit()
			Timers:CreateTimer(0.05, function()
				hero:FindClearSpace(caster.initial_spawn_position)
			end)
			dotacraft:ResolveRallyPointOrder(hero, caster)
			print("Revived "..hero_name)
		end
	end

	-- Swap to the passive hero_acquired ability
	local ability = event.ability
	local ability_name = ability:GetAbilityName()

	print("SWAPPING "..ability_name.." with the ACQUIRED version on EVERY ALTAR")

	local playerAltars = Players:GetAltars(playerID)
	for _,altar in pairs(playerAltars) do
		local new_ability_name = string.gsub(ability_name, "_revive" , "")
		new_ability_name = Upgrades:GetBaseAbilityName(new_ability_name) --Take away numbers or research
		new_ability_name = new_ability_name.."_acquired"

		print("new_ability_name is "..new_ability_name.." finding it")

		altar:AddAbility(new_ability_name)
		altar:SwapAbilities(ability_name, new_ability_name, false, true)
		altar:RemoveAbility(ability_name)
		
		print(" FOUND REVIVE Swapped "..ability_name.." with "..new_ability_name)

		local new_ability = altar:FindAbilityByName(new_ability_name)
		new_ability:SetLevel(new_ability:GetMaxLevel())

		AdjustAbilityLayout(altar)
	end
	
	-- remove hero panel when revived
	unit_shops:RemoveHeroPanel(GameRules.HeroTavernEntityID, caster:GetPlayerOwnerID(), hero_name)
	
	FireGameEvent( 'ability_values_force_check', { player_ID = playerID })
end

-- Hide the revive ability on every altar
function HideReviveAbility( event )
	local caster = event.caster
	local ability = event.ability
	local playerID = caster:GetPlayerOwnerID()

	local ability_name = ability:GetAbilityName()

	print("HIDING "..ability_name.." on EVERY ALTAR")

	local playerAltars = Players:GetAltars(playerID)
	for _,altar in pairs(playerAltars) do
		local revive_ability = altar:FindAbilityByName(ability_name)
		if revive_ability then
			print("Hiding "..revive_ability:GetAbilityName())
			revive_ability:SetHidden(true)
		end
	end

	FireGameEvent( 'ability_values_force_check', { player_ID = playerID })
end

-- Show the revive ability on every altar after cancelling a revive
function ShowReviveAbility( event )
	local caster = event.caster
	local ability = event.ability
	local playerID = caster:GetPlayerOwnerID()
	local item_name = ability:GetAbilityName()

	local ability_name = string.gsub(item_name, "item_", "")
	local ability = caster:FindAbilityByName(ability_name)

	print("SHOWING "..ability_name.." on EVERY ALTAR")

	local playerAltars = Players:GetAltars(playerID)
	for _,altar in pairs(playerAltars) do
		local acquired_ability = altar:FindAbilityByName(ability_name)
		if acquired_ability then
			print("Showing "..acquired_ability:GetAbilityName())
			acquired_ability:SetHidden(false)
		end
	end

	FireGameEvent( 'ability_values_force_check', { player_ID = playerID })
end