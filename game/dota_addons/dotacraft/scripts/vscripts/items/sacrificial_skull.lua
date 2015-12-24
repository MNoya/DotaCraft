function MakeBlight( event )
	local ability = event.ability
	local point = event.target_points[1]

	BuildingHelper:SnapToGrid64(point.x)
	BuildingHelper:SnapToGrid64(point.y)

	print("MakeBlight at "..VectorString(point))

	-- Call the mechanic, radius is set to 384 internally because of 64x64 tiles
	CreateBlight(point, "item")
end
