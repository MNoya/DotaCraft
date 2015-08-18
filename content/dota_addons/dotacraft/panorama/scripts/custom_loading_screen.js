// choose random hint
function Choose_Hint(){
	var count = Count_Localized_Strings()
	var random_number = Math.round(count)
	
	// accepted random localized string
	var Localized_String = $.Localize("loading_screen_hint_"+random_number)
	
	var Hint_Text = Root.FindChildTraverse("HintPanel").FindChildTraverse("HintText")
	Hint_Text.text = "Hint: "+Localized_String
}

// an infinite loop that stops once an unlocalised string is found
function Count_Localized_Strings(){
	for(i=0; i == i; i++){	
		// store localized string based on i Index
		var Localized_String = $.Localize("loading_screen_hint_"+i)
		
		// check if the localized string is identical to the localize value, if true that means there's no localisation for this, we assume at least.
		if(Localized_String == "loading_screen_hint_"+i){
			$.Msg("BREAKING OUT OF COUNT, COUNT="+i)
			return y = i -1
			break;
		}
	}
}

// root panel
var Root = $.GetContextPanel();

(function () {
	Choose_Hint()
})();
