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
		}
		
		public function onCloseButtonClicked(event:MouseEvent)
        {
            trace("Close Overview Panel");
            this.visible = false;
            return;
        }
	}
}

