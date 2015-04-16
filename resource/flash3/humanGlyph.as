package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import flash.utils.Dictionary;
	import scaleform.clik.events.*;
	import scaleform.clik.events.ButtonEvent;
	import scaleform.clik.data.DataProvider;
	
	import ValveLib.*;
	import flash.text.TextFormat;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;		
	
	public class humanGlyph extends MovieClip {
		var gameAPI:Object;
		var globals:Object;
		var humanOverlay:Object;
		
		public function humanGlyph() {
			// constructor code
		}
		
		public function setup(api:Object, globals:Object, overlay:Object)
		{
			//set our needed variables
			this.gameAPI = api;
			this.globals = globals;
			this.humanOverlay = overlay;
												
			this.showOverlayBtn.addEventListener(MouseEvent.CLICK, onGlyphClick);
						
			trace("###Glyph Setup!");
		}
		
		// This has the issue of not updating everytime the UI should update...
		public function onGlyphClick(event:MouseEvent)
        {
			trace("glyph click!");
        	this.humanOverlay.visible = true;
			return;
        }// end function
		
		
	}
}
