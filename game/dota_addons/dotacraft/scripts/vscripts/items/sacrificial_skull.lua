function MakeBlight( event )
    local point = event.target_points[1]

    event.caster:EmitSound("Hero_Undying.Decay.Cast")
    Blight:Create(point, "tiny")
end
