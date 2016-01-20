"use strict";

var LOW_UPKEEP = 50
var HIGH_UPKEEP = 80
var currentUpkeep = 0 //1 for No, 2 for Low, 3 for High

GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD , false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_MENU_BUTTONS , false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false );


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
		$('#UpkeepTextAnnounce').text = $.Localize( "#high_upkeep" );
		$('#UpkeepTextAnnounce').RemoveClass('Hidden');

		$('#FoodText').AddClass('Red');
		$('#FoodText').RemoveClass('Yellow');
		$('#FoodText').RemoveClass('Green');	

		$('#UpkeepText').AddClass('Red');
		$('#UpkeepText').RemoveClass('Yellow');
		$('#UpkeepText').RemoveClass('Green');
		$('#UpkeepText').text = "High Upkeep";
		
		$('#UpkeepTextAnnounce').AddClass('Red');
		$('#UpkeepTextAnnounce').RemoveClass('Yellow');
		$('#UpkeepTextAnnounce').RemoveClass('Green');
		$.Schedule(3, function(){ $('#UpkeepTextAnnounce').AddClass('Hidden') })
	}
	else if (food_used > LOW_UPKEEP && food_used <= HIGH_UPKEEP && currentUpkeep !=2) {
		currentUpkeep = 2
		$.Msg(" LOW UPKEEP")
		$('#UpkeepTextAnnounce').text = $.Localize( "#low_upkeep" );
		$('#UpkeepTextAnnounce').RemoveClass('Hidden');

		$('#FoodText').AddClass('Yellow');	
		$('#FoodText').RemoveClass('Red');
		$('#FoodText').RemoveClass('Green');
			
		$('#UpkeepText').AddClass('Yellow');	
		$('#UpkeepText').RemoveClass('Red');
		$('#UpkeepText').RemoveClass('Green');
		$('#UpkeepText').text = "Low Upkeep";
		
		$('#UpkeepTextAnnounce').AddClass('Yellow');
		$('#UpkeepTextAnnounce').RemoveClass('Red');
		$('#UpkeepTextAnnounce').RemoveClass('Green');
		$.Schedule(3, function(){ $('#UpkeepTextAnnounce').AddClass('Hidden') })
	}
	else if (food_used < LOW_UPKEEP && currentUpkeep !=1){
		currentUpkeep = 1
		$.Msg(" NO UPKEEP")
		$('#UpkeepTextAnnounce').text = $.Localize( "#no_upkeep" );
		$('#UpkeepTextAnnounce').RemoveClass('Hidden');

		$('#FoodText').AddClass('Green');
		$('#FoodText').RemoveClass('Yellow');
		$('#FoodText').RemoveClass('Red');

		$('#UpkeepText').AddClass('Green');
		$('#UpkeepText').RemoveClass('Yellow');
		$('#UpkeepText').RemoveClass('Red');
		$('#UpkeepText').text = "No Upkeep";
		
		$('#UpkeepTextAnnounce').AddClass('Green');
		$('#UpkeepTextAnnounce').RemoveClass('Yellow');
		$('#UpkeepTextAnnounce').RemoveClass('Red');
		$.Schedule(3, function(){ $('#UpkeepTextAnnounce').AddClass('Hidden') })
	}
}

(function () {
	GameEvents.Subscribe( "player_lumber_changed", OnPlayerLumberChanged );
	GameEvents.Subscribe( "player_food_changed", OnPlayerFoodChanged );
	
	UpdateGold();
})();

function UpdateGold(){
	var CurrentGold = Players.GetGold( Game.GetLocalPlayerID() );
	
	$("#GoldText").text = CurrentGold;
	$.Schedule(0.1, UpdateGold);
};