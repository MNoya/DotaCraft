function PulverizeStart(event)
    AddAnimationTranslate(event.caster, "enchant_totem")
end

function PulverizeEnd(event)
    RemoveAnimationTranslate(event.caster)
end