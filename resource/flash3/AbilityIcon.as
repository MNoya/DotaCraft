package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import flash.utils.Dictionary;
	import scaleform.clik.events.*;
	import flash.geom.Point;
	
	import ValveLib.*;
	import flash.text.TextFormat;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;	
	
	public class AbilityIcon extends MovieClip {
		var gameAPI:Object;
		var globals:Object;
		public var ability_name:String;
		private var disabledOverlay:MovieClip;
		
		public function AbilityIcon() {
			// constructor code
		}
		
		public function setup(api:Object, globals:Object, ability_name:String, ability_state:Number)
		{
			//set our needed variables
			this.gameAPI = api;
			this.globals = globals;
						
			//Image
			var spellIcon:MovieClip = new MovieClip;
			this.globals.LoadImage("images/spellicons/" + ability_name + ".png", spellIcon, false);
			
			// Handle _disable ability
			if (ability_state == 0)
				ability_name = ability_name+"_disabled";
			
			this.ability_name = ability_name;
			spellIcon.scaleY = 0.5; //64px
			spellIcon.scaleX = 0.5; //64px
			this.addChild(spellIcon);
			
			// Draw a black square on top if the ability is disabled
			if (ability_state == 0)
				drawTheOverlay();
			
			// Listeners
			this.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
			this.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
			
		}
		
		public function onMouseRollOver(keys:MouseEvent){
       		
       		var s:Object = keys.target;
       		trace("roll over! " + s.ability_name);

			// Workout where to put it
            var lp:Point = s.localToGlobal(new Point(0, 0));	
			
			//if(lp.x < Globals.instance.CustomUI.movieClip.width/2)
			if(lp.x < 1920/2) { //make it accept other resolutions
                // Workout how much to move it
                var offset:Number = 64;

                // Face to the right
                globals.Loader_rad_mode_panel.gameAPI.OnShowAbilityTooltip(lp.x+offset, lp.y, s.ability_name);
            } else {
                // Face to the left
                globals.Loader_heroselection.gameAPI.OnSkillRollOver(lp.x, lp.y, s.ability_name);
            }
       	}
		
		public function onMouseRollOut(keys:MouseEvent){
			
			globals.Loader_heroselection.gameAPI.OnSkillRollOut();
		}
		
		private function drawTheOverlay() {
			this.disabledOverlay = new MovieClip;
		
			this.disabledOverlay.graphics.lineStyle();
			this.disabledOverlay.graphics.beginFill(0x000000, 0.7); //0.5 refers to alpha
			this.disabledOverlay.graphics.drawRect(0, 0, 64, 64);
			this.disabledOverlay.graphics.endFill();
		
			this.addChild(this.disabledOverlay);
		}
	}
}
