-- Gives vision over an area and shows dust particle to the team
function Flare(event)
	local caster = event.caster
	local ability = event.ability
	local level = ability:GetLevel()
	local reveal_radius = ability:GetLevelSpecialValueFor( "radius", level - 1 )
	local duration = ability:GetLevelSpecialValueFor( "duration", level - 1 )
	local target = event.target_points[1]

    local fxIndex = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_rattletrap/rattletrap_rocket_flare_illumination.vpcf",PATTACH_WORLDORIGIN,nil,caster:GetTeamNumber())
    ParticleManager:SetParticleControl(fxIndex, 0, target)
    ParticleManager:SetParticleControl(fxIndex, 1, Vector(5,0,0))

    AddFOWViewer(caster:GetTeamNumber(), target, reveal_radius, duration, false)

    local visiondummy = CreateUnitByName("dummy_unit", target, false, caster, caster, caster:GetTeamNumber())
    visiondummy:AddNewModifier(caster, ability, "modifier_true_sight_aura", {}) 
    Timers:CreateTimer(duration, function() UTIL_Remove(visiondummy) return end)
end

-- Deal extra damage to  Unarmored and Medium armor units in AoE
function FragmentationShard( event )
	local caster = event.caster
	local target = event.target
	local targets = event.target_entities
	local extra_damage = caster:GetAverageTrueAttackDamage() -- Double damage to unarmored/medium armored units

	for _,enemy in pairs(targets) do
		local armor_type = enemy:GetArmorType()
		if armor_type == "unarmored" or armor_type == "medium" then
			-- Do extra damage to this unit
			ApplyDamage({ victim = enemy, attacker = caster, damage = extra_damage, damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES})
			print("FragmentationShard dealt extra damage to "..unit_name)
		end
	end
end