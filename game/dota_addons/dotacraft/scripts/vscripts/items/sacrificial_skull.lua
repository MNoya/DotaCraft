function MakeBlight( event )
	local ability = event.ability
	local point = event.target_points[1]

	BuildingHelper:SnapToGrid64(point.x)
	BuildingHelper:SnapToGrid64(point.y)

	print("MakeBlight at "..VectorString(point))

	-- Call the mechanic, radius is set to 384 internally because of 64x64 tiles
    local blight_skull = CreateUnitByName("undead_blight_skull", point, false, nil, nil, 0)
    blight_skull:AddNewModifier(blight_skull, nil, "modifier_building", {})
    blight_skull:AddNewModifier(blight_skull, nil, "modifier_out_of_world", {clientside = true})
	CreateBlight(blight_skull, "item")
end
