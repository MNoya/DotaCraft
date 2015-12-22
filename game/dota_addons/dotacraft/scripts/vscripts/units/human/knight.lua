-- Legion Commander prop_dynamic attachment
function Mount( event )
	local caster = event.caster

	local prop = Attachments:AttachProp(caster, "attach_hitloc", "models/heroes/legion_commander/legion_commander.vmdl")
	DoEntFire( prop:GetName(), "SetAnimation", "legion_commander_idle", 0, nil, nil )

	caster.rider = prop
end

function FakeAttack( event )
	local caster = event.caster

	DoEntFire( caster.rider:GetName(), "SetAnimation", "legion_commander_attack", 0, nil, nil )
end