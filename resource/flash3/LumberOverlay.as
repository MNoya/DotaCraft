//=====================================================================================================
// LumberOverlay.as
//=====================================================================================================
package {
	import flash.display.MovieClip;
	import flash.text.*;

	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class LumberOverlay extends MovieClip{
		
		//these three variables are required by the engine
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		public var screenWidth:int;
		
		//constructor, you usually will use onLoaded() instead
		public function LumberOverlay() : void {

		}
			
		//this function is called when the UI is loaded
		public function onLoaded() : void {			
			//make this UI visible
			visible = true;
			
			//let the client rescale the UI
			Globals.instance.resizeManager.AddListener(this);
			
			//pass the gameAPI on to the modules
			this.myResource.setup(this.gameAPI, this.globals);
						
			//this is not needed, but it shows you your UI has loaded (needs 'scaleform_spew 1' in console)
			trace("#Lumber Overlay loaded!");
		}
		
		//this handles the resizes - credits to Nullscope & Perry
		public function onResize(re:ResizeManager) : * {
			
			// calculate by what ratio the stage is scaling
			var scaleRatioY:Number = re.ScreenHeight/1080;
			
			trace("#Lumber Overlay Resize");
			trace("##########################");
					
			screenWidth = re.ScreenWidth;
					
			//pass the resize event to our module, we pass the width and height of the screen, as well as the INVERSE of the stage scaling ratios.
			this.myResource.screenResize(re.ScreenWidth, re.ScreenHeight, scaleRatioY, scaleRatioY, re.IsWidescreen());
		}
	}
}