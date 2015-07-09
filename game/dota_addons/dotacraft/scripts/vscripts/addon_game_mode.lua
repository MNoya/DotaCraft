---------------------------------------------------------------------------
if dotacraft == nil then
	_G.dotacraft = class({})
end
---------------------------------------------------------------------------

require('timers')
require('physics')
require('dotacraft')
require('popups')
require('utilities')
require('upgrades')
require('mechanics')
require('orders')
require('buildinghelper')

---------------------------------------------------------------------------

function Precache( context )
		print("[DOTACRAFT] Performing pre-load precache")

		-- Particles can be precached individually or by folder
		-- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
		PrecacheResource("particle", "particles/custom/rally_flag.vpcf", context)
		PrecacheResource("particle_folder", "particles/test_particle", context)
		PrecacheResource("particle_folder", "particles/buildinghelper", context)

		-- Models can also be precached by folder or individually
		-- PrecacheModel should generally used over PrecacheResource for individual models
		PrecacheResource("model_folder", "particles/heroes/antimage", context)
		PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
		PrecacheModel("models/creeps/neutral_creeps/n_creep_troll_skeleton/n_creep_troll_skeleton_fx.vmdl", context)

		-- Sounds can precached here like anything else
		PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)

		-- Entire items can be precached by name
		-- Abilities can also be precached in this way despite the name
		PrecacheItemByNameSync("example_ability", context)
		PrecacheItemByNameSync("item_rally", context)
		PrecacheItemByNameSync("item_apply_modifiers", context)
		PrecacheItemByNameSync("item_orb_of_frost", context)
		PrecacheItemByNameSync("item_orb_of_fire", context)
		PrecacheItemByNameSync("item_orb_of_venom_wc3", context)
		PrecacheItemByNameSync("item_orb_of_corruption", context)
		PrecacheItemByNameSync("item_orb_of_darkness", context)
		PrecacheItemByNameSync("item_orb_of_lightning", context)

		-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
		-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
		PrecacheUnitByNameSync("npc_dota_hero_keeper_of_the_light", context)
		PrecacheUnitByNameSync("npc_dota_hero_zuus", context)
		PrecacheUnitByNameSync("npc_dota_hero_omniknight", context)
		PrecacheUnitByNameSync("npc_dota_hero_Invoker", context)

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

		-- These should be on PostLoadPrecache, but it's not working inside tools. Just temporary.
		PrecacheUnitByNameSync("human_barracks", context)
		PrecacheUnitByNameSync("human_arcane_sanctum", context)
		PrecacheUnitByNameSync("human_altar_of_kings", context)
		PrecacheUnitByNameSync("human_keep", context)
		PrecacheUnitByNameSync("human_castle", context)
		PrecacheUnitByNameSync("human_farm", context)
		PrecacheUnitByNameSync("human_lumber_mill", context)
		PrecacheUnitByNameSync("human_scout_tower", context)
		PrecacheUnitByNameSync("human_guard_tower", context)
		PrecacheUnitByNameSync("human_cannon_tower", context)
		PrecacheUnitByNameSync("human_arcane_tower", context)
		PrecacheUnitByNameSync("human_blacksmith", context)
		PrecacheUnitByNameSync("human_workshop", context)
		PrecacheUnitByNameSync("human_arcane_sanctum", context)
		PrecacheUnitByNameSync("human_gryphon_aviary", context)
		PrecacheUnitByNameSync("human_arcane_vault", context)

		PrecacheUnitByNameSync("nightelf_ancient_of_lore", context)
		PrecacheUnitByNameSync("nightelf_ancient_of_war", context)
		PrecacheUnitByNameSync("nightelf_ancient_of_wind", context)
		PrecacheUnitByNameSync("nightelf_ancient_protector", context)
		PrecacheUnitByNameSync("nightelf_ancient_of_wonders", context)
		PrecacheUnitByNameSync("nightelf_tree_of_life", context)
		PrecacheUnitByNameSync("nightelf_altar_of_elders", context)
		PrecacheUnitByNameSync("nightelf_chimaera_roost", context)

		-- HATS
		PrecacheResource("model_folder", "models/heroes/dragon_knight", context)
		PrecacheResource("model_folder", "models/items/dragon_knight", context)
		PrecacheResource("model_folder", "models/heroes/sniper", context)
		PrecacheResource("model_folder", "models/items/sniper", context)
		PrecacheResource("model_folder", "models/heroes/chaos_knight", context)
		PrecacheResource("model_folder", "models/items/chaos_knight", context)
		PrecacheResource("model_folder", "models/heroes/silencer", context)
		PrecacheResource("model_folder", "models/items/silencer", context)
		PrecacheResource("model_folder", "models/heroes/gyrocopter", context)
		PrecacheResource("model_folder", "models/items/gyrocopter", context)
		PrecacheResource("model_folder", "models/heroes/skywrath_mage", context)
		PrecacheResource("model_folder", "models/items/skywrath_mage", context)
end

-- Create our game mode and initialize it
function Activate()
	print ( '[DOTACRAFT] creating dotacraft game mode' )
	dotacraft:InitGameMode()
end

---------------------------------------------------------------------------