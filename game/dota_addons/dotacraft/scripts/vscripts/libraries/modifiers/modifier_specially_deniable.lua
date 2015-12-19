modifier_specially_deniable = class({})

function modifier_specially_deniable:CheckState() 
    return { [MODIFIER_STATE_SPECIALLY_DENIABLE] = true, }
end

function modifier_specially_deniable:IsHidden()
    return true
end
