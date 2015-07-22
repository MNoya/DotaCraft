local popup = {}
 
POPUP_SYMBOL_PRE_PLUS = 0
POPUP_SYMBOL_PRE_MINUS = 1
POPUP_SYMBOL_PRE_SADFACE = 2
POPUP_SYMBOL_PRE_BROKENARROW = 3
POPUP_SYMBOL_PRE_SHADES = 4
POPUP_SYMBOL_PRE_MISS = 5
POPUP_SYMBOL_PRE_EVADE = 6
POPUP_SYMBOL_PRE_DENY = 7
POPUP_SYMBOL_PRE_ARROW = 8

POPUP_SYMBOL_POST_EXCLAMATION = 0
POPUP_SYMBOL_POST_POINTZERO = 1
POPUP_SYMBOL_POST_MEDAL = 2
POPUP_SYMBOL_POST_DROP = 3
POPUP_SYMBOL_POST_LIGHTNING = 4
POPUP_SYMBOL_POST_SKULL = 5
POPUP_SYMBOL_POST_EYE = 6
POPUP_SYMBOL_POST_SHIELD = 7
POPUP_SYMBOL_POST_POINTFIVE = 8


-- e.g. when healed by an ability
function PopupHealing(target, amount)
    PopupNumbers(target, "heal", Vector(0, 255, 0), 1.0, amount, POPUP_SYMBOL_PRE_PLUS, nil)
end

-- e.g. the popup you get when you suddenly take a large portion of your health pool in damage at once
function PopupDamage(target, amount)
    PopupNumbers(target, "damage", Vector(255, 0, 0), 1.0, amount, nil, POPUP_SYMBOL_POST_DROP)
end

-- e.g. when dealing critical damage
function PopupCriticalDamage(target, amount)
    PopupNumbers(target, "crit", Vector(255, 0, 0), 1.0, amount, nil, POPUP_SYMBOL_POST_LIGHTNING)
end

-- e.g. when taking damage over time from a poison type spell
function PopupDamageOverTime(target, amount)
    PopupNumbers(target, "poison", Vector(215, 50, 248), 1.0, amount, nil, POPUP_SYMBOL_POST_EYE)
end

-- e.g. when blocking damage with a stout shield
function PopupDamageBlock(target, amount)
    PopupNumbers(target, "block", Vector(255, 255, 255), 1.0, amount, POPUP_SYMBOL_PRE_MINUS, nil)
end

-- e.g. when last-hitting a creep
function PopupGoldGain(target, amount)
    PopupNumbers(target, "gold", Vector(255, 200, 33), 2.0, amount, POPUP_SYMBOL_PRE_PLUS, nil)
end

-- e.g. when missing uphill
function PopupMiss(target)
    PopupNumbers(target, "miss", Vector(255, 0, 0), 1.0, nil, POPUP_SYMBOL_PRE_MISS, nil)
end

function PopupExperience(target, amount)
    PopupNumbers(target, "miss", Vector(154, 46, 254), 1.0, amount, POPUP_SYMBOL_PRE_PLUS, nil)
end

function PopupMana(target, amount)
    PopupNumbers(target, "heal", Vector(0, 176, 246), 1.0, amount, POPUP_SYMBOL_PRE_PLUS, nil)
end

function PopupHealthTome(target, amount)
    PopupNumbers(target, "miss", Vector(255, 255, 255), 1.0, amount, nil, POPUP_SYMBOL_POST_LIGHTNING)
end

function PopupStrTome(target, amount)
    PopupNumbers(target, "miss", Vector(255, 0, 0), 1.0, amount, nil, POPUP_SYMBOL_POST_LIGHTNING)
end

function PopupAgiTome(target, amount)
    PopupNumbers(target, "miss", Vector(0, 255, 0), 1.0, amount, nil, POPUP_SYMBOL_POST_LIGHTNING)
end

function PopupIntTome(target, amount)
    PopupNumbers(target, "miss", Vector(0, 176, 246), 1.0, amount, nil, POPUP_SYMBOL_POST_LIGHTNING)
end

function PopupHPRemovalDamage(target, amount)
    PopupNumbers(target, "crit", Vector(154, 46, 254), 3.0, amount, nil, POPUP_SYMBOL_POST_LIGHTNING)
end

function PopupLumber(target, amount)
    PopupNumbers(target, "damage", Vector(10, 200, 90), 3.0, amount, POPUP_SYMBOL_PRE_PLUS, nil)
end

-- Customizable version.
function PopupNumbers(target, pfx, color, lifetime, number, presymbol, postsymbol)
    local pfxPath = string.format("particles/msg_fx/msg_%s.vpcf", pfx)
    local pidx
    if pfx == "gold" or pfx == "luber" then
        pidx = ParticleManager:CreateParticleForTeam(pfxPath, PATTACH_ABSORIGIN_FOLLOW, target, target:GetTeamNumber())
    else
        pidx = ParticleManager:CreateParticle(pfxPath, PATTACH_ABSORIGIN_FOLLOW, target)
    end

    local digits = 0
    if number ~= nil then
        digits = #tostring(number)
    end
    if presymbol ~= nil then
        digits = digits + 1
    end
    if postsymbol ~= nil then
        digits = digits + 1
    end

    ParticleManager:SetParticleControl(pidx, 1, Vector(tonumber(presymbol), tonumber(number), tonumber(postsymbol)))
    ParticleManager:SetParticleControl(pidx, 2, Vector(lifetime, digits, 0))
    ParticleManager:SetParticleControl(pidx, 3, color)
end

function PopupMultiplier(target, number)
    local particleName = "particles/custom/alchemist_unstable_concoction_timer.vpcf"
    local preSymbol = 0 --none
    local postSymbol = 4 --crit
    local digits = string.len(number)+1
    local targetPos = target:GetAbsOrigin()

    local particle = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, target )
    ParticleManager:SetParticleControl(particle, 0, Vector(targetPos.x, targetPos.y, targetPos.z+322))
    ParticleManager:SetParticleControl( particle, 1, Vector( preSymbol, number, postSymbol) )
    ParticleManager:SetParticleControl( particle, 2, Vector( digits, 0, 0) )
end

function PopupLegion(target, number)
    local particleName = "particles/custom/legion_commander_duel_text.vpcf"

    local digits = string.len(number)
    local targetPos = target:GetAbsOrigin()
    local particle = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, target )
    ParticleManager:SetParticleControl( particle, 1, Vector( 10, number, 0) )
    ParticleManager:SetParticleControl( particle, 2, Vector( digits, 0, 0) )
    ParticleManager:SetParticleControl( particle, 3, Vector(targetPos.x, targetPos.y, targetPos.z+322) )
end

function PopupKillbanner(target, name)
    -- Possible names: firstblood, doublekill, triplekill, rampage, multikill_generic
    local particleName = "particles/econ/events/killbanners/screen_killbanner_compendium14_"..name..".vpcf"

    local particle = ParticleManager:CreateParticle( particleName, PATTACH_EYES_FOLLOW, target )
end

return popups