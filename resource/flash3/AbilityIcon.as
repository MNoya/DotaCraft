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
		public var iconName:String;
		
		public function AbilityIcon() {
			// constructor code
		}
		
		public function setup(api:Object, globals:Object)
		{
			//set our needed variables
			this.gameAPI = api;
			this.globals = globals;
						
			//Image
			var spellIcon:MovieClip = new MovieClip;
			this.globals.LoadImage("images/spellicons/" + this.name + ".png", spellIcon, false);
			spellIcon.scaleY = 0.5; //64px
			spellIcon.scaleX = 0.5; //64px
			this.addChild(spellIcon);
			
			// Listeners
			this.addEventListener(MouseEvent.ROLL_OVER, onMouseRollOver);
			this.addEventListener(MouseEvent.ROLL_OUT, onMouseRollOut);
			
		}
		
		public function onMouseRollOver(keys:MouseEvent){
       		
       		var s:Object = keys.target;
       		trace("roll over! " + s.name);

			// Workout where to put it
            var lp:Point = s.localToGlobal(new Point(0, 0));	
			
			//if(lp.x < Globals.instance.CustomUI.movieClip.width/2)
			if(lp.x < 1920/2) { //make it accept other resolutions
                // Workout how much to move it
                var offset:Number = 64;

                // Face to the right
                globals.Loader_rad_mode_panel.gameAPI.OnShowAbilityTooltip(lp.x+offset, lp.y, s.name);
            } else {
                // Face to the left
                globals.Loader_heroselection.gameAPI.OnSkillRollOver(lp.x, lp.y, s.name);
            }
       	}
		
		public function onMouseRollOut(keys:MouseEvent){
			
			globals.Loader_heroselection.gameAPI.OnSkillRollOut();
		}
	}
}
