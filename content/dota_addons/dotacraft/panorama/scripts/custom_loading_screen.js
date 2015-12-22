// choose random hint
function Choose_Hint(){
	var count =  Count_Localized_Strings()
	var random_number = Math.floor(Math.random() * count)
	
	// accepted random localized string
	var Localized_String = $.Localize("loading_screen_hint_"+random_number)
	
	var Hint_Text = Root.FindChildTraverse("HintPanel").FindChildTraverse("HintText")
	Hint_Text.text = "Hint: "+Localized_String
}

function Choose_Background() {
	var Map_Info = Game.GetMapInfo()
	var Map_Name = Map_Info.map_display_name.substring(2)
	if (Map_Name == "")
	{
		$.Schedule(0.1, Choose_Background)
		return
	}

	var path = "url('file://{images}/loading/"+Map_Name+".png');"
	$("#LoadingScreen").style["background-image"] = path
	$.Msg("Set Loading Screen Background ",path)
}

// an infinite loop that stops once an u nlocalised string is found
// function assume that atleast a hint index _0 EXIST
function Count_Localized_Strings(){
	if($.Localize("loading_screen_hint_0") == "loading_screen_hint_0"){
		$.Msg("[LOADING SCREEN] No localized string found, or incorrectly indexed(start at 0)")
		return
	}
	
	for(i=0; i == i; i++){	
		// store localized string based on i Index
		var Localized_String = $.Localize("loading_screen_hint_"+(i+1))
		
		// check if the localized string is identical to the localize value, if true that means there's no localisation for this, we assume at least.
		if(Localized_String == "loading_screen_hint_"+(i+1)){
			//$.Msg("BREAKING OUT OF COUNT, COUNT="+i)
			return i
			break;
		}
	}
}

function Check_Loading(){
	var GameState = Game.GetState()

	if(GameState == DOTA_GameState.DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP){
		var Load_Screen = Root.FindChildTraverse("LoadingScreen")
		Load_Screen.visible = false		
		Root.SetHasClass("Done_Loading", true)
	}	
	else{
		$.Schedule(0.1, Check_Loading)
	}
}
// root panel
var Root = $.GetContextPanel();

(function () {
	Choose_Hint();
	Choose_Background();
	Check_Loading();
})();
