package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import scaleform.clik.events.*;
	import scaleform.clik.data.DataProvider;
	
	import ValveLib.*;
	import flash.text.TextFormat;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;	
	
	
	public class SkillsOverlay extends MovieClip {
		var gameAPI:Object;
		var globals:Object;
		var abilities:Object;
		
		public function SkillsOverlay() {
			// constructor code
		}
		
		public function setup(api:Object, globals:Object)
		{
			//set our needed variables
			this.gameAPI = api;
			this.globals = globals;
			
			// load values from KV
			loadKV();
						
			// Game Event Listening
			this.gameAPI.SubscribeToGameEvent("show_overview_panel", this.showHumanOverview);
			this.gameAPI.SubscribeToGameEvent("hide_overview_panel", this.hideHumanOverview);
			
			this.visible = false;
		}
		
		public function showHumanOverview(args:Object) : void {	
			// Show for this player
			var pID:int = globals.Players.GetLocalPlayer();
			if (args.player_ID == pID) {
				this.visible = true;
				var race:String = args.race;
				trace("##"+race+" overview Visible for "+args.player_ID);
				trace(args.abilities);
				var ability_array:Array = args.abilities.split(",");
								
				for (var i = 0; i<this.numChildren; i++)
				{
					var e:Object = this.getChildAt(i);
					switch(getQualifiedClassName(e)) {
						case "AbilityIcon":
							var splitName:Array = e.name.split("ability");
							//trace(e.name,abilities["human_race"][splitName[1]]);
														
							var index = Number(splitName[1])-1; //One less because the 0,0,0,1 string
							trace("Checking index "+index+" of abilities, value: ", ability_array[ index ]);
							var ability_name = abilities[race][splitName[1]]; //This gets changed internally with _disabled
							e.setup(this.gameAPI, this.globals, ability_name, Number( ability_array[ index ] ));
							trace(ability_name)							
								
						break;
					}
				}
			}
		}
		
		public function hideHumanOverview(args:Object) : void {	
			// Show for this player
			var pID:int = globals.Players.GetLocalPlayer();
			if (args.player_ID == pID) {
				this.visible = false;
				trace("##Human overview Hidden for "+args.player_ID);
			}
		}
		
		// load the abilities
		private function loadKV() {
			abilities = Globals.instance.GameInterface.LoadKVFile('scripts/kv/abilities.kv');
			trace("[SkillsOverlay] KV Loaded");
		}
	}
}

