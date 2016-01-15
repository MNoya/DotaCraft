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
		$('#IdleButton').RemoveClass('Hidden');
	}
	else
	{
		$('#IdleNumber').text = "";
		$('#IdleButton').AddClass('Hidden');
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
 
function CreateControlGroup( index ){
	var iPlayerID = Players.GetLocalPlayer();
    var selectedEntities = Players.GetSelectedEntities(iPlayerID);
	
	CreateControlGroupButton(index, selectedEntities);
};

function CreateControlGroupButton( index, entities){
	if($("#ControlGroup"+index) == null){ // create panel if it doesn't exist
		var ControlGroupButton = $.CreatePanel("Panel", $("#ControlGroups"), "ControlGroup"+index);
		ControlGroupButton.index = index;
		ControlGroupButton.currentSelection = entities;
		ControlGroupButton.BLoadLayout("file://{resources}/layout/custom_game/control_group_button.xml", false, false);
	}else{ // if panel still exist, overwrite current saved selection
		$("#ControlGroup"+index).currentSelection = entities;
	};
	
	if( $("#ControlGroups").GetChildCount() >= 2 )
		SortChildren( $("#ControlGroups") );
};

function IdentifyKey( keystring ){
	return parseInt( keystring.substring(keystring.length-1), 10 );
};

function OnCreateControlGroupPressed( args ){
	var Index = IdentifyKey(args);
	if( isControlDown() )
		CreateControlGroup(Index);
	else
		if( $("#ControlGroups").GetChild(Index-1) != null )
			$("#ControlGroups").GetChild(Index-1).OnControlGroupButtonPressed();
};

function SortChildren( Container ){
	$.Msg("Sorting child of panel: "+Container.id);
	for(var i =0; i < Container.GetChildCount(); i++){
		for(var j=0; j < Container.GetChildCount() - 1; j++){
			var child = Container.GetChild(i);
			var child2 = Container.GetChild(i+1);
			
			if( child2 != null ){
				if( child.index > child2.index ){
					Container.MoveChildAfter(child, child2);
				};
			};
		};
	};
};

function isControlDown(){
	return GameUI.IsControlDown();
};
(function () {
	GameEvents.Subscribe( "player_show_ui", OnPlayerStart );
	GameEvents.Subscribe( "rotate_camera", RotateCamera );
	GameEvents.Subscribe( "player_update_idle_builders", OnPlayerUpdateIdleBuilders );
	
	// Idle Builders Key
	Game.AddCommand( "+IdleBuilderSwap", OnIdleButtonPressed, "", 0 );

	// Create Control Group Key
	Game.AddCommand( "+SelectCreateControlGroup1", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup2", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup3", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup4", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup5", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup6", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup7", OnCreateControlGroupPressed, "", 0 );				
})();