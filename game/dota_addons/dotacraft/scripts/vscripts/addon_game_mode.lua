---------------------------------------------------------------------------
if dotacraft == nil then
	_G.dotacraft = class({})
end
---------------------------------------------------------------------------

require('libraries/timers')
require('libraries/physics')
require('libraries/animations')
require('libraries/popups')
require('libraries/notifications')
require('dotacraft')
require('utilities')
require('upgrades')
require('mechanics')
require('orders')
require('damage')
require('stats')
require('developer')
require('units/neutral_ai')
require('units/builder')
require('libraries/buildinghelper')

---------------------------------------------------------------------------

function Precache( context )
	print("[DOTACRAFT] Performing pre-load precache")

	-- Particles can be precached individually or by folder
	-- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
	PrecacheResource("particle_folder", "particles/custom", context)
	PrecacheResource("particle_folder", "particles/buildinghelper", context)

	-- Models can also be precached by folder or individually
	-- PrecacheModel should generally used over PrecacheResource for individual models
	PrecacheResource("model_folder", "models/heroes/tiny_04/", context)
	PrecacheModel("models/creeps/neutral_creeps/n_creep_troll_skeleton/n_creep_troll_skeleton_fx.vmdl", context)

	-- Sounds can precached here like anything else
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)

	-- Entire items can be precached by name
	-- Abilities can also be precached in this way despite the name
	PrecacheItemByNameSync("example_ability", context)
	PrecacheItemByNameSync("item_rally", context)
	PrecacheItemByNameSync("item_apply_modifiers", context)

	-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
	-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way

	-- This units are created as soon as the player gets into the game		
	PrecacheUnitByNameSync("human_town_hall", context)
	PrecacheUnitByNameSync("nightelf_tree_of_life", context)
	PrecacheUnitByNameSync("undead_necropolis", context)
	PrecacheUnitByNameSync("orc_great_hall", context)

	PrecacheUnitByNameSync("human_peasant", context)
	PrecacheUnitByNameSync("human_militia", context)	
	PrecacheUnitByNameSync("nightelf_wisp", context)
	PrecacheUnitByNameSync("undead_acolyte", context)
	PrecacheUnitByNameSync("orc_peon", context)

	-- These are available on the builder units from the start
	PrecacheUnitByNameSync("human_barracks", context)
	PrecacheUnitByNameSync("human_altar_of_kings", context)
	PrecacheUnitByNameSync("human_keep", context)
	PrecacheUnitByNameSync("human_lumber_mill", context)
	PrecacheUnitByNameSync("human_scout_tower", context)
	PrecacheUnitByNameSync("human_blacksmith", context)
	PrecacheUnitByNameSync("human_arcane_vault", context)
	PrecacheUnitByNameSync("human_castle", context)
	PrecacheUnitByNameSync("human_farm", context)

	PrecacheUnitByNameSync("nightelf_ancient_of_war", context)
	PrecacheUnitByNameSync("nightelf_ancient_of_wonders", context)
	PrecacheUnitByNameSync("nightelf_altar_of_elders", context)
	PrecacheUnitByNameSync("nightelf_hunters_hall", context)
	PrecacheUnitByNameSync("nightelf_entangled_gold_mine", context)
	PrecacheUnitByNameSync("nightelf_moon_well", context)

	PrecacheUnitByNameSync("undead_altar_of_darkness", context)
	PrecacheUnitByNameSync("undead_crypt", context)
	PrecacheUnitByNameSync("undead_graveyard", context)
	PrecacheUnitByNameSync("undead_haunted_gold_mine", context)
	PrecacheUnitByNameSync("undead_tomb_of_relics", context)
	PrecacheUnitByNameSync("undead_ziggurat", context)

	PrecacheUnitByNameSync("orc_altar_of_storms", context)
	PrecacheUnitByNameSync("orc_barracks", context)
	PrecacheUnitByNameSync("orc_burrow", context)
	PrecacheUnitByNameSync("orc_voodoo_lounge", context)
	PrecacheUnitByNameSync("orc_war_mill", context)	
end

-- Create our game mode and initialize it
function Activate()
	print ( '[DOTACRAFT] creating dotacraft game mode' )
	dotacraft:InitGameMode()
end

---------------------------------------------------------------------------