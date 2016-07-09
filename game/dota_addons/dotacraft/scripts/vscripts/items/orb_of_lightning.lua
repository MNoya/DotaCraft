function Purge( event )
	local target = event.target
	
	-- Purge Enemy
	local RemovePositiveBuffs = true
	local RemoveDebuffs = false
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = false
	local RemoveExceptions = false
	target:Purge( RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
end

function SummonDamage( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local damage_to_summons = ability:GetLevelSpecialValueFor("damage_to_summons", (ability:GetLevel() - 1))

	if target:IsSummoned() then
		ApplyDamage({ victim = target, attacker = caster, damage = damage_to_summons, ability = ability, damage_type = DAMAGE_TYPE_MAGICAL })
	end
end