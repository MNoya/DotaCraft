--[[
	Author: Noya
	Date: 17.01.2015.
	Gives vision over an area and shows a particle to the team
]]
function FarSight( event )
	local caster = event.caster
	local ability = event.ability
	local level = ability:GetLevel()
	local reveal_radius = ability:GetLevelSpecialValueFor( "reveal_radius", level - 1 )
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
	if level == 1 then
		local dummy = CreateUnitByName("dummy_600vision", target, false, caster, caster, caster:GetTeamNumber())
		Timers:CreateTimer(duration, function() dummy:RemoveSelf() end)

	elseif level == 2 then
		local dummy = CreateUnitByName("dummy_1800vision", target, false, caster, caster, caster:GetTeamNumber())
		Timers:CreateTimer(duration, function() dummy:RemoveSelf() end)

	elseif level == 3 then
		-- Central dummy
		local dummy = CreateUnitByName("dummy_1800vision", target, false, caster, caster, caster:GetTeamNumber())

		-- We need to create many 1800vision dummies to make a bigger circle
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
    	local dummy_front = CreateUnitByName("dummy_1800vision", front_position, false, caster, caster, caster:GetTeamNumber())
    	local dummy_back = CreateUnitByName("dummy_1800vision", back_position, false, caster, caster, caster:GetTeamNumber())
    	local dummy_left = CreateUnitByName("dummy_1800vision", left_position, false, caster, caster, caster:GetTeamNumber())
    	local dummy_right = CreateUnitByName("dummy_1800vision", right_position, false, caster, caster, caster:GetTeamNumber())

    	-- Destroy after the duration
    	Timers:CreateTimer(duration, function() 
    		dummy:RemoveSelf()
    		dummy_front:RemoveSelf() 
    		dummy_back:RemoveSelf() 
    		dummy_left:RemoveSelf() 
    		dummy_right:RemoveSelf()
    	end)
    end

end