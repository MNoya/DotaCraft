-- Read the wearables.kv, check the unit name, swap weapon to the next level
function UpgradeWeaponWearables(target, level)
	
	local wearable = target:FirstMoveChild()
	local unit_name = target:GetUnitName()
	print("UWW",unit_name)
	local wearables = GameRules.Wearables
	local unit_table = wearables[unit_name]
	local weapon_table = unit_table.weapon

	local original_weapon = weapon_table[tostring(0)]
	local old_weapon = weapon_table[tostring((level)-1)]
	local new_weapon = weapon_table[tostring(level)]

	print("UWW",old_weapon,new_weapon)
	
	while wearable ~= nil do
		if wearable:GetClassname() == "dota_item_wearable" then
			print("UWW",wearable:GetModelName())

			-- Unit just spawned, it has the default weapon
			if original_weapon == wearable:GetModelName() then
				wearable:SetModel( new_weapon )
				print("UWW", "\nSuccessfully swap " .. original_weapon .. " with " .. new_weapon )
				break

			-- In this case, the unit is already on the field and might have an upgrade
			elseif old_weapon and old_weapon == wearable:GetModelName() then
				wearable:SetModel( new_weapon )
				print("UWW", "\nSuccessfully swap " .. old_weapon .. " with " .. new_weapon )
				break
			end
		end
		wearable = wearable:NextMovePeer()
	end
end

-- Read the wearables.kv, check the unit name, swap all armors to the next level
function UpgradeArmorWearables(target, level)
	
	local wearable = target:FirstMoveChild()
	local unit_name = target:GetUnitName()
	print("UAW",unit_name)
	local wearables = GameRules.Wearables
	local unit_table = wearables[unit_name]
	local armor_table = unit_table.armor

	print("Armor Table")
	for _,armor in pairs(armor_table) do
		print(k)
		DeepPrintTable(armor)
	
		local original_armor = armor[tostring(0)]
		local old_armor = armor[tostring((level)-1)]
		local new_armor = armor[tostring(level)]
		
		while wearable ~= nil do
			if wearable:GetClassname() == "dota_item_wearable" then
				print("UAW",wearable:GetModelName())

				-- Unit just spawned, it has the default weapon
				if original_weapon == wearable:GetModelName() then
					wearable:SetModel( new_armor )
					print("UAW", "\nSuccessfully swap " .. original_weapon .. " with " .. new_armor )
					break

				-- In this case, the unit is already on the field and might have an upgrade
				elseif old_armor and old_armor == wearable:GetModelName() then
					wearable:SetModel( new_armor )
					print("UAW", "\nSuccessfully swap " .. old_armor .. " with " .. new_armor )
					break
				end
			end
			wearable = wearable:NextMovePeer()
		end
	end

end