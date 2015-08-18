// choose random hint
function Choose_Hint(){
	var count =  Count_Localized_Strings()
	var random_number = Math.floor(Math.random() * count)
	
	// accepted random localized string
	var Localized_String = $.Localize("loading_screen_hint_"+random_number)
	
	var Hint_Text = Root.FindChildTraverse("HintPanel").FindChildTraverse("HintText")
	Hint_Text.text = "Hint: "+Localized_String
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

// root panel
var Root = $.GetContextPanel();

(function () {
	Choose_Hint()
})();
