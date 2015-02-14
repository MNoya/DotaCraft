//=====================================================================================================
// ResourcePanel.as
//====================================================================================================
package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import scaleform.clik.events.*;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	
	
	public class ResourcePanel extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
		
	
		public function ResourcePanel() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			//this is our listener for the event, OnHeroLevelUp() is the handler
			this.gameAPI.SubscribeToGameEvent("cgm_player_lumber_changed", this.lumberEvent);
				
			trace("##Module Setup!");
		}
		
		public function setLumber(number): void {
			lumberCount.text = number;			
			trace("##ResourcePanel Set Lumber to "+lumberCount.text);
		}
		
		public function lumberEvent(args:Object) : void {
			trace("##Event Firing Detected")
			trace("##Data: "+args.player_ID+" - "+args.lumber);
			if (globals.Players.GetLocalPlayer() == args.player_ID)
			{
				this.setLumber(args.lumber);
			}
		}
				
		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean){
			
			trace("Stage Size: ",stageW,stageH,"Minus",stageW*0.4*yScale,stageH*0.352*yScale);
			
			this.x = stageW-stageW*0.407*yScale;
			this.y = stageH-stageH*0.352*yScale;
			
			this.width = this.width*yScale;
			this.height	 = this.height*yScale;
			
			trace("Result Resize: ",this.x,this.y,yScale);
					 
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
			
			trace("Custom UI ResourcePanel Resize");
		}
	}
	
}
