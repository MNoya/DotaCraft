--[[
	Author: Noya
	Date: 08.02.2015.
	Keeps track of the last time the hawk moved
]]
function HawkMoved( event )
	local caster = event.caster

	caster.hawkMoved = GameRules:GetGameTime()
end

-- Keeps track of the last time the hawk attacked
function HawkAttacked( event )
	local caster = event.caster

	caster.hawkAttacked = GameRules:GetGameTime()
end


-- If the hawk hasn't moved or attacked in the last duration, apply invis
function HawkInvisCheck( event )
	local caster = event.caster
	local ability = event.ability
	local motionless_time = ability:GetLevelSpecialValueFor("motionless_time", ability:GetLevel() - 1)

	local current_time = GameRules:GetGameTime()

	if (current_time - caster.hawkAttacked) > motionless_time and (current_time - caster.hawkMoved) > motionless_time then

		ability:ApplyDataDrivenModifier(caster, caster, "modifier_hawk_invis", {})
		caster:AddNewModifier(caster, ability, "modifier_invisible", {}) 
	end
end

-- Initialize the attack and move trackers
function HawkCreated( event )
	local caster = event.caster
	
	caster.hawkMoved = GameRules:GetGameTime()
	caster.hawkAttacked = GameRules:GetGameTime()

end