//=====================================================================================================
// ResourcePanel.as
//====================================================================================================
package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import scaleform.clik.events.*;
	import flash.text.TextField;
    import flash.text.TextFormat;
	
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
			this.gameAPI.SubscribeToGameEvent("cgm_player_food_limit_changed", this.foodLimitEvent);
			this.gameAPI.SubscribeToGameEvent("cgm_player_food_used_changed", this.foodUsedEvent);										  
											  
				
			trace("##Module Setup!");
		}
		
		public function setLumber(number): void {
			lumberCount.text = number;
			
			var txFormat:TextFormat = new TextFormat;
	
			//font
			txFormat.font = "$TextFontBold";					
			
			lumberCount.setTextFormat(txFormat);
			
			trace("##ResourcePanel Set Lumber to "+lumberCount.text);
		}
		
		public function setFood(used, limit): void {
			foodCount.text = used + " / " + limit;
			
			var txFormat:TextFormat = new TextFormat;
	
			//font
			txFormat.font = "$TextFontBold";					
			
			//color. 0-50 green, 51-80 yellow, 81-100 red
			var greenColor:Number = 0x00FF00;
			var yellowColor:Number = 0xFFFF00;
			var redColor:Number = 0xFF0000;
			
			if (used > 80)
				txFormat.color = redColor;
			else if (used > 50)
				txFormat.color = yellowColor;
			else
				txFormat.color = greenColor;
			
			foodCount.setTextFormat(txFormat);
			
			trace("##ResourcePanel Set Food to "+foodCount.text);
		}
		
		public function lumberEvent(args:Object) : void {
			trace("##Event Firing Detected")
			trace("##Data: "+args.player_ID+" - "+args.lumber);
			if (globals.Players.GetLocalPlayer() == args.player_ID)
			{
				this.setLumber(args.lumber);
			}
		}
		
		public function foodUsedEvent(args:Object) : void {
			trace("##Event Firing Detected")
			trace("##Data: "+args.player_ID+" - "+args.food_used+" - "+args.food_limit);
			if (globals.Players.GetLocalPlayer() == args.player_ID)
			{
				this.setFood(args.food_used, args.food_limit);
			}
		}
		
		public function foodLimitEvent(args:Object) : void {
			trace("##Event Firing Detected")
			trace("##Data: "+args.player_ID+" - "+args.food_used+" - "+args.food_limit);
			if (globals.Players.GetLocalPlayer() == args.player_ID)
			{
				this.setFood(args.food_used, args.food_limit);
			}
		}
				
		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean){
			
			trace("Stage Size: ",stageW,stageH);
			
			//this.x = stageW-stageW*0.407*yScale;
			//this.y = stageH-stageH*0.352*yScale;
			
			this.x = stageW * 0.7265625
			this.y = stageH * 0.7648148			
			
			this.width = this.width*yScale;
			this.height	 = this.height*yScale;
			
			trace("#Result Resize: ",this.x,this.y,yScale);
					 
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
			
			trace("#LumberOverlay ResourcePanel Resize");
		}
	}
	
}
