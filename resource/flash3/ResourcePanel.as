//=====================================================================================================
// ResourcePanel.as
//====================================================================================================
package  {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.*;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import flash.display.Sprite;
	
	//copied from VotingPanel.as source
	import flash.display.*;
    import flash.filters.*;
    import flash.text.*;
    import scaleform.clik.events.*;
    import vcomponents.*;

	
	
	public class ResourcePanel extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;
		
		//more shameless copy paste
		private var _btnYes:VButton;
        private var _btnNo:VButton;
		
		private var _loc_2:VComponent;
		
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
	}
	
}
