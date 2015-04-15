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
		
		public function SkillsOverlay() {
			// constructor code
		}
		
		public function setup(api:Object, globals:Object)
		{
			//set our needed variables
			this.gameAPI = api;
			this.globals = globals;
			
			var i:int = 0;
			for (i = 0; i<this.numChildren; i++)
			{
				var e:Object = this.getChildAt(i);
				switch(getQualifiedClassName(e)) {
					case "AbilityIcon":
						e.setup(this.gameAPI, this.globals);
					break;
				}
			}
			
			// Game Event Listening
			this.gameAPI.SubscribeToGameEvent("show_human_panel", this.showHumanOverview);
			this.gameAPI.SubscribeToGameEvent("hide_human_panel", this.hideHumanOverview);
			
			this.visible = false;
		}
		
		public function showHumanOverview(args:Object) : void {	
			// Show for this player
			var pID:int = globals.Players.GetLocalPlayer();
			if (args.player_ID == pID) {
				this.visible = true;
				trace("##Human overview Visible for "+args.player_ID);
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
	}
}

