function TargetTest( event )
	local EventName = event.EventName
	local Damage = event.Damage

	local caster = event.caster
	local target = event.target
	local unit = event.unit
	local attacker = event.attacker
	local ability = event.ability

	local target_points = event.target_points
	local target_entities = event.target_entities

	print("**"..EventName.."**")
	print("~~~")
	if caster then print("CASTER: "..caster:GetUnitName()) end
	if target then print("TARGET: "..target:GetUnitName()) end
	if unit then print("UNIT: "..unit:GetUnitName()) end
	if attacker then print("ATTACKER: "..attacker:GetUnitName()) end
	if Damage then print("DAMAGE: "..Damage) end

	if target_points then
		for k,v in pairs(target_points) do
			print("POINT",k,v)
		end
	end

	-- Multiple Targets
	if target_entities then
		for k,v in pairs(target_entities) do
			print("TARGET "..k..": "..v:GetUnitName())
		end
	end

	--DeepPrintTable(event)
	print("~~~")
end