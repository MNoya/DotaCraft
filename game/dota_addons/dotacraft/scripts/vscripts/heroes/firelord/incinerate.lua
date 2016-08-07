function OrbCheck(event)
    local target = event.target
    local caster = event.caster

    if target:IsMechanical() or IsCustomBuilding(target) or target:IsWard() then
        caster:RemoveModifierByName("modifier_incinerate_orb")
    else
        if not caster:HasModifier("modifier_incinerate_orb") then
            local ability = event.ability
            ability:ApplyDataDrivenModifier(caster,caster,"modifier_incinerate_orb",{})
        end
    end
end

--[[
	Author: Noya, adapted from SpellLibrary ursa_fury_swipes
	Increase stack after each hit
]]
function IncinerateAttack( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local modifierName = "modifier_incinerate_stack"
	local damageType = ability:GetAbilityDamageType()

	local duration = ability:GetLevelSpecialValueFor( "bonus_reset_time", ability:GetLevel() - 1 )
	local damage_per_stack = ability:GetLevelSpecialValueFor( "damage_per_stack", ability:GetLevel() - 1 )
	
	-- If the unit has the stack, initialize it, else just increase
	if target:HasModifier( modifierName ) then
		local current_stack = target:GetModifierStackCount( modifierName, ability )
		
		ApplyDamage({victim = target, attacker = caster, damage = damage_per_stack * current_stack, damage_type = damageType, ability = ability})
		
		ability:ApplyDataDrivenModifier( caster, target, modifierName, { duration = duration } )
		target:SetModifierStackCount( modifierName, ability, current_stack + 1 )
	else
		ability:ApplyDataDrivenModifier( caster, target, modifierName, { duration = duration } )
		target:SetModifierStackCount( modifierName, ability, 1 )
	end
end

function IncinerateDeath(event)
	local caster = event.caster
	local target = event.unit
	local ability = event.ability
	local radius = ability:GetLevelSpecialValueFor("incineration_radius",ability:GetLevel()-1)
	local damage = ability:GetLevelSpecialValueFor("incineration_damage",ability:GetLevel()-1)
	
	local particle = ParticleManager:CreateParticle("particles/custom/ogre_magi_fireblast.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, FIND_ANY_ORDER, false)
	for _,v in pairs(enemies) do
		ApplyDamage({victim = v, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL, ability = ability})
	end
end