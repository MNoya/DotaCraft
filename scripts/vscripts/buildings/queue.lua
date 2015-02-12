--[[
	Author: Noya
	Date: 12.02.2015.
	Creates an item on the buildings inventory to consume the queue.
]]
function EnqueueUnit( event )
	local caster = event.caster
	local ability = event.ability
	local player = caster:GetPlayerOwner():GetPlayerID()
	local gold_cost = ability:GetGoldCost( ability:GetLevel() - 1 )

	-- Initialize queue
	if not ability.queue then
		ability.queue = {}
	end

	-- Queue up to 5 units max
	if #ability.queue < 5 then

		local ability_name = ability:GetAbilityName()
		local item_name = "item_"..ability_name
		local item = CreateItem(item_name, caster, caster)
		caster:AddItem(item)

		-- RemakeQueue
		ability.queue = {}
		for itemSlot = 1, 5, 1 do
			local item = caster:GetItemInSlot( itemSlot )
			if item ~= nil then
				table.insert(ability.queue, item:GetEntityIndex())
			end
		end
	else
		-- Refund with message
 		PlayerResource:ModifyGold(player, gold_cost, false, 0)
		FireGameEvent( 'custom_error_show', { player_ID = player, _error = "Queue is full" } )		
	end
end

-- Destroys an item on the buildings inventory, refunding full cost of purchasing and reordering the queue
-- If its the first slot, the channeling ability is also set to not channel, refunding the full price.
function DequeueUnit( event )
	local caster = event.caster
	local item = event.ability
	local player = caster:GetPlayerOwner():GetPlayerID()

	local item_ability = EntIndexToHScript(item:GetEntityIndex())
	local item_ability_name = item_ability:GetAbilityName()

	-- Get tied ability
	local train_ability_name = string.gsub(item_ability_name, "item_", "")
	local train_ability = caster:FindAbilityByName(train_ability_name)
	local gold_cost = train_ability:GetGoldCost( train_ability:GetLevel() - 1 )

	print("Start dequeue")

	for itemSlot = 0, 5, 1 do
       	local item = caster:GetItemInSlot( itemSlot )
        if item ~= nil then
        	local current_item = EntIndexToHScript(item:GetEntityIndex())

        	if current_item == item_ability then
        		print("Q")
        		DeepPrintTable(train_ability.queue)
        		local queue_element = getIndex(train_ability.queue, item:GetEntityIndex())
        		print(item:GetEntityIndex().." in queue at "..queue_element)
	            table.remove(train_ability.queue, queue_element)

	            caster:RemoveItem(item)
	            
	            -- Refund ability cost
	            PlayerResource:ModifyGold(player, gold_cost, false, 0)
				print("Refund ",gold_cost)

				-- Set not channeling if the cancelled item was the first **current** slot
				if itemSlot == 1 then
					train_ability:SetChanneling(false)
					train_ability:EndChannel(true)
					print("Cancel current channel")
					ReorderItems(caster,train_ability.queue)
				else
					print("Removed unit in queue slot",itemSlot)					
				end
				break
			end
        end
    end
end

-- Auxiliar function, takes all items and puts them 1 slot back
function ReorderItems( caster, queue )
	queue = {}
	for itemSlot = 1, 5, 1 do
		local item = caster:GetItemInSlot( itemSlot )
       	if item ~= nil then
       		print("========>REMOVING",item:GetEntityIndex())   		
    		local new_item = CreateItem(item:GetName(), caster, caster)
       		caster:RemoveItem(item)
			table.insert(queue, new_item:GetEntityIndex())
			print("========>ADDED",new_item:GetEntityIndex())   		
       		caster:AddItem(new_item)
       	end
    end
end


-- Moves on to the next element of the queue
function NextQueue( event )
	local caster = event.caster
	local ability = event.ability
	ability:SetChanneling(false)
	--print("Move next!")

	-- Dequeue
	--DeepPrintTable(event)
	local hAbility = EntIndexToHScript(ability:GetEntityIndex())

	for itemSlot = 0, 5, 1 do
       	local item = caster:GetItemInSlot( itemSlot )
        if item ~= nil then
        	local item_name = tostring(item:GetAbilityName())

        	-- Remove the "item_" to compare
        	local train_ability_name = string.gsub(item_name, "item_", "")

        	if train_ability_name == hAbility:GetAbilityName() then

        		local train_ability = caster:FindAbilityByName(train_ability_name)

        		print("Q")
        		DeepPrintTable(train_ability.queue)
        		local queue_element = getIndex(train_ability.queue, item:GetEntityIndex())
        		if IsValidEntity(item) then
	        		print(item:GetEntityIndex().." in queue at "..queue_element)
		            table.remove(train_ability.queue, queue_element)
	            	caster:RemoveItem(item)
	            end

            	break
            elseif item then
        		--print(item_name,hAbility:GetAbilityName())
        	end
        end
    end
end

function AdvanceQueue( event )
	local caster = event.caster
	local ability = event.ability

	if not IsChanneling( caster ) then
		
		-- RemakeQueue
		ability.queue = {}

		-- Check the first item that contains "train" on the queue
		for itemSlot=1,5 do
			local item = caster:GetItemInSlot(itemSlot)
			if item ~= nil then

				table.insert(ability.queue, item:GetEntityIndex())

				local item_name = tostring(item:GetAbilityName())
				if not IsChanneling( caster ) and string.find(item_name, "train") then
					-- Find the name of the tied ability-item: 
					--	ability = human_train_footman
					-- 	item = item_human_train_footman
					local train_ability_name = string.gsub(item_name, "item_", "")

					local ability_to_channel = caster:FindAbilityByName(train_ability_name)

					ability_to_channel:SetChanneling(true)
					print(ability_to_channel:GetAbilityName()," started channel")

					-- After the channeling time, check if it was cancelled or spawn it
					-- EndChannel(false) runs whatever is in the OnChannelSucceded of the function
					Timers:CreateTimer(ability_to_channel:GetChannelTime(), 
					function()
						print("===Queue Table====")
						DeepPrintTable(ability_to_channel.queue)
						if IsValidEntity(item) then
							ability_to_channel:EndChannel(false)
							ReorderItems(caster, ability_to_channel.queue)
							print("Unit finished building")
						else
							print("This unit was interrupted")
						end
					end)
				end
			end
		end
	end
end

-- Auxiliar table function
function tableContains(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return true
        end
    end
    return false
end

function getIndex(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return i
        end
    end
    return -1
end

function getUnitIndex(list, unitName)
    --print("Given Table")
    --DeepPrintTable(list)
    if list == nil then return false end
    for k,v in pairs(list) do
        for key,value in pairs(list[k]) do
            print(key,value)
            if value == unitName then 
                return key
            end
        end        
    end
    return -1
end

-- Auxiliar function that goes through every ability and item, checking for any ability being channelled
function IsChanneling ( unit )
	
	for abilitySlot=0,15 do
		local ability = unit:GetAbilityByIndex(abilitySlot)
		if ability ~= nil and ability:IsChanneling() then 
			return true
		end
	end

	for itemSlot=0,5 do
		local item = unit:GetItemInSlot(itemSlot)
		if item ~= nil and item:IsChanneling() then
			return true
		end
	end

	return false
end