function FlameStrikeAnimation(event)
	local caster = event.caster
	StartAnimation(caster, {duration=1, activity=ACT_DOTA_CAST_SUN_STRIKE, rate=1, translate="divine_sorrow_sunstrike"})
end

function FlameStrikeDamage(event)
	local ability = event.ability
	local caster = event.caster
	local targets = event.target_entities
	local damage = event.Damage
	local buildingReduction = ability:GetKeyValue("BuildingReduction")

	if targets then
		for k,target in pairs(targets) do
			local damageDone = damage
			if IsCustomBuilding(target) then
                damageDone = damageDone*buildingReduction
                local currentHP = target:GetHealth()
                local newHP = currentHP - damageDone

                if newHP <= 0 then
                    target:Kill(ability, caster)
                else
                    target:SetHealth(newHP)
                end
            else
                ApplyDamage({ victim = target, attacker = caster, damage = damageDone, ability = ability, damage_type = ability:GetAbilityDamageType() })
            end
		end
	elseif event.target then
		local target = event.target
		local damageDone = damage
		if IsCustomBuilding(target) then
            damageDone = damage*buildingReduction
            local currentHP = target:GetHealth()
            local newHP = currentHP - damageDone

            if newHP <= 0 then
                target:Kill(ability, caster)
            else
                target:SetHealth(newHP)
            end
        else
            ApplyDamage({ victim = target, attacker = caster, damage = damageDone, ability = ability, damage_type = ability:GetAbilityDamageType() })
        end
	end	
end