"use strict";

var LOW_UPKEEP = 50
var HIGH_UPKEEP = 80
var currentUpkeep = 1 //1 for No, 2 for Low, 3 for High

function OnPlayerLumberChanged ( args ) {
	var iPlayerID = Players.GetLocalPlayer()
	var lumber = args.lumber
	$.Msg("Player "+iPlayerID+" Lumber: "+lumber)
	$('#LumberText').text = lumber
}

function OnPlayerFoodChanged ( args ) {
	var iPlayerID = Players.GetLocalPlayer()
	var food_used = args.food_used
	var food_limit = args.food_limit
	$.Msg("Player "+iPlayerID+" Food: "+food_used+"/"+food_limit)
	$('#FoodText').text = food_used+"/"+food_limit

	//decide to show No/Low/High Upkeep message
	if (food_used > HIGH_UPKEEP && currentUpkeep != 3){
		currentUpkeep = 3
		$.Msg(" HIGH_UPKEEP")
		$('#UpkeepText').text = $.Localize( "#high_upkeep" );
		$('#UpkeepText').RemoveClass('Hidden');

		$('#FoodText').AddClass('Red');
		$('#FoodText').RemoveClass('Yellow');
		$('#FoodText').RemoveClass('Green');	

		$('#UpkeepText').AddClass('Red');
		$('#UpkeepText').RemoveClass('Yellow');
		$('#UpkeepText').RemoveClass('Green');
		$.Schedule(3, function(){ $('#UpkeepText').AddClass('Hidden') })
	}
	else if (food_used > LOW_UPKEEP && food_used <= HIGH_UPKEEP && currentUpkeep !=2) {
		currentUpkeep = 2
		$.Msg(" LOW UPKEEP")
		$('#UpkeepText').text = $.Localize( "#low_upkeep" );
		$('#UpkeepText').RemoveClass('Hidden');

		$('#FoodText').AddClass('Yellow');	
		$('#FoodText').RemoveClass('Red');
		$('#FoodText').RemoveClass('Green');

		$('#UpkeepText').AddClass('Yellow');
		$('#UpkeepText').RemoveClass('Red');
		$('#UpkeepText').RemoveClass('Green');
		$.Schedule(3, function(){ $('#UpkeepText').AddClass('Hidden') })
	}
	else if (food_used < LOW_UPKEEP && currentUpkeep !=1){
		currentUpkeep = 1
		$.Msg(" NO UPKEEP")
		$('#UpkeepText').text = $.Localize( "#no_upkeep" );
		$('#UpkeepText').RemoveClass('Hidden');

		$('#FoodText').AddClass('Green');
		$('#FoodText').RemoveClass('Yellow');
		$('#FoodText').RemoveClass('Red');
		
		$('#UpkeepText').AddClass('Green');
		$('#UpkeepText').RemoveClass('Yellow');
		$('#UpkeepText').RemoveClass('Red');
		$.Schedule(3, function(){ $('#UpkeepText').AddClass('Hidden') })
	}
}

(function () {
	GameEvents.Subscribe( "player_lumber_changed", OnPlayerLumberChanged );
	GameEvents.Subscribe( "player_food_changed", OnPlayerFoodChanged );
})();