-- Auxiliar table function
function tableContains(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return true
        end
    end
    return false
end

function getIndex(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return i
        end
    end
    return -1
end

function getUnitIndex(list, unitName)
    --print("Given Table")
    --DeepPrintTable(list)
    if list == nil then return false end
    for k,v in pairs(list) do
        for key,value in pairs(list[k]) do
            print(key,value)
            if value == unitName then 
                return key
            end
        end        
    end
    return -1
end


-- goes through a unit's abilities and sets the abil's level to 1,
-- spending an ability point if possible.
function InitAbilities( hero )
    for i=0, hero:GetAbilityCount()-1 do
        local abil = hero:GetAbilityByIndex(i)
        if abil ~= nil then
            if hero:IsHero() and hero:GetAbilityPoints() > 0 then
                hero:UpgradeAbility(abil)
            else
                abil:SetLevel(1)
            end
        end
    end
end