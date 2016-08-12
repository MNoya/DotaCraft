function Banish(event)
    local target = event.target
    local taunt = target:FindAbilityByName("nightelf_taunt")
    if taunt then taunt:SetActivated(false) end
end

function BanishEnd(event)
    local target = event.target
    local taunt = target:FindAbilityByName("nightelf_taunt")
    if taunt then taunt:SetActivated(true) end
end