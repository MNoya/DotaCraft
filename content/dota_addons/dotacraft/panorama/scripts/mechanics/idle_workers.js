"use strict";

var builderList;
var idleCount = 0;
var currentBuilder = 0;

function OnIdleButtonPressed( data ) {
	var iPlayerID = Players.GetLocalPlayer();
	$.Msg("Player "+iPlayerID+" pressed iddle button, with "+idleCount+" idle builders");

	if (currentBuilder == idleCount){
		currentBuilder = 0;
	};
	currentBuilder++;

	var nextBuilder = builderList[String(currentBuilder)];
	if (nextBuilder === undefined)
		currentBuilder = 1;

	nextBuilder = builderList[String(currentBuilder)];
	GameUI.SelectUnit(nextBuilder, false);
	GameEvents.SendCustomGameEventToServer( "reposition_player_camera", { entIndex: nextBuilder });
}

function OnPlayerUpdateIdleBuilders( args ) {
	var iPlayerID = Players.GetLocalPlayer();
	//$.Msg("OnPlayerUpdateIdleBuilders")

	builderList = args.idle_builder_entities;
	idleCount = 0;

	for (var key in builderList) {
		var idleBuilderIndex = builderList[key];
		//$.Msg("Idle Builder "+idleBuilderIndex)
		idleCount++;
	};

	if (idleCount > 0){
		$('#IdleNumber').text = idleCount;
		$('#IdleButton').visible = true;
	}
	else
	{
		$('#IdleNumber').text = "";
		$('#IdleButton').visible = false;
	};
};

function OnPlayerStart( args ) {
	var race = args.race;
	idleCount = args.initial_builders;
	$('#IdleNumber').text = idleCount;
	$('#IdleButtonImage').SetImage( "s2r://panorama/images/custom_game/"+race+"/"+race+"_builder.png" );
};

var angle = 0;
function RotateCamera() {
	angle+= 180;
	GameUI.SetCameraYaw( angle );
};
 
(function () {
	GameEvents.Subscribe( "player_show_ui", OnPlayerStart );
	GameEvents.Subscribe( "rotate_camera", RotateCamera );
	GameEvents.Subscribe( "player_update_idle_builders", OnPlayerUpdateIdleBuilders );
	
	// Idle Builders Key
	GameUI.Keybinds.IdleBuilderSwap = function() { OnIdleButtonPressed() }
})();