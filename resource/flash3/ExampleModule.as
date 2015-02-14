//=====================================================================================================
// ExampleModule.as
//=====================================================================================================
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
	
	public class ExampleModule extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
          
		public var points:int;
		   
		public function ExampleModule() {
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			//this is our listener for the event, OnHeroLevelUp() is the handler
			this.gameAPI.SubscribeToGameEvent("cgm_player_stat_points_changed", this.OnStatPointsChanged);
	
			//we add a listener to this.button1 (I called my button 'button1')
			//this listener listens to the CLICK mouseEvent, and when it observes it, it cals onButtonClicked
			this.button1.addEventListener(MouseEvent.CLICK, onButton1Clicked);
			
			trace("##Module Setup!");
		}

		public function onButton1Clicked(event:MouseEvent) {
			this.button2.visible=true;
			this.button2.addEventListener(MouseEvent.CLICK, onButton2Clicked);
			this.button3.visible=true;
			this.button3.addEventListener(MouseEvent.CLICK, onButton3Clicked);
			//ToDo: check if its a Warrior class to show the int button
			this.button4.visible=true;
			this.button4.addEventListener(MouseEvent.CLICK, onButton4Clicked);
		}
		
		public function onButton2Clicked(event:MouseEvent) {
			this.gameAPI.SendServerCommand("AllocateStats str");
		}
		
		public function onButton3Clicked(event:MouseEvent) {
			this.gameAPI.SendServerCommand("AllocateStats agi");
		}
		
		public function onButton4Clicked(event:MouseEvent) {
			this.gameAPI.SendServerCommand("AllocateStats int");
		}
		
		public function OnStatPointsChanged(args:Object) : void {
			//get the ID of the player this UI belongs to, here we use a scaleform function from globals
			var pID:int = globals.Players.GetLocalPlayer();
			
			points = args.stat_points;
			var points_string:String = points.toString();
			trace("##You have "+points_string+" left");
			
			//check of the player in the event is the owner of this UI. Note that args are the parameters of the event
			if (args.player_ID == pID) {
				//if we can not afford another stats point, we will remove the button
				if (args.stat_points <= 0) {
					this.button1.visible=false;
					this.button2.visible=false;
					this.button3.visible=false;
					this.button4.visible=false;
				}
				else
				{
					//set visible
					trace("##Making Stats Allocation visible");
					this.button1.visible=true;
					this.button1.addEventListener(MouseEvent.CLICK, onButton1Clicked);
				}
				
			}
		}
    		
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean){
			this.x = stageW/2;
			this.y = stageH/2-100*yScale; //A bit on top of the middle to show the chat
					 
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
		}
	}	
}