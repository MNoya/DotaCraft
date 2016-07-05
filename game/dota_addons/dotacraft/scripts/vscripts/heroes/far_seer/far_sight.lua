--[[
	Author: Noya
	Date: 17.01.2015.
	Gives vision over an area and shows a particle to the team
]]
function FarSight( event )
	local caster = event.caster
	local ability = event.ability
	local level = ability:GetLevel()
	local reveal_radius = ability:GetLevelSpecialValueFor( "radius", level - 1 )
	local duration = ability:GetLevelSpecialValueFor( "duration", level - 1 )

	local allHeroes = HeroList:GetAllHeroes()
	local particleName = "particles/items_fx/dust_of_appearance.vpcf"
	local target = event.target_points[1]
	-- Particle for team
	for _, v in pairs( allHeroes ) do
		if v:GetPlayerID() and v:GetTeam() == caster:GetTeam() then
			local fxIndex = ParticleManager:CreateParticleForPlayer( particleName, PATTACH_WORLDORIGIN, v, PlayerResource:GetPlayer( v:GetPlayerID() ) )
			ParticleManager:SetParticleControl( fxIndex, 0, target )
			ParticleManager:SetParticleControl( fxIndex, 1, Vector(reveal_radius,0,reveal_radius) )
		end
	end

	-- Vision
	--[[if level == 1 or level == 2 then
		ability:CreateVisibilityNode(target, reveal_radius, duration)
	elseif level == 3 then
		-- Central vision
		ability:CreateVisibilityNode(target, 1800, duration)

		-- We need to create many 1800 vision nodes to make a bigger circle
		local fv = caster:GetForwardVector()
    	local distance = 1800

    	-- Front and Back
    	local front_position = target + fv * distance
    	local back_position = target - fv * distance

		-- Left and Right
    	ang_left = QAngle(0, 90, 0)
    	ang_right = QAngle(1, -90, 0)
		
		local left_position = RotatePosition(target, ang_left, front_position)
    	local right_position = RotatePosition(target, ang_right, front_position)

    	-- Create the 4 auxiliar units
    	ability:CreateVisibilityNode(front_position, 1800, duration)
    	ability:CreateVisibilityNode(back_position, 1800, duration)
    	ability:CreateVisibilityNode(left_position, 1800, duration)
    	ability:CreateVisibilityNode(right_position, 1800, duration)
    end]]
    AddFOWViewer(caster:GetTeamNumber(), target, reveal_radius, duration, false)
    local visiondummy = CreateUnitByName("dummy_unit", target, false, caster, caster, caster:GetTeamNumber())
    visiondummy:AddNewModifier(caster, ability, "modifier_item_ward_true_sight", {true_sight_range = reveal_radius}) 
    Timers:CreateTimer(duration, function() visiondummy:RemoveSelf() return end)
end