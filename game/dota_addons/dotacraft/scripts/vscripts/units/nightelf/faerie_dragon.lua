-- Get if the ability is on autocast mode and cast it
function PhaseShiftAutocast( event )
	local caster = event.caster
	local ability = event.ability
	
	if ability:GetAutoCastState() and ability:IsFullyCastable() then
		
		local damage = event.Damage
		caster:Heal(damage, caster)

		caster:CastAbilityImmediately(ability, caster:GetPlayerOwnerID())
	end
end

-- Hide caster's model.
function HideCaster( event )
	event.caster:AddEffects(EF_NODRAW)
end

--Show caster's model.
function ShowCaster( event )
	event.caster:RemoveEffects(EF_NODRAW)
end

-- Stop a sound on the target unit.
function StopSound( event )
	StopSoundEvent( event.sound_name, event.target )
end

-- Make the visuals and initialize targets mana
function ManaFlareStart( event )
	local caster = event.caster
	local point = event.target_points[1]
    local ability = event.ability
    caster:StartGesture(ACT_DOTA_RUN)

    ability.flare = CreateUnitByName("dummy_unit_vulnerable", point, false, caster, caster, caster:GetTeam())
    ability:ApplyDataDrivenModifier(caster, ability.flare, "modifier_mana_flare", {})

    local particle = ParticleManager:CreateParticle("particles/econ/items/puck/puck_alliance_set/puck_dreamcoil_tether_aproset.vpcf", PATTACH_ABSORIGIN, ability.flare)
    ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

    -- Disable Phase Shift
    local phase_shift_ability = caster:FindAbilityByName("nightelf_phase_shift")
   	if phase_shift_ability:GetAutoCastState() == true then phase_shift_ability:ToggleAutoCast() end
    phase_shift_ability:SetLevel(0)
end

function ManaFlareEnd( event )
	local caster = event.caster
	local ability = event.ability

	ability.flare:RemoveSelf()
	caster:RemoveGesture(ACT_DOTA_RUN)

	 -- Reenable Phase Shift
    local phase_shift_ability = caster:FindAbilityByName("nightelf_phase_shift")
   	if phase_shift_ability:GetAutoCastState() == false then phase_shift_ability:ToggleAutoCast() end
    phase_shift_ability:SetLevel(1)
end

function ManaFlareDamage( event )
	local caster = event.caster
	local unit = event.unit
	local ability = event.ability
	local ability_cast = event.event_ability -- Awesome addition on Reborn
	local mana_cost = ability_cast:GetManaCost(ability_cast:GetLevel())
	local max_damage_unit = ability:GetSpecialValueFor("max_damage_unit")
	local max_damage_hero = ability:GetSpecialValueFor("max_damage_hero")
	local damager_per_mana_unit = ability:GetSpecialValueFor("damager_per_mana_unit")
	local damage_per_mana_hero = ability:GetSpecialValueFor("damage_per_mana_hero")
	local damage_type = ability:GetAbilityDamageType()
	local damage = 0

	if mana_cost == 0 then
		return
	end

	if unit:IsHero() or unit:IsConsideredHero() then
		if mana_cost * damage_per_mana_hero > max_damage_hero then
			damage = max_damage_hero
		else
			damage = mana_cost * damage_per_mana_hero
		end
	else
		if mana_cost * damager_per_mana_unit > max_damage_unit then
			damage = max_damage_unit
		else
			damage = mana_cost * damager_per_mana_unit
		end
	end 

	ApplyDamage({ victim = unit, attacker = caster, damage = damage, damage_type = damage_type, ability = ability}) 

	local attackName = "particles/units/heroes/hero_puck/puck_dreamcoil_start_d.vpcf"
    local attack = ParticleManager:CreateParticle(attackName, PATTACH_ABSORIGIN_FOLLOW, unit)

    unit:EmitSound("Hero_Puck.Dream_Coil_Snap")
end