---------------------------------------------------------------------------
if dotacraft == nil then
    _G.dotacraft = class({})
end
---------------------------------------------------------------------------

require('libraries/adv_log')
require('libraries/timers')
require('libraries/physics')
require('libraries/animations')
require('libraries/popups')
require('libraries/attributes')
require('libraries/notifications')
require('libraries/attachments')
require('libraries/containers')
require('libraries/selection')
require('libraries/keyvalues')
require('libraries/buildinghelper')
require('libraries/gatherer')
--[[
require('statcollection/init')
--]]

require('dotacraft')
require('utilities')
require('mechanics/require')
require('orders')
require('damage')
require('developer')
require('units/neutral_ai')
require('units/aggro_filter')
require('buildings/altar')
require('buildings/research')
require('buildings/upgrades')
require('buildings/queue')
require('buildings/rally_point')

---------------------------------------------------------------------------

function Precache( context )
    print("[DOTACRAFT] Performing Pre-Load precache")

    _G.PRECACHE_TABLE = LoadKeyValues("scripts/kv/precache.kv")

    for k,_ in pairs(PRECACHE_TABLE.UnitSync) do
        PrecacheUnitByNameSync(k, context)
    end

    for k,_ in pairs(PRECACHE_TABLE.ItemSync) do
        PrecacheItemByNameSync(k, context)
    end

    for resource_type,v in pairs(PRECACHE_TABLE.Resource) do
        for k,_ in pairs(v) do
            PrecacheResource(resource_type, k, context)
        end
    end

    PrecacheWearables( context )
    
    print("[DOTACRAFT] Pre-Load precache done!")
end

-- Create our game mode and initialize it
function Activate()
    print ( '[DOTACRAFT] creating dotacraft game mode' )
    dotacraft:InitGameMode()
    dotacraft.Initialized = true
end

if dotacraft.Initialized then
    dotacraft:OnScriptReload()
end

---------------------------------------------------------------------------