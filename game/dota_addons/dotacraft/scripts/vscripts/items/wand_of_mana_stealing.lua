item_wand_of_mana_stealing = class({})

function item_wand_of_mana_stealing:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()        
    local mana_stolen = self:GetSpecialValueFor("mana_stolen")
    mana_stolen = math.min(mana_stolen, target:GetMana()-mana_stolen)
    target:SetMana(target:GetMana()-mana_stolen)
    caster:SetMana(caster:GetMana()+mana_stolen)

    target:EmitSound("Hero_Bane.BrainSap.Target")

    local particle = ParticleManager:CreateParticle("particles/custom/items/wands/mana_steal.vpcf",PATTACH_ABSORIGIN_FOLLOW,caster)
    ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

    if mana_stolen > 0 then
        PopupMana(caster, mana_stolen)
    end

    local charges = caster:GetCurrentCharges()
    if charges > 1 then
        self:SetCurrentCharges(charges-1)
    else
        self:RemoveSelf()
    end
end

--------------------------------------------------------------------------------
 
function item_wand_of_mana_stealing:CastFilterResultTarget( target )
    local caster = self:GetCaster()
    if caster:GetMana() == caster:GetMaxMana() then
        return UF_FAIL_CUSTOM
    end

    local targetMana = target:GetMana()
    if not targetMana or targetMana < 1 then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end
  
function item_wand_of_mana_stealing:GetCustomCastErrorTarget( target )
    local caster = self:GetCaster()
    if caster:GetMana() == caster:GetMaxMana() then
        return "#error_full_mana"
    end

    local targetMana = target:GetMana()
    if not targetMana or targetMana < 1 then
        return "#error_need_target_with_mana"
    end
 
    return ""
end