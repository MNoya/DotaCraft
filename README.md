## About the project

**Stage 1**: Recreate all Warcraft 3 Hero Abilities in Dota. 

This will serve as an extension to the [Dota Spell Library](https://github.com/Pizzalol/SpellLibrary)

Stage 2: Add every race-based unit and their abilities.

Stage 3: Port some RTS elements of the WC3 engine (like unit-creating buildings, tech upgrades, multi teams, etc) and ultimately develop a decent game mode out of this.

## Guidelines

- All abilities will be written using the datadriven system & lua scripts, no dota overrides allowed.

- Values and general description are taken from http://classic.battle.net/war3/

- Code each separate ability file inside scripts/npc/abilities then use executable.jar to merge the npc_abilities_custom.txt and test.

- Update progress in the [Warcraft 3 SpellLibrary Spreadsheet](https://docs.google.com/spreadsheets/d/1qwyG20YNi88G-SFYbaiyxi11Vtar8kjNXXJCMZyF7Y0)

- Check [Warchasers](https://github.com/MNoya/Warchasers/tree/master/scripts) & [SpellLibrary spreadsheet](https://docs.google.com/spreadsheets/d/1oNoqMW2_PZ57TEonAQgMF-9JlApbt3LPNFtx72RhS8Y)
to see if a similar spell was already made. Many spells overlap, so also make sure to reuse spells from both libraries and credit the authors.

- Try to use any existing dota particle similar to the original spell. [Use this guide for reference](http://moddota.com/forums/discussion/69/particle-attachment)

If custom particles are needed we can deal with that later.

- Follow this coding style:

For Datadriven KeyValues
~~~
"OnSpellStart"
{
    "RunScript"
    {
        "ScriptFile"    "heroes/hero_name/ability_name.lua"
        "Function"      "AbilityName"
    }
}
~~~

For Lua functions
~~~
--[[
    Author:
    Date: Day.Month.2015.
    (Description)
]]
function AbilityName( event )
    -- Variables
    local caster = event.caster
    local ability = event.ability
    local value = = ability:GetLevelSpecialValueFor( "value" , ability:GetLevel() - 1  )

    -- Try to comment each block of logical actions
    -- If the ability handle is not nil, print a message
    if ability then
        print("RunScript")
    end
end
~~~

- Modifier Name conventions (very important for automating tooltips later)

  - Start with "modifier_"
  - Then add the spell name (no hero name)
  - Add "_buff" "_debuff" "_stun" or anything when appropiate

- Use as many AbilitySpecials as possible, do not hardcode the lua file.

- Find a good ACT_DOTA_X and cast point for the abilities if possible.

- There are some mechanics that might not be worth porting, we have to discuss those later:

  - Undead damage
  - Disabling targeting units more than level 5
  - Air units
  - Others...
