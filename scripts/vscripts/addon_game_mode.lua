
require('timers')
require('physics')
require('dotacraft')
require('popups')

-- BuildingHelper by Myll
require('buildinghelper')
require('FlashUtil')
require('abilities')

function Precache( context )
	--[[
		This function is used to precache resources/units/items/abilities that will be needed
		for sure in your game and that cannot or should not be precached asynchronously or 
		after the game loads.

		See dotacraft:PostLoadPrecache() in dotacraft.lua for more information
		]]

		print("[DOTACRAFT] Performing pre-load precache")

		-- Particles can be precached individually or by folder
		-- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
		PrecacheResource("particle", "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", context)
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

		-- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
		-- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
		PrecacheUnitByNameSync("npc_dota_hero_keeper_of_the_light", context)
		PrecacheUnitByNameSync("npc_dota_hero_zuus", context)
		PrecacheUnitByNameSync("npc_dota_hero_omniknight", context)
		PrecacheUnitByNameSync("npc_dota_hero_Invoker", context)

		-- Remove this later, it's just for testing
		PrecacheUnitByNameSync("human_barracks", context)
		PrecacheUnitByNameSync("human_arcane_sanctum", context)
		PrecacheUnitByNameSync("human_altar_of_kings", context)
		PrecacheUnitByNameSync("human_town_hall", context)
		PrecacheUnitByNameSync("human_peasant", context)
end

-- Create the game mode when we activate
function Activate()
	GameRules.dotacraft = dotacraft()
	GameRules.dotacraft:Initdotacraft()
end
