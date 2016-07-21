function MakeBlight( event )
    local point = event.target_points[1]

    Blight:Create(point, "tiny")
end
