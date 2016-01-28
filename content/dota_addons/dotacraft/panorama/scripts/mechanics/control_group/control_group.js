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
		GameUI.CustomUIConfig.SortByCustomIndex( $("#ControlGroups"), false );
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

function isControlDown(){
	return GameUI.IsControlDown();
};

(function () {
	// Create Control Group Key
	Game.AddCommand( "+SelectCreateControlGroup1", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup2", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup3", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup4", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup5", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup6", OnCreateControlGroupPressed, "", 0 );
	Game.AddCommand( "+SelectCreateControlGroup7", OnCreateControlGroupPressed, "", 0 );				
})();