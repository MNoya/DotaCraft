function CreateBlight( event )
	local ability = event.ability
	local point = event.target_points[1]

	-- Call the mechanic, radius is set to 384 internally because of 64x64 tiles
	CreateBlight(point, "item")
end