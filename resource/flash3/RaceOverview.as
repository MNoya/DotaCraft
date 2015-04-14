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
	
	public class RaceOverview extends MovieClip {
		var gameAPI:Object;
		var globals:Object;
		
		public function RaceOverview() {
			// constructor code
		}
		
		public function setup(api:Object, globals:Object)
		{
			//set our needed variables
			this.gameAPI = api;
			this.globals = globals;
			
			//this should be an interation over all the childs
			this.human_train_peasant.setup(this.gameAPI, this.globals);
			this.human_train_archmage.setup(this.gameAPI, this.globals);
			this.human_train_paladin.setup(this.gameAPI, this.globals);
			this.human_train_mountain_king.setup(this.gameAPI, this.globals);
			this.human_train_blood_mage.setup(this.gameAPI, this.globals);
			this.human_train_footman.setup(this.gameAPI, this.globals);
			this.human_train_rifleman.setup(this.gameAPI, this.globals);
			this.human_train_knight.setup(this.gameAPI, this.globals);
			this.human_train_priest.setup(this.gameAPI, this.globals);
			this.human_train_sorceress.setup(this.gameAPI, this.globals);
			this.human_train_spell_breaker.setup(this.gameAPI, this.globals);
			this.human_train_flying_machine.setup(this.gameAPI, this.globals);
			this.human_train_mortar_team.setup(this.gameAPI, this.globals);
			this.human_train_siege_engine.setup(this.gameAPI, this.globals);
			this.human_train_gryphon_rider.setup(this.gameAPI, this.globals);
			this.human_train_dragonhawk_rider.setup(this.gameAPI, this.globals);
			
			
			var i:int = 0;
			for (i = 0; i<this.numChildren; i++)
			{
				var e:Object = this.getChildAt(i);
				trace(e.name, getQualifiedClassName(e));
				trace("-");
				switch(getQualifiedClassName(e)) {
					case "AbilityIcon":
						trace("AbilityIcon");
						//this.e.setup(this.gameAPI, this.globals);
					break;
				}
			}
		}
	}
	
}
